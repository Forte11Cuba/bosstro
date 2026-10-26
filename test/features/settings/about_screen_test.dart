import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/project_links.dart';
import 'package:bosstro/features/settings/screens/about_screen.dart';
import 'package:bosstro/shared/providers/core_providers.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';

import '../../support/screen_harness.dart';

const _commit = '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b';

/// What the source code row handed to the browser, and its answer.
class _Browser {
  _Browser({this.takes = true});

  final bool takes;
  final opened = <Uri>[];

  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return takes;
  }
}

Future<void> _about(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  String commit = _commit,
  _Browser? browser,
}) async {
  setSurface(tester, width: 400, height: 900);
  await pumpApp(
    tester,
    location: AppRoute.about,
    locale: locale,
    textScale: 1,
    overrides: [
      ...fakeCoreOverrides(),
      appCommitProvider.overrideWithValue(commit),
      openExternalUrlProvider.overrideWithValue((browser ?? _Browser()).open),
    ],
  );
}

/// Records what reaches the system clipboard.
List<String> _recordClipboard(WidgetTester tester) {
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
  return copied;
}

void main() {
  /// DS-A11Y-4: the new screen at 2× text, 320 dp wide, in Spanish, in both
  /// themes, without overflow — and the licence dialog it opens.
  group('fits at 320 dp, 2× text, es', () {
    for (final brightness in Brightness.values) {
      testWidgets('About and the licence dialog (${brightness.name})', (
        tester,
      ) async {
        // Arrange
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.about,
          brightness: brightness,
          overrides: [
            ...fakeCoreOverrides(),
            appCommitProvider.overrideWithValue(_commit),
          ],
        );

        // Act
        await tester.ensureVisible(find.text('Licencia'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Licencia'));
        await tester.pumpAndSettle();

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('Acerca de'), findsOneWidget);
        expect(find.byType(MostroDialog), findsOneWidget);
      });
    }
  });

  testWidgets('the version as MostroP2P/app writes it, and the commit hash', (
    tester,
  ) async {
    // Act
    await _about(tester);

    // Assert
    expect(find.text('v$fakeAppVersion'), findsOneWidget);
    expect(find.text('Commit Hash'), findsOneWidget);
    expect(find.text('1a2b3c4'), findsOneWidget);
  });

  testWidgets('a build that named no commit has no commit row', (tester) async {
    // Act
    await _about(tester, commit: '');

    // Assert
    expect(find.text('v$fakeAppVersion'), findsOneWidget);
    expect(find.text('Commit Hash'), findsNothing);
  });

  testWidgets('the licence notice stays in English in every language', (
    tester,
  ) async {
    // Arrange — a translated licence has no legal force; only the title is
    // translated.
    await _about(tester, locale: const Locale('es'));

    // Act
    await tester.tap(find.text('Licencia'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('Licencia Pública General Affero de GNU v3'),
      findsOneWidget,
    );
    expect(
      find.textContaining('it under the terms of the GNU Affero General'),
      findsOneWidget,
    );
    expect(find.textContaining('either version 3 of the License'), findsOne);
  });

  testWidgets('Source code opens the repository in the browser', (
    tester,
  ) async {
    // Arrange — the AGPL section 13 offer of the source.
    final browser = _Browser();
    await _about(tester, browser: browser);
    expect(find.text('MostroP2P/bosstro'), findsOneWidget);

    // Act
    await tester.tap(find.text('Source code'));
    await tester.pumpAndSettle();

    // Assert
    expect(browser.opened, [Uri.parse('https://github.com/MostroP2P/bosstro')]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('with no browser to take it, the link is offered to copy', (
    tester,
  ) async {
    // Arrange
    final copied = _recordClipboard(tester);
    await _about(tester, browser: _Browser(takes: false));

    // Act
    await tester.tap(find.text('Source code'));
    await tester.pumpAndSettle();
    expect(find.text(sourceCodeUrl), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    // Assert
    expect(copied, [sourceCodeUrl]);
    expect(find.text('Link copied to clipboard'), findsOne);
  });

  group('shortHash', () {
    test('cuts a hash to seven characters, as MostroP2P/app', () {
      expect(shortHash(_commit), '1a2b3c4');
    });

    test('keeps a hash that is already short', () {
      expect(shortHash('abc'), 'abc');
    });
  });
}
