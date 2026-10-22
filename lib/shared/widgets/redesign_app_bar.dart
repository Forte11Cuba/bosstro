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
PreferredSizeWidget redesignAppBar(
  BuildContext context, {
  required String title,
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
    title: Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: pal.textPrimary,
      ),
    ),
    actions: actions.isEmpty ? null : actions,
  );
}
