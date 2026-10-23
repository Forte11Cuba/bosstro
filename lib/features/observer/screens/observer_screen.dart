import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/observer/providers/observer_providers.dart';
import 'package:bosstro/features/observer/services/observer_core.dart';
import 'package:bosstro/features/observer/widgets/observed_bubble.dart';
import 'package:bosstro/features/observer/widgets/paste_key_dialog.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/labeled_icon_action.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/secure_window.dart';

/// Open the chat between the parties of [disputeId] (pushed over the detail,
/// as the image viewer).
Future<void> openObserverScreen(BuildContext context, String disputeId) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ObserverScreen(disputeId: disputeId),
      ),
    );

/// What the buyer and the seller wrote to each other, read with the key of
/// their chat (Mostrix's Observer tab), read only: no message field, a note
/// pinned where it would be. The relays are asked when the screen opens
/// with a key known and on Refresh; what was read is kept, so it shows
/// before that and after a failure.
///
/// The parties' conversation is not the solver's, so the window is secure
/// while it is open (FLAG_SECURE on Android): no screenshot, recording or
/// recent-apps thumbnail.
class ObserverScreen extends ConsumerStatefulWidget {
  const ObserverScreen({super.key, required this.disputeId});

  final String disputeId;

  @override
  ConsumerState<ObserverScreen> createState() => _ObserverScreenState();
}

class _ObserverScreenState extends ConsumerState<ObserverScreen> {
  bool _asked = false;

  ObservedChatNotifier get _notifier =>
      ref.read(observedChatProvider(widget.disputeId).notifier);

