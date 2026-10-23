import 'dart:async';
import 'dart:typed_data';

import 'package:bosstro/src/rust/api/chat.dart' as chat_api;
import 'package:bosstro/src/rust/api/chat.dart'
    show
        AttachmentProgress,
        ChatMessageView,
        ChatParty,
        ChatThread,
        ChatUpdate,
        OpenedAttachment;

export 'package:bosstro/src/rust/api/chat.dart'
    show
        AttachmentProgress,
        ChatAttachment,
        ChatAttachmentKind,
        ChatChannelState,
        ChatDelivery,
        ChatError,
        ChatMessageView,
        ChatParty,
        ChatSender,
        ChatThread,
        ChatUpdate,
        OpenedAttachment;

/// The Rust core's dispute chat (`rust/src/api/chat.rs`). An interface so
/// widget tests, which run without the native library, drive a fake.
abstract interface class ChatCore {
  /// The conversation with [party] of [disputeId], oldest message first, or
  /// null when the dispute is not this key's on the active node.
  Future<ChatThread?> thread(String disputeId, ChatParty party);

  /// Send [text] to [party]. Returns it as stored, sending; throws a
  /// [ChatError] when it was refused before anything left.
  Future<ChatMessageView> send(String disputeId, ChatParty party, String text);

  /// Send again a message of this key that was not sent. Throws a
  /// [ChatError] when it cannot be.
  Future<ChatMessageView> retry(
    String disputeId,
    ChatParty party,
    String messageId,
  );

  /// Every conversation change, for whichever node is active.
  Stream<ChatUpdate> updates();

  /// Check, clean, encrypt, upload and send the file [bytes] to [party]
  /// (`send_chat_attachment`). Returns the message as stored, sending; throws
  /// a [ChatError] when nothing was sent ([uploadId] names the upload on
  /// [attachmentProgress]).
  Future<ChatMessageView> sendAttachment(
    String disputeId,
    ChatParty party,
    Uint8List bytes,
    String fileName,
    String uploadId,
  );

  /// The attachment of [messageId], downloaded if needed, verified and
  /// decrypted in memory (`open_chat_attachment`). Throws a [ChatError].
  Future<OpenedAttachment> openAttachment(
    String disputeId,
    ChatParty party,
    String messageId,
  );

  /// Every transfer's progress, uploads and downloads.
  Stream<AttachmentProgress> attachmentProgress();
}

class RustChatCore implements ChatCore {
  const RustChatCore();

  @override
  Future<ChatThread?> thread(String disputeId, ChatParty party) =>
      chat_api.chatThread(disputeId: disputeId, party: party);

  @override
  Future<ChatMessageView> send(
    String disputeId,
    ChatParty party,
    String text,
  ) => chat_api.sendChatMessage(disputeId: disputeId, party: party, text: text);

  @override
  Future<ChatMessageView> retry(
    String disputeId,
    ChatParty party,
    String messageId,
  ) => chat_api.retryChatMessage(
    disputeId: disputeId,
    party: party,
    messageId: messageId,
  );

  @override
  Stream<ChatUpdate> updates() async* {
    final stream = await chat_api.onChatUpdates();
    while (true) {
      final next = await stream.next();
      if (next == null) return;
      yield next;
    }
  }

  @override
  Future<ChatMessageView> sendAttachment(
    String disputeId,
    ChatParty party,
    Uint8List bytes,
    String fileName,
    String uploadId,
  ) => chat_api.sendChatAttachment(
    disputeId: disputeId,
    party: party,
    bytes: bytes,
    fileName: fileName,
    uploadId: uploadId,
  );

  @override
  Future<OpenedAttachment> openAttachment(
    String disputeId,
    ChatParty party,
    String messageId,
  ) => chat_api.openChatAttachment(
    disputeId: disputeId,
    party: party,
    messageId: messageId,
  );

  @override
  Stream<AttachmentProgress> attachmentProgress() async* {
    final stream = await chat_api.onAttachmentProgress();
    while (true) {
      final next = await stream.next();
      if (next == null) return;
      yield next;
    }
  }
}
