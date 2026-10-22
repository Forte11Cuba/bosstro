import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/providers/device_security_providers.dart';
import 'package:bosstro/shared/widgets/input_source_action.dart';
import 'package:bosstro/shared/widgets/key_card.dart';
import 'package:bosstro/shared/widgets/mostro_qr.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/snackbar.dart';

/// The copy for each refusal of a key (Rust returns markers, Dart words).
String keyErrorText(AppLocalizations l10n, SolverKeyError error) =>
    switch (error) {
      SolverKeyError.empty => l10n.keyErrorEmpty,
      SolverKeyError.publicKeyGiven => l10n.keyErrorPublicKey,
      SolverKeyError.invalid => l10n.keyErrorInvalid,
      // Only the safe replace can meet it, and it unloads first.
      SolverKeyError.alreadyLoaded => l10n.keySaveFailed,
    };

/// Copies a secret key the way a secret is copied, never like an id
/// (`copyId`): marked sensitive, so Android 13+ hides it in the copy preview
/// and keyboards keep it out of their history, and cleared from the
/// clipboard after a minute. The snackbar says so (DS-CMP-15).
Future<void> copySecretKey(
  BuildContext context,
  WidgetRef ref,
  String secret,
) async {
  final copied = AppLocalizations.of(context).secretKeyCopied;
  HapticFeedback.selectionClick();
  await ref.read(sensitiveClipboardProvider).copy(secret);
  if (context.mounted) showMostroSnackBar(context, copied);
}

/// A step's title on the key screens: 17/w600, a header for screen readers.
class StepHeading extends StatelessWidget {
  const StepHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: ShellPalette.of(context).textPrimary,
      ),
    ),
  );
}

/// A step's explanation: 14 sp, `textSecondary`, height 1.5.
class StepBody extends StatelessWidget {
  const StepBody(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 14,
      height: 1.5,
      color: ShellPalette.of(context).textSecondary,
    ),
  );
}

/// The npub to hand to the node operator: its QR, the npub whole (it is
/// compared character by character), copy, and share.
class NpubShare extends StatelessWidget {
  const NpubShare({super.key, required this.npub});

  final String npub;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: MostroQr(data: npub, semanticsLabel: l10n.npubQrLabel)),
        const SizedBox(height: 14),
        KeyCard(
          label: l10n.npubLabel,
          value: npub,
          copyLabel: l10n.copyNpub,
          onCopy: () => copyId(context, npub),
        ),
        const SizedBox(height: 12),
        InputSourceAction(
          icon: Icons.share_rounded,
          label: l10n.shareNpub,
          onTap: () => SharePlus.instance.share(ShareParams(text: npub)),
        ),
      ],
    );
  }
}