  /// Ask the relays once per visit, as soon as a key is known.
  void _readOnce(ObserverView? view) {
    if (_asked || view == null || !view.hasKey) return;
    _asked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_notifier.refresh());
    });
  }

  Future<void> _paste() =>
      openPasteKeyDialog(context, disputeId: widget.disputeId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final state = ref.watch(observedChatProvider(widget.disputeId));
    final view = state.valueOrNull;
    _readOnce(view);
    final reading = view?.reading ?? false;
    return SecureWindow(
      child: Scaffold(
        backgroundColor: pal.bg,
        appBar: redesignAppBar(
          context,
          title: l10n.observerTitle,
          onBack: () => Navigator.of(context).pop(),
          actions: [
            if (view != null) ...[
              IconButton(
                onPressed: _paste,
                tooltip: l10n.observerPasteAction,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.key_rounded, size: 22, color: pal.limeIcon),
              ),
              Padding(
                padding: const EdgeInsets.only(right: redesignSidePadding - 12),
                child: IconButton(
                  onPressed: view.hasKey && !reading ? _notifier.refresh : null,
                  tooltip: l10n.observerRefresh,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color:
                        view.hasKey && !reading
                            ? pal.limeIcon
                            : pal.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
        body: switch (state) {
          AsyncData(value: null) => ListEmptyState(
            sticker: 'thinking',
            title: l10n.detailNotYoursTitle,
            body: l10n.detailNotYoursBody,
          ),
          AsyncError() => ListEmptyState(
            sticker: 'thinking',
            title: l10n.pendingLoadErrorTitle,
            body: l10n.pendingLoadErrorBody,
          ),
          AsyncData(value: final view?) => _Body(
            view: view,
            onPaste: _paste,
            onRefresh: _notifier.refresh,
          ),
          _ => _loading(l10n),
        },
      ),
    );
  }
}

Widget _loading(AppLocalizations l10n) => SingleChildScrollView(
  physics: const NeverScrollableScrollPhysics(),
  child: ListSkeleton(label: l10n.chatLoading, rowHeight: 72),
);

class _Body extends StatelessWidget {
  const _Body({
    required this.view,
    required this.onPaste,
    required this.onRefresh,
  });

  final ObserverView view;
  final VoidCallback onPaste;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final chat = view.chat;
    final since = observerSinceLabel(chat.since.toInt(), locale);
    final pasteLink = LabeledIconAction(
      icon: Icons.key_rounded,
      label: l10n.observerPasteAction,
      onPressed: onPaste,
    );

    final Widget content;
    if (chat.messages.isNotEmpty) {
      content = _Messages(
        messages: chat.messages,
        header: switch (view.error) {
          final error? => _ErrorBanner(text: _errorLine(l10n, error, since)),
          null => null,
        },
      );
    } else if (!view.hasKey) {
      content = ListEmptyState(
        sticker: 'confused',
        title: l10n.observerNoKeyTitle,
        body: l10n.observerNoKey,
        action: PrimaryButton(
          label: l10n.observerPasteAction,
          onPressed: onPaste,
        ),
      );
    } else if (view.error case final error?) {
      content = switch (error) {
        ObserverError.keyOpensNothing => ListEmptyState(
          sticker: 'confused',
          title: l10n.observerOpensNothingTitle,
          body: l10n.observerOpensNothingBody(since),
          action: pasteLink,
        ),
        ObserverError.noPartyKeys => ListEmptyState(
          sticker: 'confused',
          title: l10n.observerNoPartyKeysTitle,
          body: l10n.observerNoPartyKeysBody,
        ),
        ObserverError.unknownDispute ||
        ObserverError.noKey ||
        ObserverError.noNode => ListEmptyState(
          sticker: 'thinking',
          title: l10n.detailNotYoursTitle,
          body: l10n.detailNotYoursBody,
        ),
        _ => ListEmptyState(
          sticker: 'thinking',
          title: l10n.observerReadFailedTitle,
          body: l10n.observerReadFailedBody,
          action: PrimaryButton(
            label: l10n.observerRefresh,
            onPressed: onRefresh,
          ),
        ),
      };
    } else {
      // A key is known and the relays are being asked.
      content = _loading(l10n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: content),
        if (chat.messages.isNotEmpty || view.hasKey)
          _ReadOnlyNote(text: _readOnlyNote(l10n, chat)),
      ],
    );
  }
}

/// Who opened what the screen shows: in words, under it.
String _readOnlyNote(AppLocalizations l10n, ObservedChat chat) {
  final parties = chat.disclosures.map((d) => d.party).toSet();
  if (parties.length > 1) return l10n.observerReadOnlyBoth;
  if (parties.contains(ChatParty.buyer)) return l10n.observerReadOnlyBuyer;
  if (parties.contains(ChatParty.seller)) return l10n.observerReadOnlySeller;
  if (chat.hasPastedKey) return l10n.observerReadOnlyPasted;
  return l10n.observerReadOnlyStored;
}

/// A failed refresh over messages read before: one line above them.
String _errorLine(AppLocalizations l10n, ObserverError error, String since) =>
    switch (error) {
      ObserverError.keyOpensNothing => l10n.observerOpensNothingShort(since),
      ObserverError.noPartyKeys => l10n.observerNoPartyKeysBody,
      ObserverError.unknownDispute ||
      ObserverError.noKey ||
      ObserverError.noNode => l10n.observerNotYours,
      ObserverError.invalidKey ||
      ObserverError.noSharedKey => l10n.observerReadOnlyStored,
      ObserverError.noRelays || ObserverError.fetchFailed =>
        '${l10n.observerReadFailedTitle}. ${l10n.observerReadFailedBody}',
    };

/// The messages, newest at the bottom; times are written against a clock
/// that moves every minute. [header] sits above the oldest, in the same
/// scroll (a failed refresh).
class _Messages extends StatefulWidget {
  const _Messages({required this.messages, this.header});

  final List<ObservedMessage> messages;
  final Widget? header;

  @override
  State<_Messages> createState() => _MessagesState();
}

class _MessagesState extends State<_Messages> {
  late DateTime _now = clock.now();
  late final Timer _tick = Timer.periodic(
    const Duration(minutes: 1),
    (_) => setState(() => _now = clock.now()),
  );

  @override
  void initState() {
    super.initState();
    _tick;
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        12,
        redesignSidePadding,
        12,
      ),
      itemCount: messages.length + (widget.header == null ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        // Reversed: the last item is the top one.
        if (i == messages.length) return widget.header!;
        final message = messages[messages.length - 1 - i];
        return ObservedBubble(
          key: ValueKey(message.id),
          message: message,
          now: _now,
        );
      },
    );
  }
}

/// A refresh that failed, above messages read before (they stay).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: pal.dangerText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: pal.dangerText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// In place of a message field: this chat is read only, and with whose key.
class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          redesignSidePadding,
          8,
          redesignSidePadding,
          12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: pal.inset,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: pal.border),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, size: 16, color: pal.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: pal.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
