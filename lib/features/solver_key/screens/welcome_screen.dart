import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/warning_note.dart';

/// Welcome (D9): "Log in" (primary) and "Create new account" (secondary).
/// What a solver without a key sees at launch.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  /// The Bosstro emblem, built from `icons/bosstro.png`.
  static const emblemAsset = 'assets/images/bosstro_emblem.webp';

  static const double _emblemSide = 120;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// Set while a screen pushed from here is open. A second tap that lands
  /// before the first push shows (a slow phone, a double tap) is ignored:
  /// two Create new account screens would each generate their own nsec, and
  /// backing out of the top one would show another key.
  bool _navigating = false;

  Future<void> _open(String route) async {
    if (_navigating) return;
    _navigating = true;
    try {
      await context.push(route);
    } finally {
      if (mounted) _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final unreadable = ref.watch(storedKeyUnreadableProvider);

    return Scaffold(
      backgroundColor: pal.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  redesignSidePadding,
                  32,
                  redesignSidePadding,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      child: Image.asset(
                        WelcomeScreen.emblemAsset,
                        height: WelcomeScreen._emblemSide,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.welcomeTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: pal.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.welcomeBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: pal.textSecondary,
                      ),
                    ),
                    if (unreadable) ...[
                      const SizedBox(height: 24),
                      WarningNote(text: l10n.welcomeKeyUnreadable),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                redesignSidePadding,
                12,
                redesignSidePadding,
                redesignSidePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: l10n.welcomeLogIn,
                    onPressed: () => _open(AppRoute.login),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: l10n.welcomeCreateAccount,
                    onPressed: () => _open(AppRoute.createAccount),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
