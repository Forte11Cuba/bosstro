import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/chat/attachments/attachment_picker.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';

/// Asks where the file comes from, from ../app. Resolves to null when
/// dismissed. The camera row is offered only where there is one.
Future<AttachmentSource?> showAttachSheet(
  BuildContext context, {
  required bool showCamera,
}) {
  return showMostroSheet<AttachmentSource>(
    context: context,
    builder: (sheet) {
      final l10n = AppLocalizations.of(sheet);
      return MostroSheet(
        title: l10n.attachSheetTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SourceRow(
              icon: Icons.photo_library_outlined,
              label: l10n.attachSourcePhoto,
              source: AttachmentSource.photo,
            ),
            if (showCamera)
              _SourceRow(
                icon: Icons.photo_camera_outlined,
                label: l10n.attachSourceCamera,
                source: AttachmentSource.camera,
              ),
            _SourceRow(
              icon: Icons.picture_as_pdf_outlined,
              label: l10n.attachSourcePdf,
              source: AttachmentSource.pdf,
            ),
            const SizedBox(height: 10),
            _Note(text: l10n.attachSheetNote),
          ],
        ),
      );
    },
  );
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.label,
    required this.source,
  });

  final IconData icon;
  final String label;
  final AttachmentSource source;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return ListTile(
      minTileHeight: 48,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      leading: Icon(icon, size: 22, color: pal.limeIcon),
      title: Text(
        label,
        style: TextStyle(fontSize: 15, color: pal.textPrimary),
      ),
      onTap: () => Navigator.of(context).pop(source),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: pal.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: pal.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
