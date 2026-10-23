import 'dart:async';

import 'package:bosstro/src/rust/api/chat.dart' as chat_api;
import 'package:bosstro/src/rust/api/chat.dart'
    show ChatMessageView, ChatParty, ChatThread, ChatUpdate;

export 'package:bosstro/src/rust/api/chat.dart'
    show
        ChatChannelState,
        ChatDelivery,
        ChatError,
        ChatMessageView,
        ChatParty,
        ChatSender,
        ChatThread,
        ChatUpdate;

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
}
