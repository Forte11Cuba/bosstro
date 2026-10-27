import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';

/// Side padding of every screen (DS-SPC-1), and the right inset of the app
/// bar's actions so they line up with the content below.
const double redesignSidePadding = 18;

/// The app bar of every pushed screen (DS-CMP-12): back arrow, a 15/600
/// sentence-case title, and actions flush right.
///
/// [actions] are placed verbatim, so each screen sets its own right inset to
/// [redesignSidePadding]. A null [onBack] drops the arrow — a terminal step
/// with nowhere to go back to — and the title moves to the side padding.
/// A null [title] leaves the bar to the way back, for a screen whose own
/// headline names it (a full-screen confirmation).
PreferredSizeWidget redesignAppBar(
  BuildContext context, {
  String? title,
  required VoidCallback? onBack,
  List<Widget> actions = const [],
}) {
  final pal = ShellPalette.of(context);
  return AppBar(
    backgroundColor: pal.bg,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    automaticallyImplyLeading: false,
    leading:
        onBack == null
            ? null
            : IconButton(
              icon: Icon(Icons.arrow_back, size: 22, color: pal.textBody),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
            ),
    titleSpacing: onBack == null ? redesignSidePadding : 0,
    title: switch (title) {
      final text? => Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: pal.textPrimary,
        ),
      ),
      null => null,
    },
    actions: actions.isEmpty ? null : actions,
  );
}
