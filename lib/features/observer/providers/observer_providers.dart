import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/chat/providers/chat_providers.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/observer/services/observer_core.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';

/// The core behind the observer. Tests override it with a fake.
final observerCoreProvider = Provider<ObserverCore>(
  (ref) => const RustObserverCore(),
);

/// The observed chat of one dispute as the screen shows it: what is stored,
/// and how the last read from the relays went.
@immutable
class ObserverView {
  const ObserverView({
    required this.chat,
    this.reading = false,
    this.error,
    this.readOnce = false,
  });

  final ObservedChat chat;

  /// A read from the relays is under way.
  final bool reading;

  /// Why the last read failed; null when it did not, or none was made.
  final ObserverError? error;

  /// A read finished while this view lived: an empty chat is then an
  /// answer, not a question not asked yet.
  final bool readOnce;

  /// A key that can read is known: a party shared one, or one was pasted.
  bool get hasKey => chat.disclosures.isNotEmpty || chat.hasPastedKey;

  /// Something can be shown or read.
  bool get canRead => hasKey || chat.messages.isNotEmpty;

  ObserverView copyWith({
    ObservedChat? chat,
    bool? reading,
    ObserverError? Function()? error,
    bool? readOnce,
  }) => ObserverView(
    chat: chat ?? this.chat,
    reading: reading ?? this.reading,
    error: error == null ? this.error : error(),
    readOnce: readOnce ?? this.readOnce,
  );
}

/// The observed chat of a dispute this key holds; null when it is not this
/// key's on the active node. Stored state is read again when a message
/// arrives in the dispute's own chats (a party may just have shared its
/// key); the relays are asked only by [ObservedChatNotifier.refresh] and
/// [ObservedChatNotifier.paste].
final observedChatProvider = AsyncNotifierProvider.autoDispose
    .family<ObservedChatNotifier, ObserverView?, String>(
      ObservedChatNotifier.new,
    );

class ObservedChatNotifier
    extends AutoDisposeFamilyAsyncNotifier<ObserverView?, String> {
  /// How long chat updates are gathered before the store is read again.
  static const coalesce = Duration(milliseconds: 150);

  Timer? _pending;

  ObserverCore get _core => ref.read(observerCoreProvider);

  @override
  Future<ObserverView?> build(String arg) async {
    ref.watch(activeNodeProvider);
    ref.watch(solverKeyProvider);
    ref.listen(chatUpdatesProvider, (_, next) {
      final update = next.valueOrNull;
      if (update == null ||
          update.mostroPubkey != ref.read(activeNodeProvider)) {
        return;
      }
      if (update.disputeId == null || update.disputeId == arg) _schedule();
    });
    ref.onDispose(() => _pending?.cancel());
    final chat = await _core.stored(arg);
    return chat == null ? null : ObserverView(chat: chat);
  }

  void _schedule() {
    if (_pending?.isActive ?? false) return;
    _pending = Timer(coalesce, () => unawaited(_reloadStored()));
  }

  Future<void> _reloadStored() async {
    try {
      final chat = await _core.stored(arg);
      final current = state.valueOrNull;
      state = AsyncData(
        chat == null
            ? null
            : current == null
            ? ObserverView(chat: chat)
            : current.copyWith(chat: chat),
      );
    } catch (e) {
      debugPrint('[observer] not read from storage: $e');
    }
  }

  /// Ask the relays again with every key known. What is stored stays on
  /// screen meanwhile and after a failure.
  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null || current.reading) return;
    state = AsyncData(current.copyWith(reading: true));
    try {
      final chat = await _core.read(arg);
      state = AsyncData(ObserverView(chat: chat, readOnce: true));
    } catch (e) {
      final error = e is ObserverError ? e : ObserverError.fetchFailed;
      if (e is! ObserverError) debugPrint('[observer] read failed: $e');
      final now = state.valueOrNull ?? current;
      state = AsyncData(
        now.copyWith(reading: false, error: () => error, readOnce: true),
      );
    }
  }

  /// Check a pasted key ([key]: its UTF-8 bytes, wiped by the caller).
  /// Returns why it was refused, or null once it read.
  Future<ObserverError?> paste(Uint8List key) async {
    try {
      final chat = await _core.paste(arg, key);
      state = AsyncData(ObserverView(chat: chat, readOnce: true));
      return null;
    } on ObserverError catch (e) {
      return e;
    } catch (e) {
      debugPrint('[observer] paste failed: $e');
      return ObserverError.fetchFailed;
    }
  }
}
