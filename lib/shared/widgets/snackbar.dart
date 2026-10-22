import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';

/// The app's snackbar (DS-CMP-15): it confirms something that already
/// happened ("Copied"). Floating, on the surface, radius 12, two seconds.
/// Never an error the solver must act on — that belongs in the screen.
void showMostroSnackBar(BuildContext context, String text) {
  final pal = ShellPalette.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle(color: pal.textStrong)),
        backgroundColor: pal.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}
