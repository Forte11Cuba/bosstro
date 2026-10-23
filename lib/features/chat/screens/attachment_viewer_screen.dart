import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/chat/attachments/attachment_flow.dart';
import 'package:bosstro/features/chat/attachments/attachment_providers.dart';
import 'package:bosstro/features/chat/widgets/attachment_content.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/secure_window.dart';

/// Most a zoomable image is magnified.
const double kViewerMaxScale = 5;

/// An image of the chat, full screen, with pinch zoom, and Save (the
/// system's save dialog, a download on the web).
///
/// A dispute's evidence is sensitive, so the window is secure while it is
/// open (`SecureWindow`: FLAG_SECURE on Android, nothing elsewhere): no
/// screenshot, recording or recent-apps thumbnail of the full image. The
/// solver keeps a copy with Save.
class AttachmentViewerScreen extends ConsumerWidget {
  const AttachmentViewerScreen({
    super.key,
    required this.reference,
    required this.fileName,
  });

  final AttachmentRef reference;
  final String fileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final opened = ref.watch(openedAttachmentProvider(reference));
    final file = opened.valueOrNull;
    return SecureWindow(
      child: Scaffold(
        backgroundColor: pal.bg,
        appBar: redesignAppBar(
          context,
          title: fileName,
          onBack: () => Navigator.of(context).pop(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: redesignSidePadding - 12),
              child: IconButton(
                onPressed:
                    file == null
                        ? null
                        : () => saveAttachment(context, ref, file),
                tooltip: l10n.attachmentSave,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(
                  Icons.download_rounded,
                  size: 22,
                  color: file == null ? pal.textTertiary : pal.limeIcon,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: switch (opened) {
            AsyncData(:final value) when value.isImage => LayoutBuilder(
              builder:
                  (context, box) => Semantics(
                    label: l10n.attachmentImageLabel(fileName),
                    hint: l10n.attachmentViewerZoomHint,
                    image: true,
                    child: InteractiveViewer(
                      maxScale: kViewerMaxScale,
                      child: SizedBox(
                        width: box.maxWidth,
                        height: box.maxHeight,
                        child: Image.memory(
                          value.bytes,
                          fit: BoxFit.contain,
                          // Sharp when zoomed, bounded in memory.
                          cacheWidth: decodeWidth(context, box.maxWidth * 2),
                          excludeFromSemantics: true,
                          errorBuilder:
                              (_, _, _) => AttachmentProblem(
                                text: l10n.attachmentInvalidImage,
                              ),
                        ),
                      ),
                    ),
                  ),
            ),
            AsyncData() => AttachmentProblem(text: l10n.attachmentNotVerified),
            AsyncError(:final error) => AttachmentProblem(
              text: openErrorText(l10n, error),
              onRetry:
                  isRetryableOpenError(error)
                      ? () =>
                          ref.invalidate(openedAttachmentProvider(reference))
                      : null,
            ),
            _ => AttachmentSkeleton(label: l10n.attachmentLoading),
          },
        ),
      ),
    );
  }
}
