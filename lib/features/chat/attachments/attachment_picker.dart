import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// The largest file the chat sends, as `MAX_ATTACHMENT_BYTES` in
/// `rust/src/attachments/mod.rs`. Checked before a picked file is read, so a
/// 2 GB video is refused without loading it; Rust checks it again.
const int kMaxAttachmentBytes = 25 * 1024 * 1024;

/// `512 KB`, `1,4 MB`: a file size as the chat shows it, in [locale].
String formatAttachmentSize(int bytes, String locale) {
  if (bytes >= 1024 * 1024) {
    final mb = NumberFormat('0.0', locale).format(bytes / (1024 * 1024));
    return '$mb MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}

/// Where the solver takes a file from, one per row of the attach sheet.
enum AttachmentSource { photo, camera, pdf }

/// A file the solver chose, not read yet.
@immutable
class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.size,
    required this.read,
  });

  /// The name the platform gave it. Rust sanitizes it before it is sent.
  final String name;

  final int size;

  /// Loads the bytes. Called only after the size check and the solver's
  /// confirmation, so a refused file is never read into memory.
  final Future<Uint8List> Function() read;
}

/// What came back from a pick.
sealed class PickOutcome {
  const PickOutcome();
}

/// The solver closed the picker.
class PickCancelled extends PickOutcome {
  const PickCancelled();
}

/// Over [kMaxAttachmentBytes]; refused before reading it.
class PickTooLarge extends PickOutcome {
  const PickTooLarge();
}

class Picked extends PickOutcome {
  const Picked(this.file);

  final PickedAttachment file;
}

/// Checks the size before anything is read.
PickOutcome checkPicked(PickedAttachment file) =>
    file.size > kMaxAttachmentBytes ? const PickTooLarge() : Picked(file);

/// The platform pickers behind the attach sheet, from ../app.
///
/// Photos and the camera go through `image_picker` (the system photo picker
/// on Android, a file dialog on Linux); PDFs through `file_picker`. What is
/// sent is decided by Rust from the bytes, not from anything said here.
class AttachmentPicker {
  AttachmentPicker({ImagePicker? imagePicker})
    : _images = imagePicker ?? ImagePicker();

  final ImagePicker _images;

  /// Whether this device has a camera the picker can open. False on Linux
  /// and the web.
  bool get supportsCamera =>
      !kIsWeb && _images.supportsImageSource(ImageSource.camera);

  Future<PickOutcome> pick(AttachmentSource source) => switch (source) {
    AttachmentSource.photo => _pickImage(ImageSource.gallery),
    AttachmentSource.camera => _pickImage(ImageSource.camera),
    AttachmentSource.pdf => _pickPdf(),
  };

  Future<PickOutcome> _pickImage(ImageSource source) async {
    // Full metadata would ask for photo-library access; Rust strips the
    // metadata anyway.
    final file = await _images.pickImage(
      source: source,
      requestFullMetadata: false,
    );
    if (file == null) return const PickCancelled();
    return checkPicked(
      PickedAttachment(
        name: file.name,
        size: await file.length(),
        read: file.readAsBytes,
      ),
    );
  }

  Future<PickOutcome> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      // Read later, and only if the size passes. The web has no path to read
      // from later: it hands over a stream of the browser's File.
      withData: false,
      withReadStream: kIsWeb,
    );
    final file = result?.files.singleOrNull;
    if (file == null) return const PickCancelled();
    final stream = file.readStream;
    return checkPicked(
      PickedAttachment(
        name: file.name,
        size: file.size,
        read:
            stream != null
                ? () => collectBytes(stream)
                : file.xFile.readAsBytes,
      ),
    );
  }
}

/// Every chunk of [stream] in one buffer.
@visibleForTesting
Future<Uint8List> collectBytes(Stream<List<int>> stream) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => AttachmentPicker(),
);
