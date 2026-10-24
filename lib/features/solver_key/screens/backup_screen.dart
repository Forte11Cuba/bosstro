import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/platform_capabilities.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/features/solver_key/widgets/key_widgets.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/key_card.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/secure_window.dart';
import 'package:bosstro/shared/widgets/warning_note.dart';

/// Settings → Backup: the stored secret key, whole, to write down. Reached
/// only through the warning dialog in Settings (AGENTS.md → "Key handling",
/// 5). It reads secure storage; Rust is not asked for the secret.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  late final Future<String?> _secret =
      ref.read(solverKeyServiceProvider).readBackup();

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return SecureWindow(
      child: Scaffold(
        backgroundColor: pal.bg,
        appBar: redesignAppBar(
          context,
          title: l10n.backupTitle,
          onBack: () => context.pop(),
        ),
        // Over the shell, with no bottom bar: the SafeArea keeps the last
        // warning clear of the system navigation bar (../app #267).
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              redesignSidePadding,
              8,
              redesignSidePadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StepBody(l10n.backupBody),
                const SizedBox(height: 18),
                FutureBuilder<String?>(
                  future: _secret,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    final secret = snapshot.data;
                    if (snapshot.hasError || secret == null) {
                      return WarningNote(text: l10n.backupUnavailable);
                    }
                    return KeyCard(
                      label: l10n.secretKeyLabel,
                      value: secret,
                      copyLabel: l10n.copySecretKey,
                      onCopy:
                          PlatformCapabilities.copySecret
                              ? () => copySecretKey(context, ref, secret)
                              : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                WarningNote(text: l10n.traderKeyWarning),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
