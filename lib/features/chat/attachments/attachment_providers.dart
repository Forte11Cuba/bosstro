import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/chat/providers/chat_providers.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';

/// One attachment: its message in one conversation.
typedef AttachmentRef = ({String disputeId, ChatParty party, String messageId});

/// How many decrypted bytes stay in memory across bubbles, as ../app. Past
/// it the oldest go, and are decrypted again from the encrypted cache when
/// scrolled back to.
const int kDecryptedCacheBytes = 64 * 1024 * 1024;

/// Decrypted attachments, in memory only, least recently used first out.
///
/// The disk holds the encrypted blob (Rust's attachment cache); this keeps a
/// bubble scrolled off and back from decrypting it again.
class DecryptedAttachmentCache {
  DecryptedAttachmentCache({this.maxBytes = kDecryptedCacheBytes});

  final int maxBytes;

  // Insertion order is recency: a hit is removed and added back at the end.
  final LinkedHashMap<AttachmentRef, OpenedAttachment> _entries =
      LinkedHashMap();
  int _bytes = 0;

  int get sizeInBytes => _bytes;

  OpenedAttachment? get(AttachmentRef ref) {
    final hit = _entries.remove(ref);
    if (hit != null) _entries[ref] = hit;
    return hit;
  }

  void put(AttachmentRef ref, OpenedAttachment data) {
    final previous = _entries.remove(ref);
    if (previous != null) _bytes -= previous.bytes.length;
    // One file larger than the whole budget is served, never kept.
    if (data.bytes.length > maxBytes) return;
    _entries[ref] = data;
    _bytes += data.bytes.length;
    while (_bytes > maxBytes) {
      final oldest = _entries.keys.first;
      _bytes -= _entries.remove(oldest)!.bytes.length;
    }
  }

  void clear() {
    _entries.clear();
    _bytes = 0;
  }
}

/// The decrypted files of the active node and key: dropped when either
/// changes (another key must not see this one's files).
final decryptedAttachmentCacheProvider = Provider<DecryptedAttachmentCache>((
  ref,
) {
  ref.watch(activeNodeProvider);
  ref.watch(solverKeyProvider);
  final cache = DecryptedAttachmentCache();
  ref.onDispose(cache.clear);
  return cache;
});

/// The attachment of [ref], from the memory cache or opened by the core. A
/// failure (a [ChatError]) is not cached: `ref.invalidate` is the retry.
final openedAttachmentProvider = FutureProvider.autoDispose
    .family<OpenedAttachment, AttachmentRef>((ref, arg) async {
      final cache = ref.watch(decryptedAttachmentCacheProvider);
      final hit = cache.get(arg);
      if (hit != null) return hit;
      final opened = await ref
          .read(chatCoreProvider)
          .openAttachment(arg.disputeId, arg.party, arg.messageId);
      cache.put(arg, opened);
      return opened;
    });

/// Whether opening again can give another answer: a network or relay
/// failure may pass, a file that failed its checks fails the same way.
bool isRetryableOpenError(Object error) => switch (error) {
  ChatError.notVerified ||
  ChatError.unsupportedFile ||
  ChatError.invalidImage ||
  ChatError.fileTooLarge ||
  ChatError.unknownMessage => false,
  _ => true,
};
