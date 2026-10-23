import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/observer/services/observer_core.dart';

/// The observed chat in Dart: what the test stores per dispute, what a read
/// and a paste answer, and every key pasted (as text: the test checks the
/// bytes it got before the caller wiped them).
class FakeObserverCore implements ObserverCore {
  FakeObserverCore({this.node = mostroNodePubkey});

  String? node;

  /// The stored observed chats, by dispute id (absent: not this key's).
  final Map<String, ObservedChat> chats = {};

  /// What `read` answers: an [ObservedChat] or an [ObserverError] to throw.
  /// Null: the stored chat. A [Completer] holds it until the test answers.
  Object? readAnswer;
  Completer<void>? holdReads;

  /// What `paste` answers, as `read`.
  Object? pasteAnswer;

  final List<String> reads = [];
  final List<String> pasted = [];

  /// The pasted byte buffers, to check they were wiped after the call.
  final List<Uint8List> pastedBuffers = [];

  @override
  Future<ObservedChat?> stored(String disputeId) async =>
      node == null ? null : chats[disputeId];

  @override
  Future<ObservedChat> read(String disputeId) async {
    reads.add(disputeId);
    if (holdReads case final hold?) await hold.future;
    return _answer(disputeId, readAnswer);
  }

  @override
  Future<ObservedChat> paste(String disputeId, Uint8List key) async {
    pasted.add(utf8.decode(key));
    pastedBuffers.add(key);
    return _answer(disputeId, pasteAnswer);
  }

  ObservedChat _answer(String disputeId, Object? answer) {
    switch (answer) {
      case final ObserverError e:
        throw e;
      case final ObservedChat chat:
        chats[disputeId] = chat;
        return chat;
      default:
        return chats[disputeId]!;
    }
  }
}

/// An observed chat as the core returns it.
ObservedChat sampleObserved({
  String disputeId = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c',
  List<KeyDisclosure> disclosures = const [],
  bool hasPastedKey = false,
  int since = 1699395200,
  List<ObservedMessage> messages = const [],
}) => ObservedChat(
  mostroPubkey: mostroNodePubkey,
  disputeId: disputeId,
  disclosures: disclosures,
  hasPastedKey: hasPastedKey,
  since: since,
  messages: messages,
);

/// A message of the chat between the parties.
ObservedMessage observedMessage({
  required String id,
  ChatParty sender = ChatParty.buyer,
  String content = 'Ya te hice la transferencia.',
  int createdAt = 1699999000,
  ChatAttachment? attachment,
}) => ObservedMessage(
  id: id,
  sender: sender,
  content: content,
  createdAt: createdAt,
  attachment: attachment,
);
