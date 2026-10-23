import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/features/disputes/screens/in_progress_screen.dart';
import 'package:bosstro/features/disputes/screens/pending_screen.dart';
import 'package:bosstro/features/settings/screens/settings_screen.dart';
import 'package:bosstro/features/shell/screens/home_shell.dart';
import 'package:bosstro/features/solver_key/screens/backup_screen.dart';
import 'package:bosstro/features/solver_key/screens/create_account_screen.dart';
import 'package:bosstro/features/solver_key/screens/login_screen.dart';
import 'package:bosstro/features/solver_key/screens/qr_scan_screen.dart';
import 'package:bosstro/features/solver_key/screens/welcome_screen.dart';

/// Every path the app routes to, in one place.
abstract final class AppRoute {
  static const welcome = '/welcome';
  static const login = '/login';
  static const createAccount = '/create-account';
  static const scanQr = '/scan-qr';

  static const pending = '/pending';
  static const inProgress = '/in-progress';
  static const settings = '/settings';
  static const backup = '/settings/backup';

  /// The bottom bar's destinations, in order.
  static const tabs = [pending, inProgress, settings];

  /// Where a solver without a key may be.
  static const _public = {welcome, login, createAccount, scanQr};

  /// Where [location] leads; null to stay. Only a solver without a key
  /// ([signedIn] false) is moved, to Welcome.
  ///
  /// A logged-in solver is never moved off the onboarding screens here: with
  /// `push`, go_router hands the redirect the location at the base of the
  /// stack (Welcome) rather than the pushed screen, so such a rule would
  /// pull Create new account away before it shows the npub. Log in and
  /// Create new account go to the tabs themselves when they are done.
  static String? redirect(String location, {required bool signedIn}) {
    if (!signedIn && !_public.contains(location)) return welcome;
    return null;
  }
}

/// The router. The three tabs are branches of one shell, so each keeps its
/// own stack and scroll position while the solver moves between them.
/// [signedIn] is listened to: logging out moves the solver to Welcome at
/// once.
GoRouter buildRouter({
  required ValueListenable<bool> signedIn,
  String initialLocation = AppRoute.pending,
}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    refreshListenable: signedIn,
    redirect:
        (context, state) =>
            AppRoute.redirect(state.matchedLocation, signedIn: signedIn.value),
    routes: [
      GoRoute(
        path: AppRoute.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoute.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.createAccount,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: AppRoute.scanQr,
        builder: (context, state) => const QrScanScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.pending,
                builder: (context, state) => const PendingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.inProgress,
                builder: (context, state) => const InProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'backup',
                    // Over the shell: the backup has no bottom bar.
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const BackupScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
