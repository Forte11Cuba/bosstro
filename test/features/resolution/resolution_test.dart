import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/disputes/screens/dispute_detail_screen.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/features/resolution/screens/resolution_screen.dart';
import 'package:bosstro/features/resolution/widgets/resolution_card.dart';

import '../../support/screen_harness.dart';

const _opened = 1700000000;
final _now = DateTime.fromMillisecondsSinceEpoch((_opened + 7200) * 1000);

const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';
const _b = '1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9';

/// A dispute this key holds, open, with its detail.
FakeDisputesCore _held({Resolution? unanswered}) =>
    FakeDisputesCore()
      ..held = [sampleTaken(id: _a)]
      ..details[_a] = sampleDetail(id: _a, unanswered: unanswered);

FakeChatCore _chat() =>
    FakeChatCore()
      ..set(_a, ChatParty.buyer)
      ..set(_a, ChatParty.seller)
      ..set(_b, ChatParty.buyer, state: ChatChannelState.closed)
      ..set(_b, ChatParty.seller, state: ChatChannelState.closed);

Future<void> _pump(
  WidgetTester tester,
  FakeDisputesCore core, {
  String? location,
  Brightness brightness = Brightness.dark,
}) => withClock(
  Clock.fixed(_now),
  () => pumpApp(
    tester,
    location: location ?? AppRoute.disputeDetail(_a),
    brightness: brightness,
    overrides: fakeCoreOverrides(disputes: core, chat: _chat()),
  ),
);

/// The Info segment's scrollable (the IndexedStack keeps the chats built).
Finder _info() =>
    find
        .descendant(
          of: find.byType(IndexedStack),
          matching: find.byType(Scrollable),
        )
        .first;

