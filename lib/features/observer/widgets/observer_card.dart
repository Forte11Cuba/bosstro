import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/observer/providers/observer_providers.dart';
import 'package:bosstro/features/observer/screens/observer_screen.dart';
import 'package:bosstro/features/observer/widgets/paste_key_dialog.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/labeled_icon_action.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';

/// The Info segment's way into the chat between the parties: who shared the
/// key of their chat and when, "Read the chat between the parties" once
/// there is something to read, and "Paste a chat key" always.
class ObserverCard extends ConsumerWidget {
  const ObserverCard({super.key, required this.disputeId});

  final String disputeId;

  Future<void> _paste(BuildContext context) async {
    final read = await openPasteKeyDialog(context, disputeId: disputeId);
    if (read && context.mounted) await openObserverScreen(context, disputeId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(observedChatProvider(disputeId)).valueOrNull;
    if (view == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final chat = view.chat;

    String when(int seconds) => DateFormat.yMMMd(
      locale,
    ).add_Hm().format(DateTime.fromMillisecondsSinceEpoch(seconds * 1000));
    final lines = [
      for (final shared in chat.disclosures)
        switch (shared.party) {
          ChatParty.buyer => l10n.observerSharedByBuyer(
            when(shared.sharedAt.toInt()),
          ),
          ChatParty.seller => l10n.observerSharedBySeller(
            when(shared.sharedAt.toInt()),
          ),
        },
      if (chat.hasPastedKey) l10n.observerPastedKey,
      if (!view.hasKey)
        chat.messages.isEmpty ? l10n.observerNoKey : l10n.observerStoredOnly,
    ];

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined, size: 16, color: pal.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.observerTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: pal.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: pal.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              if (view.canRead)
                LabeledIconAction(
                  icon: Icons.chat_outlined,
                  label: l10n.observerReadAction,
                  onPressed: () => openObserverScreen(context, disputeId),
                ),
              LabeledIconAction(
                icon: Icons.key_rounded,
                label: l10n.observerPasteAction,
                onPressed: () => _paste(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
