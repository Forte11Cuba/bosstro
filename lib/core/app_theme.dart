import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bosstro/core/shell_palette.dart';

export 'package:bosstro/core/shell_palette.dart';

// ── Responsive breakpoints ────────────────────────────────────────────────────

/// Logical-pixel breakpoints (DS-SPC-4). The dispute detail opens on a
/// screen of its own at any width (no split view since 2026-10-23).
abstract final class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1200;
}

// ── Border-radius tokens ───────────────────────────────────────────────────────

/// The radii of the guide (DS-SHP-1), by role. Bosstro has no v1 layer, so
/// none of MostroP2P/app's v1 radii exist here, and their names (`card`,
/// `button`, `input`, `chip`) stay unused: the design check reads them as v1
/// (DS-SHP-4).
abstract final class AppRadius {
  static const double pill = 999;

  /// Dialog and bottom-sheet container, applied by the theme.
  static const double modal = 24;

  /// Cards, list rows, grouped settings sections.
  static const double block = 18;

  /// The in-page call to action and its outlined sibling.
  static const double pageCta = 16;

  /// Modal actions, compact secondary buttons, boxed inputs.
  static const double cta = 14;

  /// Tiles inside a card, snackbars.
  static const double tile = 12;

  /// Thumbnails, QR frames.
  static const double thumbnail = 8;
}

// ── Typography tokens ─────────────────────────────────────────────────────────

/// Font families bundled in `pubspec.yaml` (`fonts:`), DS-TYP-1.
abstract final class AppFonts {
  /// Interface text. Both themes set it as the default family, so a
  /// `TextStyle` without a family inherits it.
  static const String ui = 'Outfit';

  /// Figures that line up or get compared — amounts, sats, counters. Its
  /// digits are tabular.
  ///
  /// Only weights 500, 600 and 700 are bundled: always set `fontWeight`
  /// explicitly (DS-TYP-3).
  static const String figures = 'Manrope';

  /// Flags only, as a `fontFamilyFallback` ([flagFontFallback], DS-TYP-8).
  static const String flags = 'NotoFlags';

  /// Machine strings: keys and ids (DS-TYP-1).
  static const String mono = 'monospace';
}

/// The fallback list that draws flags from [AppFonts.flags] (DS-TYP-8). Null
/// on iOS and macOS, whose Core Text cannot draw the font's bitmaps and
/// whose own emoji font has every flag.
List<String>? flagFontFallback(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
        ? null
        : const [AppFonts.flags];

// ── ThemeData factories ────────────────────────────────────────────────────────

// Built once and shared: MaterialApp asks for both themes on every rebuild.
ThemeData? _darkTheme;
ThemeData? _lightTheme;

ThemeData buildDarkTheme() =>
    _darkTheme ??= _buildTheme(Brightness.dark, ShellPalette.dark);

ThemeData buildLightTheme() =>
    _lightTheme ??= _buildTheme(Brightness.light, ShellPalette.light);

/// The theme, built from the palette (Bosstro amendment 1): a widget that
/// leaves its style to the theme already looks like the redesign. Components
/// still style themselves from the palette (DS-CMP-12, DS-CMP-17 to 19);
/// this is the floor, not the style.
ThemeData _buildTheme(Brightness brightness, ShellPalette pal) {
  final ctaShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.pageCta),
  );
  const buttonText = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  return ThemeData(
    brightness: brightness,
    fontFamily: AppFonts.ui,
    fontFamilyFallback: flagFontFallback(defaultTargetPlatform),
    scaffoldBackgroundColor: pal.bg,
    canvasColor: pal.bg,
    dividerColor: pal.border,
    splashFactory: InkRipple.splashFactory,
    // No page transitions (DS-MOT-1).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _NoTransitionBuilder(),
        TargetPlatform.iOS: _NoTransitionBuilder(),
        TargetPlatform.linux: _NoTransitionBuilder(),
        TargetPlatform.macOS: _NoTransitionBuilder(),
        TargetPlatform.windows: _NoTransitionBuilder(),
      },
    ),
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: pal.lime,
      onPrimary: pal.onLime,
      secondary: pal.lime,
      onSecondary: pal.onLime,
      error: pal.danger,
      onError: pal.onDanger,
      surface: pal.surface,
      onSurface: pal.textPrimary,
      surfaceTint: Colors.transparent,
      outline: pal.border,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: pal.bg,
      foregroundColor: pal.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: pal.textBody),
    ),
    cardTheme: CardThemeData(
      color: pal.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.block),
        side: BorderSide(color: pal.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: pal.lime,
        foregroundColor: pal.onLime,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: ctaShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: pal.textBody,
        side: BorderSide(color: pal.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: ctaShape,
        textStyle: buttonText.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: pal.limeText),
    ),
    // Every modal surface: radius, surface and scrim decided once (DS-CMP-1).
    dialogTheme: DialogThemeData(
      backgroundColor: pal.surface,
      surfaceTintColor: Colors.transparent,
      barrierColor: pal.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: pal.textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: 14,
        height: 1.5,
        color: pal.textSecondary,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: pal.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: pal.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.modal),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: pal.surface,
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.ui,
        color: pal.textStrong,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
    ),
    // Underline fields (DS-CMP-10): no fill, lime on focus, red on error.
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      labelStyle: TextStyle(color: pal.textSecondary),
      hintStyle: TextStyle(color: pal.textFaint),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: pal.divider),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: pal.lime, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: pal.dangerText),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: pal.dangerText, width: 2),
      ),
      errorStyle: TextStyle(fontSize: 12, color: pal.dangerText),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: pal.lime),
    // Only the roles on the type scale (DS-TYP-4); the rest are not used.
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: pal.textBody),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: pal.textSecondary),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: pal.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: pal.textSecondary,
      ),
    ),
  );
}

// Instant page transition — no animation (DS-MOT-1).
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
