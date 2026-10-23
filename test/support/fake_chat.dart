import 'dart:async';
import 'dart:typed_data';

import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';

/// The dispute chat in Dart: conversations the test sets, read the way the
/// core answers, sends recorded, and a stream of updates the test pushes.
class FakeChatCore implements ChatCore {
  FakeChatCore({this.node = mostroNodePubkey});

  String? node;

  /// The conversations, by dispute id and party (absent: not this key's).
  final Map<(String, ChatParty), ChatThread> threads = {};

  /// What `send` and `retry` throw, when set.
  ChatError? error;

  /// The texts sent and the ids retried, in order.
  final List<String> sent = [];
  final List<String> retried = [];

  /// The files sent, by name, in order.
  final List<String> filesSent = [];

  /// What `sendAttachment` throws, when set; when null and [holdUploads]
  /// is set, the upload waits until the test completes it.
  ChatError? uploadError;
  Completer<void>? holdUploads;

  /// What `openAttachment` answers, by message id: an [OpenedAttachment],
  /// or a [ChatError] to throw. Absent: it never answers (still loading).
  final Map<String, Object> opened = {};

  /// The message ids opened, in order.
  final List<String> openedIds = [];

  final StreamController<AttachmentProgress> progress =
      StreamController.broadcast();

  final StreamController<ChatUpdate> changes = StreamController.broadcast();

  int _next = 0;

  /// Set the conversation with [party] of [disputeId].
  void set(
    String disputeId,
    ChatParty party, {
    ChatChannelState state = ChatChannelState.open,
    List<ChatMessageView> messages = const [],
  }) {
    threads[(disputeId, party)] = ChatThread(
      mostroPubkey: node ?? '',
      disputeId: disputeId,
      party: party,
      state: state,
      messages: List.of(messages),
    );
  }

  @override
  Future<ChatThread?> thread(String disputeId, ChatParty party) async =>
      node == null ? null : threads[(disputeId, party)];

  @override
  Future<ChatMessageView> send(
    String disputeId,
    ChatParty party,
    String text,
  ) async {
    if (error case final e?) throw e;
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ChatError.empty;
    sent.add(trimmed);
    final message = ChatMessageView(
      id: 'sent-${_next++}',
      sender: ChatSender.you,
      content: trimmed,
      createdAt: 1700007200 + _next,
      delivery: ChatDelivery.sending,
    );
    _append(disputeId, party, message);
    return message;
  }

  @override
  Future<ChatMessageView> retry(
    String disputeId,
    ChatParty party,
    String messageId,
  ) async {
    if (error case final e?) throw e;
    retried.add(messageId);
    final current = threads[(disputeId, party)]!;
    final old = current.messages.firstWhere((m) => m.id == messageId);
    final again = ChatMessageView(
      id: 'retry-${_next++}',
      sender: ChatSender.you,
      content: old.content,
      createdAt: old.createdAt,
      delivery: ChatDelivery.sending,
    );
    threads[(disputeId, party)] = ChatThread(
      mostroPubkey: current.mostroPubkey,
      disputeId: disputeId,
      party: party,
      state: current.state,
      messages: [
        for (final m in current.messages)
          if (m.id != messageId) m,
        again,
      ],
    );
    return again;
  }

  void _append(String disputeId, ChatParty party, ChatMessageView message) {
    final current = threads[(disputeId, party)]!;
    threads[(disputeId, party)] = ChatThread(
      mostroPubkey: current.mostroPubkey,
      disputeId: disputeId,
      party: party,
      state: current.state,
      messages: [...current.messages, message],
    );
  }

  @override
  Stream<ChatUpdate> updates() => changes.stream;

  @override
  Future<ChatMessageView> sendAttachment(
    String disputeId,
    ChatParty party,
    Uint8List bytes,
    String fileName,
    String uploadId,
  ) async {
    progress.add(AttachmentProgress(id: uploadId, fraction: 0.3));
    if (holdUploads case final hold?) await hold.future;
    if (uploadError case final e?) throw e;
    filesSent.add(fileName);
    final message = sampleMessage(
      id: 'file-${_next++}',
      sender: ChatSender.you,
      content: '{}',
      delivery: ChatDelivery.sending,
      attachment: ChatAttachment(
        kind: ChatAttachmentKind.file,
        fileName: fileName,
        mimeType: 'application/pdf',
        size: bytes.length,
      ),
    );
    _append(disputeId, party, message);
    return message;
  }

  @override
  Future<OpenedAttachment> openAttachment(
    String disputeId,
    ChatParty party,
    String messageId,
  ) {
    openedIds.add(messageId);
    return switch (opened[messageId]) {
      final OpenedAttachment file => Future.value(file),
      final ChatError e => Future.error(e),
      _ => Completer<OpenedAttachment>().future,
    };
  }

  @override
  Stream<AttachmentProgress> attachmentProgress() => progress.stream;

  /// Announce a change of one conversation, as the router does.
  void push(String disputeId, ChatParty party) => changes.add(
    ChatUpdate(mostroPubkey: node ?? '', disputeId: disputeId, party: party),
  );
}

/// A message as the core shows it.
ChatMessageView sampleMessage({
  required String id,
  ChatSender sender = ChatSender.buyer,
  String content = 'Hola',
  int createdAt = 1700005000,
  ChatDelivery delivery = ChatDelivery.sent,
  ChatAttachment? attachment,
}) => ChatMessageView(
  id: id,
  sender: sender,
  content: content,
  createdAt: createdAt,
  delivery: delivery,
  attachment: attachment,
);

/// An image attachment as a message declares it.
ChatAttachment sampleImage({
  String name = 'recibo.jpg',
  int? w = 1200,
  int? h = 900,
}) => ChatAttachment(
  kind: ChatAttachmentKind.image,
  fileName: name,
  mimeType: 'image/jpeg',
  size: 245760,
  width: w,
  height: h,
);

/// A PDF attachment as a message declares it.
ChatAttachment samplePdf({String name = 'extracto-bancario.pdf'}) =>
    ChatAttachment(
      kind: ChatAttachmentKind.file,
      fileName: name,
      mimeType: 'application/pdf',
      size: 1468006,
    );
