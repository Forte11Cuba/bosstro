import 'dart:async';

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
}) => ChatMessageView(
  id: id,
  sender: sender,
  content: content,
  createdAt: createdAt,
  delivery: delivery,
);
