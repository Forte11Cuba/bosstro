import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/features/chat/attachments/attachment_flow.dart';
import 'package:bosstro/features/chat/attachments/attachment_picker.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/chat_bubble.dart';
import 'package:bosstro/features/observer/services/observer_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';

/// One message of the chat between the parties. The buyer's sit on the
/// left in the buyer's hue (teal), the seller's on the right in the seller's
/// (magenta): the same hues as in the solver's own chats, as Mostrix
/// (amendment 8); the side is named in words too (DS-COL-10). The text is the party's own and is shown as plain text: no
/// links, no markup, nothing tappable.
///
/// A file shows by its name and type and cannot be opened: ../app encrypts
/// the files of this chat with a key the chat key does not give. The bubble
/// says so and how to get it (ask that party for it in their chat with the
/// solver, where files open).
class ObservedBubble extends StatelessWidget {
  const ObservedBubble({super.key, required this.message, required this.now});

  final ObservedMessage message;

  /// Today, to write a time of today without its date.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = DisputesPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final buyer = message.sender == ChatParty.buyer;
    final sender = buyer ? l10n.chatSenderBuyer : l10n.chatSenderSeller;
    final time = chatTimeLabel(message.createdAt.toInt(), now, locale);
    final attachment = message.attachment;
    final side = pal.party(buyer: buyer);

    final body = switch (attachment) {
      // Plain text: never linkified or parsed.
      null => Text(
        message.content,
        style: TextStyle(fontSize: 14, height: 1.4, color: pal.bubbleInk),
      ),
      final file => _LockedFile(attachment: file, buyer: buyer),
    };
    final spoken = switch (attachment) {
      null => message.content,
      final file => l10n.attachmentFileLabel(
        file.fileName,
        '${lockedFileDetails(l10n, file, locale)}. ${l10n.observerFileLocked}',
      ),
    };

    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: side.fill,
        borderRadius: BorderRadius.circular(AppRadius.block),
        border: Border.all(color: side.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: side.label,
            ),
          ),
          SizedBox(height: attachment == null ? 4 : 8),
          body,
          const SizedBox(height: 6),
          Text(time, style: TextStyle(fontSize: 11, color: pal.bubbleMeta)),
        ],
      ),
    );

    return LayoutBuilder(
      builder:
          (context, constraints) => Align(
            alignment: buyer ? Alignment.centerLeft : Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.82,
              ),
              child: MergeSemantics(
                child: Semantics(
                  label: l10n.chatMessageLabel(sender, time, spoken),
                  child: ExcludeSemantics(child: bubble),
                ),
              ),
            ),
          ),
    );
  }
}

/// A file of the parties' chat: its name, its size and type as declared,
/// that it cannot be opened, and whom to ask for it.
class _LockedFile extends StatelessWidget {
  const _LockedFile({required this.attachment, required this.buyer});

  final ChatAttachment attachment;
  final bool buyer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = DisputesPalette.of(context);
    final shell = ShellPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final meta = TextStyle(fontSize: 12, height: 1.4, color: pal.bubbleMeta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: shell.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: pal.bubbleInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lockedFileDetails(l10n, attachment, locale),
                    style: meta,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.observerFileLocked, style: meta),
        Text(
          buyer ? l10n.observerFileAdviceBuyer : l10n.observerFileAdviceSeller,
          style: meta,
        ),
      ],
    );
  }
}

/// `1,4 MB · PDF`, or the declared type itself (sanitized in Rust) when it
/// is not one the chat names, or "Image" / "File" when it declares none.
String lockedFileDetails(
  AppLocalizations l10n,
  ChatAttachment attachment,
  String locale,
) {
  final known = attachmentDetails(attachment, locale);
  final size = formatAttachmentSize(attachment.size, locale);
  if (known != size) return known;
  final type = switch (attachment.mimeType) {
    '' when attachment.kind == ChatAttachmentKind.image =>
      l10n.observerFileImage,
    '' => l10n.observerFileOther,
    final declared => declared,
  };
  return '$size · $type';
}
