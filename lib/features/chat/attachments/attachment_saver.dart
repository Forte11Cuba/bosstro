import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/chat/attachments/web_download.dart';

/// Saves a decrypted attachment where the solver chooses, from ../app.
///
/// The one path that writes the plaintext to disk, and only through the
/// system's save dialog: the solver picks the place and the name (Android:
/// the Storage Access Framework; Linux: the desktop's dialog). The web has no
/// such dialog, so there the browser downloads it. The name offered is the
/// one Rust sanitized.
class AttachmentSaver {
  const AttachmentSaver();

  /// Resolves to false when the solver closed the dialog.
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) {
      downloadBytes(fileName, bytes);
      return true;
    }
    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: bytes,
    );
    if (path == null) return false;
    // Android writes `bytes` itself; on desktop the dialog only names it.
    if (!Platform.isAndroid && !Platform.isIOS) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return true;
  }
}

final attachmentSaverProvider = Provider<AttachmentSaver>(
  (ref) => const AttachmentSaver(),
);
