import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/features/disputes/screens/in_progress_screen.dart';
import 'package:bosstro/features/disputes/screens/pending_screen.dart';
import 'package:bosstro/features/settings/screens/settings_screen.dart';
import 'package:bosstro/features/shell/screens/home_shell.dart';

/// Every path the app routes to, in one place.
abstract final class AppRoute {
  static const pending = '/pending';
  static const inProgress = '/in-progress';
  static const settings = '/settings';

  /// The bottom bar's destinations, in order.
  static const tabs = [pending, inProgress, settings];
}

/// The router. The three tabs are branches of one shell, so each keeps its
/// own stack and scroll position while the solver moves between them.
GoRouter buildRouter({String initialLocation = AppRoute.pending}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        for (final (path, screen) in const <(String, Widget)>[
          (AppRoute.pending, PendingScreen()),
          (AppRoute.inProgress, InProgressScreen()),
          (AppRoute.settings, SettingsScreen()),
        ])
          StatefulShellBranch(
            routes: [GoRoute(path: path, builder: (context, state) => screen)],
          ),
      ],
    ),
  ],
);
