import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/chat/providers/chat_providers.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';

enum UploadStatus { uploading, failed }

/// A file on its way out, shown as the solver's own bubble until the core
/// returns the message it sent, from MostroP2P/app's `PendingUpload`.
@immutable
class PendingUpload {
  const PendingUpload({
    required this.id,
    required this.fileName,
    required this.bytes,
    this.progress = 0,
    this.status = UploadStatus.uploading,
    this.error,
  });

  /// Also the id the core reports its progress under.
  final String id;
  final String fileName;

  /// Kept, in memory, for a retry.
  final Uint8List bytes;

  /// 0 to 1: prepared, encrypted, uploaded, sent.
  final double progress;
  final UploadStatus status;

  /// Why it failed.
  final ChatError? error;

  PendingUpload copyWith({
    double? progress,
    UploadStatus? status,
    ChatError? error,
  }) => PendingUpload(
    id: id,
    fileName: fileName,
    bytes: bytes,
    progress: progress ?? this.progress,
    status: status ?? this.status,
    error: error,
  );
}

/// Every transfer's progress, one core stream for the process: a pending
/// `next()` cannot be cancelled from Dart, so one receiver per upload would
/// leak. Kept subscribed once listened to.
final attachmentProgressProvider = Provider<Stream<AttachmentProgress>>(
  (ref) => ref.watch(chatCoreProvider).attachmentProgress().asBroadcastStream(),
);

/// Whether sending [error] again can succeed: a file of the wrong type or
/// size fails the same way every time; an upload or a relay may not.
bool isRetryableUploadError(ChatError? error) => switch (error) {
  ChatError.fileTooLarge ||
  ChatError.unsupportedFile ||
  ChatError.invalidImage ||
  ChatError.closed ||
  ChatError.unknownDispute ||
  ChatError.noPartyKey => false,
  _ => true,
};

/// The uploads in flight in one conversation. Scoped to it: leaving the
/// dispute drops the failed ones, whose bytes were only ever in memory; one
/// still uploading finishes in the core and shows up in the conversation.
final chatUploadsProvider = NotifierProvider.autoDispose
    .family<ChatUploadsNotifier, List<PendingUpload>, ChatKey>(
      ChatUploadsNotifier.new,
    );

class ChatUploadsNotifier
    extends AutoDisposeFamilyNotifier<List<PendingUpload>, ChatKey> {
  static int _counter = 0;
  bool _disposed = false;

  @override
  List<PendingUpload> build(ChatKey arg) {
    ref.onDispose(() => _disposed = true);
    return const [];
  }

  /// Starts sending [bytes]. Resolves to whether it was sent; a failed one
  /// stays, with a retry.
  Future<bool> send(String fileName, Uint8List bytes) {
    final upload = PendingUpload(
      id: 'upload-${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
      fileName: fileName,
      bytes: bytes,
    );
    state = [...state, upload];
    return _run(upload);
  }

  Future<bool> retry(String id) {
    final upload = _find(id);
    if (upload == null || upload.status != UploadStatus.failed) {
      return Future.value(false);
    }
    final restarted = upload.copyWith(
      progress: 0,
      status: UploadStatus.uploading,
    );
    _replace(restarted);
    return _run(restarted);
  }

  void discard(String id) {
    if (_disposed) return;
    state = [
      for (final u in state)
        if (u.id != id) u,
    ];
  }

  Future<bool> _run(PendingUpload upload) async {
    final core = ref.read(chatCoreProvider);
    final progress = ref
        .read(attachmentProgressProvider)
        .where((p) => p.id == upload.id)
        .listen(
          (p) {
            final current = _find(upload.id);
            if (current != null && p.fraction > current.progress) {
              _replace(current.copyWith(progress: p.fraction));
            }
          },
          // A progress stream that fails leaves the bar where it was; the
          // send itself decides the outcome.
          onError: (Object e) => debugPrint('[chat] upload progress: $e'),
        );
    try {
      await core.sendAttachment(
        arg.disputeId,
        arg.party,
        upload.bytes,
        upload.fileName,
        upload.id,
      );
      if (!_disposed) {
        await ref.read(chatThreadProvider(arg).notifier).refresh();
      }
      discard(upload.id);
      return true;
    } on ChatError catch (e) {
      final current = _find(upload.id);
      if (current != null) {
        _replace(current.copyWith(status: UploadStatus.failed, error: e));
      }
      return false;
    } finally {
      unawaited(progress.cancel());
    }
  }

  PendingUpload? _find(String id) {
    if (_disposed) return null;
    for (final u in state) {
      if (u.id == id) return u;
    }
    return null;
  }

  void _replace(PendingUpload upload) {
    if (_disposed) return;
    state = [for (final u in state) u.id == upload.id ? upload : u];
  }
}
