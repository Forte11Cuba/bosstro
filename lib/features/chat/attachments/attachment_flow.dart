import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/chat/attachments/attachment_picker.dart';
import 'package:bosstro/features/chat/attachments/attachment_saver.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/attach_sheet.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/snackbar.dart';

/// A file the solver picked and confirmed, read into memory.
typedef AttachmentToSend = ({String name, Uint8List bytes});

/// The paperclip's steps before an upload, from MostroP2P/app: the source
/// sheet, the pick, the size check, the confirmation and the read.
///
/// Resolves to null when the solver backed out or the file cannot be sent;
/// then the solver was already told why. [onBusy] brackets the pick and the
/// read, which can take a while for a large file.
Future<AttachmentToSend?> pickAttachmentToSend(
  BuildContext context,
  WidgetRef ref, {
  required ChatParty party,
  required ValueChanged<bool> onBusy,
}) async {
  final picker = ref.read(attachmentPickerProvider);
  final source = await showAttachSheet(
    context,
    showCamera: picker.supportsCamera,
  );
  if (source == null || !context.mounted) return null;
  onBusy(true);
  try {
    final outcome = await picker.pick(source);
    if (!context.mounted) return null;
    switch (outcome) {
      case PickCancelled():
        return null;
      case PickTooLarge():
        await showAttachmentError(
          context,
          AppLocalizations.of(context).attachmentTooLarge,
        );
        return null;
      case Picked(:final file):
        if (!await _confirmSend(context, file, party)) return null;
        return (name: file.name, bytes: await file.read());
    }
  } catch (e) {
    // A refused camera permission or an unreadable file.
    debugPrint('[chat] pick attachment failed: $e');
    if (context.mounted) {
      await showAttachmentError(
        context,
        AppLocalizations.of(context).attachmentReadFailed,
      );
    }
    return null;
  } finally {
    if (context.mounted) onBusy(false);
  }
}

Future<bool> _confirmSend(
  BuildContext context,
  PickedAttachment file,
  ChatParty party,
) async {
  final locale = Localizations.localeOf(context).toString();
  final confirmed = await showMostroDialog<bool>(
    context: context,
    builder: (dialog) {
      final l10n = AppLocalizations.of(dialog);
      final size = formatAttachmentSize(file.size, locale);
      return MostroDialog(
        icon: Icons.lock_outline_rounded,
        title: l10n.attachConfirmTitle,
        body: switch (party) {
          ChatParty.buyer => l10n.attachConfirmBuyer(file.name, size),
          ChatParty.seller => l10n.attachConfirmSeller(file.name, size),
        },
        secondary: ModalAction(
          label: l10n.cancel,
          onPressed: () => Navigator.of(dialog).pop(false),
        ),
        primary: ModalAction(
          label: l10n.chatSend,
          onPressed: () => Navigator.of(dialog).pop(true),
        ),
      );
    },
  );
  return confirmed ?? false;
}

/// An attachment failure the solver must read: a dialog, not a snackbar
/// (DS-CMP-15).
Future<void> showAttachmentError(BuildContext context, String message) {
  return showMostroDialog<void>(
    context: context,
    builder:
        (dialog) => MostroDialog(
          icon: Icons.error_outline_rounded,
          iconTone: ModalTone.destructive,
          title: message,
          primary: ModalAction(
            label: MaterialLocalizations.of(dialog).okButtonLabel,
            onPressed: () => Navigator.of(dialog).pop(),
          ),
        ),
  );
}

/// Opens the save dialog for [file]. Confirms with "Saved"; says nothing
/// when the dialog was closed; a failure is a dialog.
Future<void> saveAttachment(
  BuildContext context,
  WidgetRef ref,
  OpenedAttachment file,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    final saved = await ref
        .read(attachmentSaverProvider)
        .save(fileName: file.fileName, bytes: file.bytes);
    if (saved && context.mounted) {
      showMostroSnackBar(context, l10n.attachmentSaved);
    }
  } catch (e) {
    debugPrint('[chat] save attachment failed: $e');
    if (context.mounted) {
      await showAttachmentError(context, l10n.attachmentSaveFailed);
    }
  }
}

/// What went wrong with a file, in words.
String attachmentErrorText(AppLocalizations l10n, ChatError? error) =>
    switch (error) {
      ChatError.fileTooLarge => l10n.attachmentTooLarge,
      ChatError.unsupportedFile => l10n.attachmentUnsupported,
      ChatError.invalidImage => l10n.attachmentInvalidImage,
      ChatError.uploadFailed => l10n.attachmentUploadFailed,
      ChatError.closed => l10n.chatErrorClosed,
      ChatError.noRelays => l10n.chatErrorNoRelays,
      ChatError.unknownDispute => l10n.chatErrorNotYours,
      _ => l10n.attachmentSendFailed,
    };

/// Why a received file does not open, in words.
String openErrorText(AppLocalizations l10n, Object error) => switch (error) {
  ChatError.notVerified => l10n.attachmentNotVerified,
  ChatError.downloadFailed => l10n.attachmentDownloadFailed,
  ChatError.unsupportedFile => l10n.attachmentUnsupportedReceived,
  ChatError.invalidImage => l10n.attachmentInvalidImage,
  ChatError.fileTooLarge => l10n.attachmentTooLarge,
  ChatError.noRelays => l10n.chatErrorNoRelays,
  _ => l10n.attachmentOpenFailed,
};

/// The icon of a file the chat shows by name: a PDF, or an image.
IconData attachmentIcon(ChatAttachment attachment) =>
    attachment.kind == ChatAttachmentKind.image
        ? Icons.image_outlined
        : Icons.picture_as_pdf_outlined;

/// `1,4 MB · PDF`: what the chat says of a file under its name. Format
/// names are not translated.
String attachmentDetails(ChatAttachment attachment, String locale) {
  final type = switch (attachment.mimeType) {
    'application/pdf' => 'PDF',
    'image/png' => 'PNG',
    'image/jpeg' => 'JPEG',
    _ => null,
  };
  final size = formatAttachmentSize(attachment.size, locale);
  return type == null ? size : '$size · $type';
}
