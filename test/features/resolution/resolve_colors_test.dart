import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/features/resolution/widgets/resolution_card.dart';

import '../../support/screen_harness.dart';

const _id = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';

/// The button whose label is [label].
ButtonStyle _style(WidgetTester tester, String label) =>
    tester
        .widget<OutlinedButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(OutlinedButton),
          ),
        )
        .style!;

void main() {
  for (final (brightness, pal) in [
    (Brightness.dark, DisputesPalette.dark),
    (Brightness.light, DisputesPalette.light),
  ]) {
    testWidgets(
      'each resolve action takes its party tint, ${brightness.name}',
      (tester) async {
        await pumpWidgetAlone(
          tester,
          SingleChildScrollView(
            child: ResolutionCard(detail: sampleDetail(id: _id)),
          ),
          brightness: brightness,
        );
        final pay = _style(tester, 'Pagar al comprador');
        final refund = _style(tester, 'Devolver al vendedor');
        final none = <WidgetState>{};
        expect(pay.backgroundColor!.resolve(none), pal.observedBuyerFill);
        expect(pay.foregroundColor!.resolve(none), pal.observedBuyerLabel);
        expect(pay.side!.resolve(none)!.color, pal.observedBuyerBorder);
        expect(refund.backgroundColor!.resolve(none), pal.observedSellerFill);
        expect(refund.foregroundColor!.resolve(none), pal.observedSellerLabel);
        expect(refund.side!.resolve(none)!.color, pal.observedSellerBorder);
        // Same weight: same height, same type.
        expect(
          tester.getSize(find.text('Pagar al comprador')).height,
          tester.getSize(find.text('Devolver al vendedor')).height,
        );
        expect(
          pay.minimumSize!.resolve(none),
          refund.minimumSize!.resolve(none),
        );
      },
    );
  }
}
