import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/qr_palette.dart';

import '../support/contrast.dart';

/// A scanner needs dark marks on a light ground; the same in both themes.
void main() {
  test('modules and finder rings are near-black on the paper', () {
    expect(contrastRatio(QrPalette.ink, QrPalette.paper), greaterThan(15));
  });

  test('the green finder centres still read as dark', () {
    expect(contrastRatio(QrPalette.eye, QrPalette.paper), greaterThan(3));
  });
}
