import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/project_links.dart';
import 'package:bosstro/features/settings/widgets/settings_row.dart';
import 'package:bosstro/features/solver_key/screens/welcome_screen.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/providers/core_providers.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/snackbar.dart';

/// Opens [Uri] outside the app; true when something took it. A provider so
/// a test sees what was opened without a platform channel.
final openExternalUrlProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// The AGPLv3 notice the FSF recommends programs display, kept verbatim and
/// **not** localized (as ../app): a translated licence has no legal force
/// (<https://www.gnu.org/licenses/translations.html>), so every locale shows
/// the English original and only the dialog's title is translated. The full
/// text is `LICENSE`.
const _agplNotice = '''Bosstro
Copyright (C) 2026 the Bosstro contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.''';

/// Settings → About: the app, its version and the commit it was built from,
/// its licence, its source code — the offer AGPL section 13 asks of an app
/// that talks to its users over a network — and the licences of what it
/// ships (Flutter's licence page, where the fonts' OFL is registered).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const double _emblemSide = 88;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final version = ref.watch(appVersionProvider);
    final commit = ref.watch(appCommitProvider);

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: redesignAppBar(
        context,
        title: l10n.aboutTitle,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            redesignSidePadding,
            8,
            redesignSidePadding,
            24,
          ),
          children: [
            ExcludeSemantics(
              child: Image.asset(
                WelcomeScreen.emblemAsset,
                height: _emblemSide,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                l10n.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: pal.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.aboutTagline,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: pal.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              buildLabel(version, commit),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.figures,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: pal.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            OrderDataCard(
              rows: [
                SettingsRow(
                  icon: Icons.balance_rounded,
                  label: l10n.aboutLicense,
                  value: l10n.aboutLicenseName,
                  onTap: () => _showLicense(context),
                ),
                SettingsRow(
                  icon: Icons.code_rounded,
                  label: l10n.aboutSourceCode,
                  value: sourceCodeRepository,
                  onTap: () => _openSource(context, ref),
                ),
                SettingsRow(
                  icon: Icons.description_outlined,
                  label: l10n.aboutOpenSourceLicenses,
                  onTap:
                      () => showLicensePage(
                        context: context,
                        applicationName: l10n.appName,
                        applicationVersion: version,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "0.1.0 · 1a2b3c4": the version, and the commit when the build named one
  /// (a release does; a local build does not).
  @visibleForTesting
  static String buildLabel(String version, String commit) {
    if (commit.isEmpty) return version;
    final short = commit.length > 7 ? commit.substring(0, 7) : commit;
    return '$version · $short';
  }

  void _showLicense(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    showMostroDialog<void>(
      context: context,
      builder:
          (dialog) => MostroDialog(
            title: l10n.aboutLicenseDialogTitle,
            content: SizedBox(
              height: 320,
              child: SingleChildScrollView(
                child: Text(
                  _agplNotice,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 12,
                    height: 1.5,
                    color: pal.textSecondary,
                  ),
                ),
              ),
            ),
            primary: ModalAction(
              label: l10n.close,
              onPressed: () => Navigator.of(dialog).pop(),
            ),
          ),
    );
  }

  /// The repository in the browser. With nothing to hand it to, the link is
  /// copied instead, and the snackbar says so.
  Future<void> _openSource(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    var opened = false;
    try {
      opened = await ref.read(openExternalUrlProvider)(
        Uri.parse(sourceCodeUrl),
      );
    } catch (_) {
      // A platform without a browser throws instead of returning false.
    }
    if (opened || !context.mounted) return;
    try {
      await Clipboard.setData(const ClipboardData(text: sourceCodeUrl));
    } catch (_) {
      // Nothing to confirm: the repository is on the row itself.
      return;
    }
    if (context.mounted) showMostroSnackBar(context, l10n.aboutLinkCopied);
  }
}
