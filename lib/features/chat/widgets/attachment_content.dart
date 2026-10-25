import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/features/chat/attachments/attachment_flow.dart';
import 'package:bosstro/features/chat/attachments/attachment_providers.dart';
import 'package:bosstro/features/chat/screens/attachment_viewer_screen.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';

/// Widest an image is drawn inside a bubble, as MostroP2P/app.
const double kImageBubbleMaxWidth = 240;

/// The shape a bubble keeps before its image is decrypted: the sender's
/// width and height, clamped so a declared 1 × 10000 cannot draw a sliver or
/// a tower. 4:3 when the sender gave none.
double imageBubbleAspectRatio(int? width, int? height) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return 4 / 3;
  }
  return (width / height).clamp(0.5, 2.0);
}

/// An image in the chat: downloaded, verified and decrypted when it shows,
/// as MostroP2P/app, and decoded at the size drawn. Tapping it opens the
/// viewer.
class AttachmentImage extends ConsumerWidget {
  const AttachmentImage({
    super.key,
    required this.reference,
    required this.attachment,
  });

  final AttachmentRef reference;
  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shell = ShellPalette.of(context);
    final opened = ref.watch(openedAttachmentProvider(reference));
    final aspect = imageBubbleAspectRatio(attachment.width, attachment.height);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kImageBubbleMaxWidth),
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.thumbnail),
          child: ColoredBox(
            color: shell.inset,
            child: switch (opened) {
              AsyncData(:final value) when value.isImage => Semantics(
                label: l10n.attachmentImageLabel(attachment.fileName),
                image: true,
                button: true,
                onTapHint: l10n.attachmentOpenImage,
                child: GestureDetector(
                  excludeFromSemantics: true,
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => AttachmentViewerScreen(
                                reference: reference,
                                fileName: attachment.fileName,
                              ),
                        ),
                      ),
                  child: LayoutBuilder(
                    builder:
                        (context, box) => Image.memory(
                          value.bytes,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          // Decode at the size drawn, not at the photo's.
                          cacheWidth: decodeWidth(context, box.maxWidth),
                          excludeFromSemantics: true,
                          errorBuilder:
                              (_, _, _) => AttachmentProblem(
                                text: l10n.attachmentInvalidImage,
                              ),
                        ),
                  ),
                ),
              ),
              AsyncData() => AttachmentProblem(
                text: l10n.attachmentNotVerified,
              ),
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
      ),
    );
  }
}

/// Pixels to decode an image drawn [logicalWidth] wide, at most [max].
int? decodeWidth(BuildContext context, double logicalWidth, {int max = 4096}) {
  if (!logicalWidth.isFinite || logicalWidth <= 0) return null;
  final pixels = (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
  return pixels > max ? max : pixels;
}

/// A file the chat shows by name (a PDF): its name, size and type. Nothing
/// is downloaded until the solver saves it; it is never opened inside the
/// app. A file that fails its checks says so here, with a retry when
/// trying again can help.
class AttachmentFileCard extends ConsumerStatefulWidget {
  const AttachmentFileCard({
    super.key,
    required this.reference,
    required this.attachment,
  });

  final AttachmentRef reference;
  final ChatAttachment attachment;

  @override
  ConsumerState<AttachmentFileCard> createState() => _AttachmentFileCardState();
}

class _AttachmentFileCardState extends ConsumerState<AttachmentFileCard> {
  bool _busy = false;
  Object? _error;

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ref.read(
        openedAttachmentProvider(widget.reference).future,
      );
      if (mounted) await saveAttachment(context, ref, file);
    } catch (e) {
      ref.invalidate(openedAttachmentProvider(widget.reference));
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = DisputesPalette.of(context);
    final shell = ShellPalette.of(context);
    final attachment = widget.attachment;
    final details = attachmentDetails(
      attachment,
      Localizations.localeOf(context).toString(),
    );
    final error = _error;
    final blocked = error != null && !isRetryableOpenError(error);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(attachmentIcon(attachment), size: 24, color: shell.limeIcon),
            const SizedBox(width: 10),
            Expanded(
              // Read in the message's label.
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attachment.fileName,
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
                      details,
                      style: TextStyle(fontSize: 12, color: pal.bubbleMeta),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox.square(
              dimension: 48,
              child:
                  _busy
                      ? Center(
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: shell.limeIcon,
                          ),
                        ),
                      )
                      : IconButton(
                        onPressed: blocked ? null : _save,
                        tooltip: l10n.attachmentSaveHint,
                        icon: Icon(
                          Icons.download_rounded,
                          size: 22,
                          color: blocked ? shell.textTertiary : shell.limeIcon,
                        ),
                      ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          _ProblemLine(text: openErrorText(l10n, error)),
        ],
      ],
    );
  }
}

/// What went wrong with a file, inside its bubble: an icon and the words
/// (never color alone, DS-COL-10), with a retry when it can help.
class AttachmentProblem extends StatelessWidget {
  const AttachmentProblem({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shell = ShellPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProblemLine(text: text, centered: true),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: shell.limeText,
                  minimumSize: const Size(48, 48),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n.chatRetry),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProblemLine extends StatelessWidget {
  const _ProblemLine({required this.text, this.centered = false});

  final String text;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final shell = ShellPalette.of(context);
    final icon = Icon(
      Icons.gpp_maybe_outlined,
      size: 16,
      color: shell.textSecondary,
    );
    final words = Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(fontSize: 12, height: 1.35, color: shell.textPrimary),
    );
    if (centered) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(height: 4), words],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [icon, const SizedBox(width: 6), Expanded(child: words)],
    );
  }
}

/// The shimmer an image shows while it downloads and decrypts (DS-CMP-13),
/// still when animations are off (DS-MOT-3). Read as [label].
class AttachmentSkeleton extends StatelessWidget {
  const AttachmentSkeleton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Shimmer.fromColors(
          enabled: !MediaQuery.disableAnimationsOf(context),
          baseColor: Color.alphaBlend(pal.inset, pal.bg),
          highlightColor: Color.alphaBlend(pal.border, pal.bg),
          period: const Duration(milliseconds: 1800),
          child: ColoredBox(color: pal.surface, child: const SizedBox.expand()),
        ),
      ),
    );
  }
}