/// Scroll Info to the resolution card's [action] and tap it.
Future<void> _open(WidgetTester tester, String action) async {
  final button = find.descendant(
    of: find.byType(ResolutionCard),
    matching: find.text(action),
  );
  await tester.scrollUntilVisible(button, 200, scrollable: _info());
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// The confirmation's red answer.
Finder _answer(String label) => find.descendant(
  of: find.byType(ResolutionScreen),
  matching: find.widgetWithText(FilledButton, label),
);

/// Scroll the confirmation or the outcome until [finder] shows.
Future<void> _scrollScreenTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable:
        find
            .descendant(
              of: find.byType(ResolutionScreen),
              matching: find.byType(Scrollable),
            )
            .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  // DS-A11Y-4: every new screen at 320 dp, 2× text, Spanish, in both themes,
  // with no overflow.
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('the detail offers both resolutions, $theme', (tester) async {
      setSurface(tester);
      await _pump(tester, _held(), brightness: brightness);
      await tester.scrollUntilVisible(
        find.text('Devolver al vendedor'),
        200,
        scrollable: _info(),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Resolver la disputa'), findsOneWidget);
      expect(find.text('Pagar al comprador'), findsOneWidget);
      // Two actions of the same weight; the red answer is the confirmation's.
      expect(
        find.descendant(
          of: find.byType(ResolutionCard),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
    });

    testWidgets('pay the buyer: who, how much, and that it is final, $theme', (
      tester,
    ) async {
      setSurface(tester);
      final core = _held();
      await _pump(tester, core, brightness: brightness);
      await _open(tester, 'Pagar al comprador');
      expect(tester.takeException(), isNull);
      expect(find.text('¿Pagar al comprador?'), findsOneWidget);
      expect(find.text('El comprador recibe'), findsOneWidget);
      // The order's 75,000 less the node's 750.
      expect(find.text('74.250 sats'), findsOneWidget);
      expect(
        find.text('Los 75.000 sats de la orden menos la comisión del nodo, 750 sats.'),
        findsOneWidget,
      );
      await _scrollScreenTo(tester, find.text('Operación: 50 EUR'));
      await _scrollScreenTo(tester, find.textContaining('el vendedor no recupera'));
      await _scrollScreenTo(tester, find.textContaining('No se puede deshacer'));
      expect(tester.takeException(), isNull);
      // DS-CMP-26: the red answer repeats the action.
      expect(_answer('Pagar al comprador'), findsOneWidget);
      expect(core.resolutions, isEmpty, reason: 'nothing leaves before the answer');
    });

    testWidgets('refund the seller: who, how much, and that it is final, $theme', (
      tester,
    ) async {
      setSurface(tester);
      await _pump(tester, _held(), brightness: brightness);
      await _open(tester, 'Devolver al vendedor');
      expect(tester.takeException(), isNull);
      expect(find.text('¿Devolver al vendedor?'), findsOneWidget);
      expect(find.text('El vendedor recupera'), findsOneWidget);
      expect(find.text('75.750 sats'), findsOneWidget);
      await _scrollScreenTo(tester, find.textContaining('el comprador no recibe nada'));
      await _scrollScreenTo(tester, find.textContaining('No se puede deshacer'));
      expect(_answer('Devolver al vendedor'), findsOneWidget);
    });

    testWidgets('waiting for the node: no way back, no centered spinner, $theme', (
      tester,
    ) async {
      setSurface(tester);
      final core = _held()..resolveAnswer = Completer<void>();
      await _pump(tester, core, brightness: brightness);
      await _open(tester, 'Pagar al comprador');
      await _scrollScreenTo(tester, _answer('Pagar al comprador'));
      await tester.tap(_answer('Pagar al comprador'));
      await tester.pump();
      expect(core.resolutions, [(_a, Resolution.payBuyer)]);
      // The answer's spinner never settles: pump frames instead.
      await tester.scrollUntilVisible(
        find.textContaining('Esperando la respuesta'),
        200,
        scrollable:
            find
                .descendant(
                  of: find.byType(ResolutionScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      // The answer's own spinner, inside the button (DS-CMP-13).
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Atrás'), findsNothing);
      // The system back does not leave either.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(ResolutionScreen), findsOneWidget);
      // A second tap sends nothing more (the busy answer shows no label).
      final busyAnswer = find.descendant(
        of: find.byType(ResolutionScreen),
        matching: find.byType(FilledButton),
      );
      await tester.ensureVisible(busyAnswer);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(busyAnswer, warnIfMissed: false);
      await tester.pump();
      expect(core.resolutions, hasLength(1));

      core.resolveAnswer!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Resuelta: pagaste al comprador'), findsOneWidget);
    });

    const titles = {
      ResolveOutcome.paidBuyer: 'Resuelta: pagaste al comprador',
      ResolveOutcome.refundedSeller: 'Resuelta: devolviste al vendedor',
      ResolveOutcome.cooperativelyCanceled: 'Las partes ya la habían cancelado',
      ResolveOutcome.readOnlySolver: 'No puedes pagar ni devolver en este nodo',
      ResolveOutcome.takenOver: 'Ahora otro solver tiene esta disputa',
      ResolveOutcome.notInDispute: 'Esta orden ya no está en disputa',
      ResolveOutcome.refused: 'El nodo rechazó la petición',
      ResolveOutcome.noAnswer: 'El nodo no respondió',
    };
    for (final MapEntry(key: outcome, value: title) in titles.entries) {
      testWidgets('the outcome ${outcome.name} reads and fits, $theme', (
        tester,
      ) async {
        setSurface(tester);
        final core = _held()..resolveOutcome = outcome;
        final refund = outcome == ResolveOutcome.refundedSeller;
        final action = refund ? 'Devolver al vendedor' : 'Pagar al comprador';
        await _pump(tester, core, brightness: brightness);
        await _open(tester, action);
        await _scrollScreenTo(tester, _answer(action));
        await tester.tap(_answer(action));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(title), findsOneWidget);
        if (outcome == ResolveOutcome.readOnlySolver) {
          expect(
            find.text(
              'Tu clave de solver puede mediar en este nodo pero no pagar ni '
              'devolver. Pide al operador permiso de lectura y escritura.',
            ),
            findsOneWidget,
          );
        }
        if (outcome == ResolveOutcome.noAnswer) {
          expect(find.textContaining('no volvió a enviar'), findsOneWidget);
        }
        final next =
            outcome == ResolveOutcome.takenOver
                ? 'Ir a Tus disputas'
                : 'Volver a la disputa';
        // One way on, no second action.
        expect(find.text(next), findsOneWidget);
        await tester.tap(find.text(next));
        await tester.pumpAndSettle();
        expect(find.byType(ResolutionScreen), findsNothing);
        expect(core.resolutions, hasLength(1), reason: 'never retried');
        if (outcome == ResolveOutcome.takenOver) {
          expect(find.text('Tus disputas'), findsOneWidget);
        }
      });
    }

    testWidgets('a request that did not leave says why, $theme', (tester) async {
      setSurface(tester);
      final core = _held()..resolveError = ResolveError.nodeInfoUnavailable;
      await _pump(tester, core, brightness: brightness);
      await _open(tester, 'Devolver al vendedor');
      await _scrollScreenTo(tester, _answer('Devolver al vendedor'));
      await tester.tap(_answer('Devolver al vendedor'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('La petición no se envió'), findsOneWidget);
      expect(find.textContaining('prueba de trabajo'), findsOneWidget);
    });

    testWidgets('a read-only key keeps the actions and says why, $theme', (
      tester,
    ) async {
      setSurface(tester);
      final core = _held()..permission = SolverPermission.read;
      await _pump(tester, core, brightness: brightness);
      await tester.scrollUntilVisible(
        find.text('Devolver al vendedor'),
        200,
        scrollable: _info(),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Tu clave de solver puede mediar en este nodo'),
        findsOneWidget,
      );
      expect(find.text('Pagar al comprador'), findsOneWidget);
    });

    testWidgets('a request with no answer is named in the detail, $theme', (
      tester,
    ) async {
      setSurface(tester);
      await _pump(
        tester,
        _held(unanswered: Resolution.payBuyer),
        brightness: brightness,
      );
      await tester.scrollUntilVisible(
        find.textContaining('Tu petición de pagar al comprador no tuvo respuesta'),
        200,
        scrollable: _info(),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('closed disputes list under the open ones, read only, $theme', (
      tester,
    ) async {
      setSurface(tester);
      final core =
          FakeDisputesCore()
            ..closed = [
              sampleTaken(
                id: _b,
                status: DisputeStatus.settled,
                resolvedAs: ResolvedAs.paidBuyer,
              ),
            ]
            ..details[_b] = sampleDetail(
              id: _b,
              status: DisputeStatus.settled,
              resolvedAs: ResolvedAs.paidBuyer,
            );
      await _pump(
        tester,
        core,
        location: AppRoute.inProgress,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Ahora no tienes ninguna disputa.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Cerradas'), 200);
      await tester.scrollUntilVisible(find.text('Pagaste al comprador'), 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(InProgressDisputeRow));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The detail: its result, no way to resolve it again.
      expect(find.byType(ResolutionCard), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Resultado'),
        200,
        scrollable: _info(),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: _info(), matching: find.text('Pagaste al comprador')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('after paying, the dispute moves to the closed ones', (
    tester,
  ) async {
    setSurface(tester);
    final core = _held();
    // The detail over In progress, as a tap on its row opens it.
    await _pump(tester, core);
    expect(find.byType(DisputeDetailScreen), findsOneWidget);
    await _open(tester, 'Pagar al comprador');
    await _scrollScreenTo(tester, _answer('Pagar al comprador'));
    await tester.tap(_answer('Pagar al comprador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a la disputa'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    // The detail is read only now, with its result.
    expect(find.byType(ResolutionCard), findsNothing);
    await tester.tap(find.byTooltip('Atrás'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(DisputeDetailScreen), findsNothing);
    await tester.scrollUntilVisible(find.text('Cerradas'), 200);
    await tester.scrollUntilVisible(find.text('Pagaste al comprador'), 200);
    expect(core.held, isEmpty);
    expect(core.permission, SolverPermission.readWrite);
  });

  testWidgets('a double tap opens one confirmation', (tester) async {
    setSurface(tester);
    await _pump(tester, _held(), brightness: Brightness.dark);
    final button = find.descendant(
      of: find.byType(ResolutionCard),
      matching: find.text('Pagar al comprador'),
    );
    await tester.scrollUntilVisible(button, 200, scrollable: _info());
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(ResolutionScreen), findsOneWidget);
  });
}
