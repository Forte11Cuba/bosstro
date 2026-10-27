import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/l10n/app_localizations_en.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/status_chip.dart';

import '../../support/screen_harness.dart';

/// Opened 2023-11-14 22:13:20 UTC; the tests' clock is two hours later.
const _opened = 1700000000;
final _now = DateTime.fromMillisecondsSinceEpoch((_opened + 7200) * 1000);

const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';
const _b = '1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9';

Future<void> _pumpPending(
  WidgetTester tester,
  FakeDisputesCore disputes, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  bool settle = true,
}) => withClock(
  Clock.fixed(_now),
  () => pumpApp(
    tester,
    location: AppRoute.pending,
    locale: locale,
    brightness: brightness,
    textScale: textScale,
    settle: settle,
    overrides: fakeCoreOverrides(disputes: disputes),
  ),
);

/// Lets the provider's coalescing timer run, then the frame settle.
Future<void> _afterUpdates(WidgetTester tester) async {
  await tester.pump(PendingDisputesNotifier.coalesce);
  await tester.pumpAndSettle();
}

void main() {
  // The id closes every dispute card; its 48-dp copy target must not leave
  // the card twice as much room under it as over the chip.
  final cards = <String, Widget>{
    'Pending': PendingDisputeRow(dispute: sampleDispute(id: _a), now: _now),
    'In progress': InProgressDisputeRow(
      dispute: sampleTaken(id: _a),
      now: _now,
      onTap: () {},
    ),
    'Closed': ClosedDisputeRow(
      dispute: sampleTaken(id: _a, status: DisputeStatus.settled),
      now: _now,
      onTap: () {},
    ),
  };
  for (final MapEntry(key: name, value: row) in cards.entries) {
    testWidgets('a $name card has even room over its chip and under its id', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 800);
      // In a list, as the tabs show it: as tall as its lines.
      await pumpWidgetAlone(
        tester,
        ListView(children: [row]),
        locale: const Locale('en'),
      );
      final card = tester.getRect(find.byType(SurfaceCard));
      final chip = tester.getRect(find.byType(StatusChip));
      final id = tester.getRect(find.byIcon(Icons.copy_rounded));
      final over = chip.top - card.top;
      final under = card.bottom - id.bottom;
      expect((under - over).abs(), lessThanOrEqualTo(4), reason: '$under');
    });
  }

  // DS-A11Y-4 with rows on screen: 320 dp, 2× text, Spanish, both themes.
  for (final brightness in Brightness.values) {
    testWidgets('the list fits at 320 dp, 2× text, es, ${brightness.name}', (
      tester,
    ) async {
      setSurface(tester);
      final core = FakeDisputesCore(
        disputes: [
          sampleDispute(id: _a, initiator: DisputeInitiator.buyer),
          sampleDispute(
            id: _b,
            initiator: DisputeInitiator.unknown,
            openedAt: null,
          ),
        ],
      );
      await _pumpPending(
        tester,
        core,
        locale: const Locale('es'),
        brightness: brightness,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('ESPERANDO SOLVER'), findsWidgets);
      expect(find.text('Abierta por el comprador'), findsOneWidget);
    });

    testWidgets(
      'the empty state fits at 320 dp, 2× text, es, ${brightness.name}',
      (tester) async {
        setSurface(tester);
        await _pumpPending(
          tester,
          FakeDisputesCore(),
          locale: const Locale('es'),
          brightness: brightness,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('No hay disputas esperando'), findsOneWidget);
      },
    );
  }

  testWidgets('a row shows the status in words, the opener, the age and the '
      'short id', (tester) async {
    setSurface(tester, width: 400, height: 800);
    await _pumpPending(tester, FakeDisputesCore(disputes: [sampleDispute()]));

    // Color is never the only signal (DS-COL-10): the chip says it, in lime.
    expect(find.text('WAITING FOR A SOLVER'), findsOneWidget);
    expect(
      tester.widget<StatusChip>(find.byType(StatusChip)).kind,
      StatusChipKind.turn,
    );
    expect(find.text('Opened by the seller'), findsOneWidget);
    expect(find.text('Opened 2 hours ago'), findsOneWidget);
    expect(find.text('8a0c1e64…4b2c'), findsOneWidget);
    // No amount: the public event carries none.
    expect(find.textContaining('sats'), findsNothing);
  });

  testWidgets('tapping the id copies the whole id (DS-CMP-22)', (tester) async {
    setSurface(tester, width: 400, height: 800);
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpPending(tester, FakeDisputesCore(disputes: [sampleDispute()]));

    await tester.tap(find.text('8a0c1e64…4b2c'));
    await tester.pump();

    expect(copied, [_a]);
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('the id is a 48-dp button for screen readers', (tester) async {
    setSurface(tester, width: 400, height: 800);
    final semantics = tester.ensureSemantics();
    await _pumpPending(tester, FakeDisputesCore(disputes: [sampleDispute()]));

    final id = find.bySemanticsLabel('Dispute 8a0c1e64…4b2c');
    expect(id, findsOneWidget);
    expect(tester.getSize(id).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(id),
      matchesSemantics(
        label: 'Dispute 8a0c1e64…4b2c',
        hint: 'Copy ID',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('before the relays answer, an empty list is a skeleton, never '
      '"no disputes" (DS-CMP-13)', (tester) async {
    setSurface(tester, width: 400, height: 800);
    final core = FakeDisputesCore(synced: false);
    await _pumpPending(tester, core, settle: false);
    await tester.pump();

    expect(find.byType(ListSkeleton), findsOneWidget);
    expect(find.bySemanticsLabel('Loading disputes'), findsOneWidget);
    expect(find.text('No disputes waiting'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // The node answers with nothing pending: now it is "none".
    core.synced = true;
    core.push();
    await tester.pump(PendingDisputesNotifier.coalesce);
    await tester.pump();
    expect(find.text('No disputes waiting'), findsOneWidget);
    expect(find.textContaining('waiting for a solver'), findsOneWidget);
  });

  testWidgets('a sync announced before the list listened still ends the '
      'skeleton', (tester) async {
    setSurface(tester, width: 400, height: 800);
    final core = FakeDisputesCore(synced: false);
    await _pumpPending(tester, core, settle: false);
    await tester.pump();
    expect(find.byType(ListSkeleton), findsOneWidget);

    // Synced with no update pushed: the announcement was lost.
    core.synced = true;
    await tester.pump(PendingDisputesNotifier.unsyncedRecheck);
    await tester.pump();
    expect(find.text('No disputes waiting'), findsOneWidget);
  });

  testWidgets('stored disputes show while the relays have not answered yet', (
    tester,
  ) async {
    setSurface(tester, width: 400, height: 800);
    await _pumpPending(
      tester,
      FakeDisputesCore(synced: false, disputes: [sampleDispute()]),
    );
    expect(find.byType(ListSkeleton), findsNothing);
    expect(find.byType(PendingDisputeRow), findsOneWidget);
  });

  testWidgets('the list follows the feed: a new dispute appears, one taken or '
      'closed leaves', (tester) async {
    setSurface(tester, width: 400, height: 800);
    final core = FakeDisputesCore(disputes: [sampleDispute(id: _a)]);
    await _pumpPending(tester, core);
    expect(find.byType(PendingDisputeRow), findsOneWidget);

    final added = sampleDispute(id: _b);
    core.disputes = [...core.disputes, added];
    core.push(dispute: added);
    await _afterUpdates(tester);
    expect(find.byType(PendingDisputeRow), findsNWidgets(2));

    final taken = sampleDispute(id: _a, status: DisputeStatus.inProgress);
    core.disputes = [taken, added];
    core.push(dispute: taken);
    await _afterUpdates(tester);
    expect(find.byType(PendingDisputeRow), findsOneWidget);
    expect(find.text('1f2e3d4c…e0f9'), findsOneWidget);
  });

  testWidgets('a dispute that expires leaves on the next minute tick, with '
      'no update', (tester) async {
    setSurface(tester, width: 400, height: 800);
    var now = _now;
    final core = FakeDisputesCore(
      disputes: [sampleDispute(id: _a), sampleDispute(id: _b)],
    )..expiresAt[_a] = _now.add(const Duration(seconds: 30));
    await withClock(
      Clock(() => now),
      () => pumpApp(
        tester,
        location: AppRoute.pending,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(disputes: core),
      ),
    );
    expect(find.byType(PendingDisputeRow), findsNWidgets(2));
    expect(find.text('Opened 2 hours ago'), findsNWidgets(2));

    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(find.byType(PendingDisputeRow), findsOneWidget);
    expect(find.text('1f2e3d4c…e0f9'), findsOneWidget);
    // The age moved with the same tick.
    expect(find.text('Opened 2 hours ago'), findsOneWidget);
  });

  testWidgets('a burst of updates is read once, and another node\'s are '
      'ignored', (tester) async {
    setSurface(tester, width: 400, height: 800);
    final core = FakeDisputesCore(disputes: [sampleDispute()]);
    await _pumpPending(tester, core);
    final before = core.reads;

    for (var i = 0; i < 20; i++) {
      core.push(dispute: sampleDispute());
    }
    await _afterUpdates(tester);
    expect(core.reads, before + 1);

    core.push(dispute: sampleDispute(node: cubaPubkey), forNode: cubaPubkey);
    await _afterUpdates(tester);
    expect(core.reads, before + 1);
  });

  testWidgets('a list that cannot be read says so', (tester) async {
    setSurface(tester, width: 400, height: 800);
    await _pumpPending(tester, _BrokenDisputesCore());
    expect(find.text('Disputes could not be read'), findsOneWidget);
  });

  testWidgets('without a node, Pending asks for one and reads no dispute', (
    tester,
  ) async {
    setSurface(tester, width: 400, height: 800);
    final core = FakeDisputesCore(node: null);
    await withClock(
      Clock.fixed(_now),
      () => pumpApp(
        tester,
        location: AppRoute.pending,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(nodes: FakeNodesCore(), disputes: core),
      ),
    );
    expect(find.text('Choose your node first'), findsOneWidget);
    expect(core.reads, 0);
  });

  group('labels', () {
    final l10n = AppLocalizationsEn();

    test('the age reads in minutes, hours, then days', () {
      String age(Duration ago) => disputeAgeLabel(
        l10n,
        _opened,
        DateTime.fromMillisecondsSinceEpoch(_opened * 1000).add(ago),
      );
      expect(age(const Duration(seconds: 59)), 'Opened just now');
      expect(age(const Duration(minutes: 1)), 'Opened 1 minute ago');
      expect(age(const Duration(minutes: 59)), 'Opened 59 minutes ago');
      expect(age(const Duration(hours: 1)), 'Opened 1 hour ago');
      expect(
        age(const Duration(hours: 23, minutes: 59)),
        'Opened 23 hours ago',
      );
      expect(age(const Duration(days: 3, hours: 5)), 'Opened 3 days ago');
      // A clock behind the node's is not a negative age.
      expect(age(const Duration(minutes: -5)), 'Opened just now');
      expect(disputeAgeLabel(l10n, null, _now), 'Open time not known');
    });

    test('every status has a word, and only a waiting dispute is lime', () {
      for (final status in DisputeStatus.values) {
        expect(disputeStatusLabel(l10n, status), isNotEmpty);
        expect(
          statusChipKindOf(status),
          status == DisputeStatus.initiated
              ? StatusChipKind.turn
              : StatusChipKind.neutral,
        );
      }
    });

    test('the opener is named with the glossary, never raw', () {
      expect(
        disputeInitiatorLabel(l10n, DisputeInitiator.buyer),
        'Opened by the buyer',
      );
      expect(
        disputeInitiatorLabel(l10n, DisputeInitiator.seller),
        'Opened by the seller',
      );
      expect(
        disputeInitiatorLabel(l10n, DisputeInitiator.unknown),
        'Opener not known',
      );
    });
  });
}

class _BrokenDisputesCore extends FakeDisputesCore {
  @override
  Future<PendingDisputes?> pending() async => throw Exception('db closed');
}
