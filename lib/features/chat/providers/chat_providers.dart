import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';

/// The core behind the chat providers. Tests override it with a fake.
final chatCoreProvider = Provider<ChatCore>((ref) => const RustChatCore());

/// The core's conversation changes. Not auto-disposed: a pending `next()`
/// cannot be cancelled from Dart, so one subscription serves the process
/// (as `disputeUpdatesProvider`).
final chatUpdatesProvider = StreamProvider<ChatUpdate>(
  (ref) => ref.watch(chatCoreProvider).updates(),
);

/// One conversation: a dispute and a party.
typedef ChatKey = ({String disputeId, ChatParty party});

/// One conversation of a dispute, oldest message first, live; null when the
/// dispute is not this key's on the active node.
final chatThreadProvider = AsyncNotifierProvider.autoDispose
    .family<ChatThreadNotifier, ChatThread?, ChatKey>(ChatThreadNotifier.new);

class ChatThreadNotifier
    extends AutoDisposeFamilyAsyncNotifier<ChatThread?, ChatKey> {
  /// How long updates are gathered before the core is read again.
  static const coalesce = Duration(milliseconds: 100);

  Timer? _pending;

  ChatCore get _core => ref.read(chatCoreProvider);

  @override
  Future<ChatThread?> build(ChatKey arg) async {
    ref.watch(activeNodeProvider);
    ref.watch(solverKeyProvider);
    ref.listen(chatUpdatesProvider, (_, next) {
      final update = next.valueOrNull;
      if (update == null ||
          update.mostroPubkey != ref.read(activeNodeProvider)) {
        return;
      }
      final mine =
          update.disputeId == null ||
          (update.disputeId == arg.disputeId &&
              (update.party == null || update.party == arg.party));
      if (mine) _schedule();
    });
    // A close or a reopen changes whether the conversation can be written.
    ref.listen(disputeUpdatesProvider, (_, next) {
      final update = next.valueOrNull;
      if (update == null) return;
      final dispute = update.dispute;
      if (dispute == null || dispute.disputeId == arg.disputeId) _schedule();
    });
    ref.onDispose(() => _pending?.cancel());
    return _core.thread(arg.disputeId, arg.party);
  }

  /// Read again now.
  Future<void> refresh() => _reload();

  void _schedule() {
    if (_pending?.isActive ?? false) return;
    _pending = Timer(coalesce, () => unawaited(_reload()));
  }

  Future<void> _reload() async {
    try {
      state = AsyncData(await _core.thread(arg.disputeId, arg.party));
    } catch (e) {
      // What is on screen stays; the next update tries again.
      debugPrint('[chat] not read: $e');
    }
  }
}
