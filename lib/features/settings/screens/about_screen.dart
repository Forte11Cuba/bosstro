import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/project_links.dart';
import 'package:bosstro/core/settings_palette.dart';
import 'package:bosstro/features/settings/widgets/settings_row.dart';
import 'package:bosstro/features/solver_key/screens/welcome_screen.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/providers/core_providers.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// Opens [Uri] outside the app; true when something took it. A provider so
/// a test sees what was opened without a platform channel.
final openExternalUrlProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// The AGPLv3 notice the FSF recommends programs display, kept verbatim and
/// **not** localized, as MostroP2P/app: a translated licence has no legal force
/// (<https://www.gnu.org/licenses/translations.html>), so every locale shows
/// the English original and only the dialog's title is translated. The full
/// text is `LICENSE`.
const _agplLicenseNotice = '''Bosstro
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

/// Characters of a commit hash shown on a row, as MostroP2P/app.
const int shortHashLength = 7;

/// [hash] cut to [shortHashLength] (MostroP2P/app's `shortHash`).
String shortHash(String hash) =>
    hash.length <= shortHashLength ? hash : hash.substring(0, shortHashLength);

/// Settings → About, MostroP2P/app's About for what Bosstro has: the version
/// and the commit the build was made from (MostroP2P/app's Application rows),
/// the licence and the source code — the offer AGPL section 13 asks of an app
/// that talks to its users over a network. The node's data is Settings →
/// Node info.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const double _emblemSide = 88;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final settings = SettingsPalette.of(context);
    final version = ref.watch(appVersionProvider);
    final commit = ref.watch(appCommitProvider);

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: redesignAppBar(
        context,
        title: l10n.aboutScreenTitle,
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
            const SizedBox(height: 24),
            GroupHeader(
              title: l10n.aboutAppSection,
              color: settings.groupHeader,
            ),
            const SizedBox(height: 8),
            OrderDataCard(
              rows: [
                OrderDataRow(
                  icon: Icons.info_outline_rounded,
                  label: l10n.aboutVersionLabel,
                  // MostroP2P/app's version pill: "v2.1.0".
                  value: OrderDataValue('v$version', figures: true),
                ),
                if (commit.isNotEmpty)
                  OrderDataRow(
                    icon: Icons.commit_rounded,
                    label: l10n.aboutCommitHashLabel,
                    value: OrderDataValue(shortHash(commit), figures: true),
                  ),
                SettingsRow(
                  icon: Icons.balance_rounded,
                  label: l10n.aboutLicenseLabel,
                  value: l10n.aboutLicenseName,
                  onTap: () => _showLicenseDialog(context),
                ),
                SettingsRow(
                  icon: Icons.code_rounded,
                  label: l10n.aboutSourceCodeLabel,
                  value: sourceCodeRepository,
                  valueIsData: true,
                  onTap: () => _openExternal(context, ref, sourceCodeUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    showMostroDialog<void>(
      context: context,
      builder:
          (dialog) => MostroDialog(
            title: l10n.aboutLicenseDialogTitle,
            content: SizedBox(
              width: double.maxFinite,
              height: 320,
              child: SingleChildScrollView(
                child: Text(
                  _agplLicenseNotice,
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
}

/// Opens [url] in the external browser. With no app to hand it to, the link
/// is offered on a snackbar instead, with a copy action (MostroP2P/app's).
Future<void> _openExternal(
  BuildContext context,
  WidgetRef ref,
  String url,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var launched = false;
  try {
    launched = await ref.read(openExternalUrlProvider)(Uri.parse(url));
  } catch (_) {
    // A platform without a browser throws instead of returning false; both
    // land on the same fallback below.
    launched = false;
  }
  if (launched) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(url),
        action: SnackBarAction(
          label: l10n.copyButtonLabel,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            messenger.showSnackBar(
              SnackBar(
                content: Text(l10n.linkCopiedToClipboard),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
}
