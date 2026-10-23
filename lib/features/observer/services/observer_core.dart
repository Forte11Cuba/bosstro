import 'dart:typed_data';

import 'package:bosstro/src/rust/api/observer.dart' as observer_api;
import 'package:bosstro/src/rust/api/observer.dart' show ObservedChat;

export 'package:bosstro/src/rust/api/observer.dart'
    show KeyDisclosure, ObservedChat, ObservedMessage, ObserverError;

/// The Rust core's observed chat (`rust/src/api/observer.rs`): what the
/// buyer and the seller of a dispute wrote to each other, read with the key
/// of their chat. Read only: nothing here can write to that conversation.
/// An interface so widget tests, which run without the native library,
/// drive a fake.
abstract interface class ObserverCore {
  /// The observed chat of [disputeId] as stored, without asking the relays;
  /// null when the dispute is not this key's on the active node.
  Future<ObservedChat?> stored(String disputeId);

  /// Ask the relays with every key known for [disputeId]. Throws an
  /// [ObserverError].
  Future<ObservedChat> read(String disputeId);

  /// Check a pasted chat key against the relays, and hold it when it opens
  /// a message of this dispute. [key] is the text's UTF-8 bytes; the caller
  /// wipes them after the call. Throws an [ObserverError].
  Future<ObservedChat> paste(String disputeId, Uint8List key);
}

class RustObserverCore implements ObserverCore {
  const RustObserverCore();

  @override
  Future<ObservedChat?> stored(String disputeId) =>
      observer_api.observedChat(disputeId: disputeId);

  @override
  Future<ObservedChat> read(String disputeId) =>
      observer_api.readObservedChat(disputeId: disputeId);

  @override
  Future<ObservedChat> paste(String disputeId, Uint8List key) =>
      observer_api.pasteSharedKey(disputeId: disputeId, key: key);
}
