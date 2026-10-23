import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// Builds the camera preview: [onDetected] with each decoded value, and
/// [onError] in its place when the camera cannot start.
typedef ScannerBuilder =
    Widget Function(ValueChanged<String> onDetected, WidgetBuilder onError);

/// The camera preview the scanner shows. Tests override it with a fake, since
/// there is no camera plugin under `flutter test`.
final qrScannerProvider = Provider<ScannerBuilder>(
  (ref) => QrScanScreen.cameraScanner,
);

/// Scans a QR code and pops with its text, once. Log in pushes it and puts
/// what it returns in the secret key field.
///
/// The camera's frames never leave the plugin; the decoded value comes back
/// as a `String`, like a paste.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  static Widget cameraScanner(
    ValueChanged<String> onDetected,
    WidgetBuilder onError,
  ) => MobileScanner(
    // Without it, a refused permission or a phone without a camera shows the
    // plugin's black box and nothing to do.
    errorBuilder: (context, _) => onError(context),
    onDetect: (capture) {
      final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) onDetected(raw);
    },
  );

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  /// A code held in front of the camera is decoded on several frames; the
  /// screen pops on the first.
  bool _done = false;

  void _detected(String value) {
    if (_done) return;
    _done = true;
    context.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: pal.bg,
      appBar: redesignAppBar(
        context,
        title: l10n.scanTitle,
        onBack: () => context.pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ref.watch(qrScannerProvider)(
              _detected,
              (context) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(redesignSidePadding),
                  child: Text(
                    l10n.scanUnavailable,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: pal.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(redesignSidePadding),
              child: Text(
                l10n.scanHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: pal.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
