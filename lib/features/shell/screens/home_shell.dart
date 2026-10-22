import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/shared/widgets/bottom_nav_bar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// The three-tab shell: the tab app bar on top, the active tab, and the
/// bottom bar (Pending · In progress · Settings).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Scaffold(
      backgroundColor: pal.bg,
      body: Column(
        children: [
          // The node arrives with phase 2; until then the bar says none is
          // chosen.
          const TabAppBar(),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: shell.currentIndex,
        onSelect:
            (index) => shell.goBranch(
              index,
              // A tap on the active tab returns it to its root.
              initialLocation: index == shell.currentIndex,
            ),
      ),
    );
  }
}
