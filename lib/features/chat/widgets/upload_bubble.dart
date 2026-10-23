import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/features/chat/attachments/attachment_flow.dart';
import 'package:bosstro/features/chat/attachments/attachment_picker.dart';
import 'package:bosstro/features/chat/attachments/upload_controller.dart';
import 'package:bosstro/l10n/app_localizations.dart';

/// The solver's file on its way out: its progress, or why it failed and
/// what can be done, from ../app. Replaced by the message once the core
/// returns it. There is no cancel: an upload cannot be stopped midway, and a
/// bubble that said "cancelled" while the file still reached the party
/// would lie.
///
/// Drawn as the solver's own bubble; "Not sent" and the actions sit under
/// it, on the page, as a text message's (the danger ink does not reach
/// 4.5:1 on the lime tint).
class UploadBubble extends StatelessWidget {
  const UploadBubble({
    super.key,
    required this.upload,
    required this.onRetry,
    required this.onDiscard,
  });

  final PendingUpload upload;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = DisputesPalette.of(context);
    final shell = ShellPalette.of(context);
    final failed = upload.status == UploadStatus.failed;
    final isPdf = upload.fileName.toLowerCase().endsWith('.pdf');
    final size = formatAttachmentSize(
      upload.bytes.length,
      Localizations.localeOf(context).toString(),
    );
    final status =
        failed
            ? attachmentErrorText(l10n, upload.error)
            : l10n.attachmentUploading;

    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: pal.bubbleMineFill,
        borderRadius: BorderRadius.circular(AppRadius.block),
        border: Border.all(color: pal.bubbleMineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.chatSenderYou,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: pal.bubbleYouLabel,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                size: 22,
                color: shell.limeIcon,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upload.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: pal.bubbleInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      size,
                      style: TextStyle(fontSize: 12, color: pal.bubbleMeta),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!failed) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: upload.progress > 0 ? upload.progress : null,
                minHeight: 4,
                color: shell.lime,
                backgroundColor: pal.bubbleMineBorder,
              ),
            ),
            const SizedBox(height: 6),
            Text(status, style: TextStyle(fontSize: 11, color: pal.bubbleMeta)),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder:
          (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.82,
                ),
                child: MergeSemantics(
                  child: Semantics(
                    label: '${upload.fileName}, $size: $status',
                    liveRegion: failed,
                    child: ExcludeSemantics(child: bubble),
                  ),
                ),
              ),
              if (failed) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: shell.dangerText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${l10n.chatNotSent}. $status',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 12, color: shell.dangerText),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  children: [
                    if (isRetryableUploadError(upload.error))
                      _Action(label: l10n.chatRetry, onPressed: onRetry),
                    _Action(
                      label: l10n.attachmentDiscard,
                      onPressed: onDiscard,
                      quiet: true,
                    ),
                  ],
                ),
              ],
            ],
          ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onPressed,
    this.quiet = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final shell = ShellPalette.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: quiet ? shell.textSecondary : shell.limeText,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
