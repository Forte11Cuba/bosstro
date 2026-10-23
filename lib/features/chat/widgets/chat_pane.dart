import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/chat/providers/chat_providers.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/chat_bubble.dart';
import 'package:bosstro/features/chat/widgets/chat_composer.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// The chat with one party of a dispute: the messages, newest at the
/// bottom, and the message field pinned under them while the dispute is
/// open. A closed dispute's chat is read only; a party whose key the node
/// did not name has none.
class ChatPane extends ConsumerWidget {
  const ChatPane({super.key, required this.chat});

  final ChatKey chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final thread = ref.watch(chatThreadProvider(chat));
    return switch (thread) {
      AsyncData(value: null) => ListEmptyState(
        sticker: 'thinking',
        title: l10n.detailNotYoursTitle,
        body: l10n.detailNotYoursBody,
      ),
      AsyncData(:final value?) => _Thread(chat: chat, thread: value),
      AsyncError() => ListEmptyState(
        sticker: 'thinking',
        title: l10n.pendingLoadErrorTitle,
        body: l10n.pendingLoadErrorBody,
      ),
      _ => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ListSkeleton(label: l10n.chatLoading, rowHeight: 72),
      ),
    };
  }
}

class _Thread extends ConsumerWidget {
  const _Thread({required this.chat, required this.thread});

  final ChatKey chat;
  final ChatThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (thread.state == ChatChannelState.noPartyKey &&
        thread.messages.isEmpty) {
      return ListEmptyState(
        sticker: 'confused',
        title: l10n.chatNoPartyKeyTitle,
        body: l10n.chatNoPartyKeyBody,
      );
    }
    final body =
        thread.messages.isEmpty
            ? ListEmptyState(
              sticker: 'waving',
              title: switch (chat.party) {
                ChatParty.buyer => l10n.chatEmptyBuyerTitle,
                ChatParty.seller => l10n.chatEmptySellerTitle,
              },
              body: l10n.chatEmptyBody,
            )
            : _Messages(chat: chat, thread: thread);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        switch (thread.state) {
          ChatChannelState.open => ChatComposer(chat: chat),
          ChatChannelState.closed => const _ClosedNote(),
          ChatChannelState.noPartyKey => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// The messages, newest at the bottom; the list starts there and stays
/// there as messages arrive. Times are written against a clock that moves
/// every minute (a message of today loses its date).
class _Messages extends ConsumerStatefulWidget {
  const _Messages({required this.chat, required this.thread});

  final ChatKey chat;
  final ChatThread thread;

  @override
  ConsumerState<_Messages> createState() => _MessagesState();
}

class _MessagesState extends ConsumerState<_Messages> {
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

  Future<void> _retry(ChatMessageView message) async {
    try {
      await ref
          .read(chatCoreProvider)
          .retry(widget.chat.disputeId, widget.chat.party, message.id);
    } on ChatError catch (e) {
      debugPrint('[chat] retry refused: $e');
    }
    await ref.read(chatThreadProvider(widget.chat).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.thread.messages;
    final open = widget.thread.state == ChatChannelState.open;
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        12,
        redesignSidePadding,
        12,
      ),
      itemCount: messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final message = messages[messages.length - 1 - i];
        return ChatBubble(
          key: ValueKey(message.id),
          message: message,
          now: _now,
          onRetry: open ? () => _retry(message) : null,
        );
      },
    );
  }
}

/// In place of the message field once the dispute is over.
class _ClosedNote extends StatelessWidget {
  const _ClosedNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            Icon(
              Icons.comments_disabled_outlined,
              size: 16,
              color: pal.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.chatClosedNote,
                style: TextStyle(fontSize: 13, color: pal.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
