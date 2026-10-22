import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminance(Color c) {
  double linear(double channel) =>
      channel <= 0.03928
          ? channel / 12.92
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b);
}

/// WCAG contrast ratio of [fg] on [bg].
double contrastRatio(Color fg, Color bg) {
  final lf = _luminance(fg);
  final lb = _luminance(bg);
  return (math.max(lf, lb) + 0.05) / (math.min(lf, lb) + 0.05);
}

/// Flattens a possibly-translucent [fill] over opaque [surface] — how a
/// translucent chip or tint actually renders.
Color flatten(Color fill, Color surface) {
  double mix(double f, double b) => f * fill.a + b * (1 - fill.a);
  return Color.from(
    alpha: 1,
    red: mix(fill.r, surface.r),
    green: mix(fill.g, surface.g),
    blue: mix(fill.b, surface.b),
  );
}

/// Expects [fg] on [bg] to reach WCAG AA for body text, 4.5:1 (DS-COL-6).
void expectAA(String label, Color fg, Color bg) {
  final ratio = contrastRatio(fg, bg);
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason: '$label: ${ratio.toStringAsFixed(2)}:1 < 4.5:1',
  );
}
