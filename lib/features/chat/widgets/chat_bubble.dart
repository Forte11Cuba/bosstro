import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/features/chat/attachments/attachment_flow.dart';
import 'package:bosstro/features/chat/providers/chat_providers.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/attachment_content.dart';
import 'package:bosstro/l10n/app_localizations.dart';

/// One chat message. This solver's own sit on the right on a lime tint, the
/// party's on the left on its role's hue (the buyer teal, the seller
/// magenta, amendment 8); the sender is always named in words too, never by
/// color alone (DS-COL-10). The look is the disputes
/// palette's, not ../app's legacy chat (amendment 2).
///
/// The text is the party's own and is not trusted: it is shown as plain
/// text, with no links, no markup and nothing tappable in it.
///
/// An attachment (its text is ../app's JSON) shows the file instead: an
/// image previewed once it is verified and decrypted, a PDF by its name and
/// size, with Save.
///
/// A message of this key that was not sent says so under the bubble, on the
/// page, with a retry ([onRetry]).
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.chat,
    required this.message,
    required this.now,
    this.onRetry,
  });

  /// The conversation the message is in.
  final ChatKey chat;

  final ChatMessageView message;

  /// Today, to write a time of today without its date.
  final DateTime now;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = DisputesPalette.of(context);
    final shell = ShellPalette.of(context);
    final mine = message.sender == ChatSender.you;
    // The party's hue is the conversation's: the buyer's in the buyer's.
    final side = pal.party(buyer: chat.party == ChatParty.buyer);
    final sender = chatSenderLabel(l10n, message.sender);
    final time = chatTimeLabel(
      message.createdAt.toInt(),
      now,
      Localizations.localeOf(context).toString(),
    );
    final delivery = switch (message.delivery) {
      ChatDelivery.sending => l10n.chatSending,
      _ => null,
    };
    final attachment = message.attachment;
    final reference = (
      disputeId: chat.disputeId,
      party: chat.party,
      messageId: message.id,
    );
    final body = switch (attachment) {
      // Plain text: never linkified or parsed.
      null => Text(
        message.content,
        style: TextStyle(fontSize: 14, height: 1.4, color: pal.bubbleInk),
      ),
      ChatAttachment(kind: ChatAttachmentKind.image) => AttachmentImage(
        reference: reference,
        attachment: attachment,
      ),
      _ => AttachmentFileCard(reference: reference, attachment: attachment),
    };
    // What a screen reader says of the message's body.
    final spoken = switch (attachment) {
      null => message.content,
      _ => l10n.attachmentFileLabel(
        attachment.fileName,
        attachmentDetails(
          attachment,
          Localizations.localeOf(context).toString(),
        ),
      ),
    };

    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: mine ? pal.bubbleMineFill : side.fill,
        borderRadius: BorderRadius.circular(AppRadius.block),
        border: Border.all(color: mine ? pal.bubbleMineBorder : side.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Read in the message's label, not again on their own.
          ExcludeSemantics(
            child: Text(
              sender,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: mine ? pal.bubbleYouLabel : side.label,
              ),
            ),
          ),
          SizedBox(height: attachment == null ? 4 : 8),
          body,
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Text(
              delivery == null ? time : '$time · $delivery',
              style: TextStyle(fontSize: 11, color: pal.bubbleMeta),
            ),
          ),
        ],
      ),
    );

    final failed = message.delivery == ChatDelivery.failed;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.82,
              ),
              child:
                  attachment == null
                      ? MergeSemantics(
                        child: Semantics(
                          label: l10n.chatMessageLabel(
                            sender,
                            delivery == null ? time : '$time, $delivery',
                            spoken,
                          ),
                          child: ExcludeSemantics(child: bubble),
                        ),
                      )
                      // The file's own controls (open, save, retry) stay
                      // reachable; the message is still read as one line.
                      : Semantics(
                        container: true,
                        label: l10n.chatMessageLabel(
                          sender,
                          delivery == null ? time : '$time, $delivery',
                          spoken,
                        ),
                        child: bubble,
                      ),
            ),
            if (failed)
              // The retry goes under the words when both do not fit.
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: shell.dangerText,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.chatNotSent,
                          style: TextStyle(
                            fontSize: 12,
                            color: shell.dangerText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: shell.limeText,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(l10n.chatRetry),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// The sender in words (glossary: buyer, seller).
String chatSenderLabel(AppLocalizations l10n, ChatSender sender) =>
    switch (sender) {
      ChatSender.you => l10n.chatSenderYou,
      ChatSender.buyer => l10n.chatSenderBuyer,
      ChatSender.seller => l10n.chatSenderSeller,
    };

/// A message's time: `14:05` today, `23 oct 14:05` another day.
String chatTimeLabel(int createdAt, DateTime now, String locale) {
  final at = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
  final sameDay =
      at.year == now.year && at.month == now.month && at.day == now.day;
  return sameDay
      ? DateFormat.Hm(locale).format(at)
      : DateFormat.MMMd(locale).add_Hm().format(at);
}
