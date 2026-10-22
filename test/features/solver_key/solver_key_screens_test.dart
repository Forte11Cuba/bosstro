import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/features/solver_key/screens/qr_scan_screen.dart';

import '../../support/screen_harness.dart';

/// A scanner that "sees" [value] on its first frame, or fails to start.
Override fakeScanner({String? value}) => qrScannerProvider.overrideWithValue(
  (onDetected, onError) => Builder(
    builder: (context) {
      if (value == null) return onError(context);
      WidgetsBinding.instance.addPostFrameCallback((_) => onDetected(value));
      return const SizedBox.expand();
    },
  ),
);

/// Puts [text] on the mocked clipboard.
void mockClipboard(WidgetTester tester, String? text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async =>
        call.method == 'Clipboard.getData'
            ? (text == null ? null : {'text': text})
            : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

void main() {
  group('DS-A11Y-4: 320 dp, 2× text, es, both themes, no overflow', () {
    for (final brightness in Brightness.values) {
      final theme = brightness.name;

      testWidgets('Welcome ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.welcome,
          brightness: brightness,
          overrides: fakeCoreOverrides(
            signedIn: false,
            storedKeyUnreadable: true,
          ),
        );
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Log in, both steps ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.login,
          brightness: brightness,
          overrides: fakeCoreOverrides(signedIn: false),
        );
        expect(tester.takeException(), isNull);

        await tester.enterText(find.byType(TextField), sampleNpub);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.enterText(find.byType(TextField), sampleNsec);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.text(sampleNpub), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Create new account, both steps ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.createAccount,
          brightness: brightness,
          overrides: fakeCoreOverrides(signedIn: false),
        );
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.byType(Checkbox));
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.text('Ir a las disputas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Scan QR, camera unavailable ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.scanQr,
          brightness: brightness,
          overrides: [...fakeCoreOverrides(signedIn: false), fakeScanner()],
        );
        expect(find.textContaining('La cámara no está disponible'), findsOne);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Backup ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.backup,
          brightness: brightness,
        );
        expect(find.text(sampleNsec), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Settings with the key group ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.settings,
          brightness: brightness,
        );
        expect(find.text('Cerrar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('routing', () {
    test('a solver without a key goes to Welcome', () {
      for (final location in AppRoute.tabs) {
        expect(AppRoute.redirect(location, signedIn: false), AppRoute.welcome);
      }
      expect(
        AppRoute.redirect(AppRoute.backup, signedIn: false),
        AppRoute.welcome,
      );
    });

    test('the onboarding screens stay open without a key', () {
      for (final location in [
        AppRoute.welcome,
        AppRoute.login,
        AppRoute.createAccount,
        AppRoute.scanQr,
      ]) {
        expect(AppRoute.redirect(location, signedIn: false), isNull);
      }
    });

    test('a logged-in solver is never moved by the redirect', () {
      // With push, go_router hands the redirect the base of the stack, so
      // moving a logged-in solver off Welcome would also pull Create new
      // account away before it shows the npub.
      for (final location in [
        AppRoute.welcome,
        AppRoute.login,
        AppRoute.createAccount,
        ...AppRoute.tabs,
      ]) {
        expect(AppRoute.redirect(location, signedIn: true), isNull);
      }
    });

    testWidgets('startup without a key opens Welcome', (tester) async {
      setSurface(tester, width: 400, height: 800);
      await pumpApp(
        tester,
        location: AppRoute.pending,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(signedIn: false),
      );
      expect(find.text('Create new account'), findsOneWidget);
      expect(find.text('Pending disputes'), findsNothing);
    });
  });

  group('Log in', () {
    late FakeKeyBackend backend;

    Future<void> openLogin(WidgetTester tester) async {
      setSurface(tester, width: 400, height: 800);
      backend = FakeKeyBackend();
      await pumpApp(
        tester,
        location: AppRoute.welcome,
        locale: const Locale('en'),
        textScale: 1,
        overrides: [
          ...fakeCoreOverrides(signedIn: false, backend: backend),
          fakeScanner(value: sampleNsec),
        ],
      );
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
    }

    Future<void> submit(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    testWidgets('names each refused key in words', (tester) async {
      await openLogin(tester);
      await submit(tester, '');
      expect(find.text('Enter your secret key.'), findsOneWidget);
      await submit(tester, sampleNpub);
      expect(
        find.textContaining('That is a public key (npub)'),
        findsOneWidget,
      );
      await submit(tester, 'hello');
      expect(find.textContaining('This is not a valid secret key'), findsOne);
      expect(backend.store.entries, isEmpty);
    });

    testWidgets('confirms the npub before anything is loaded or stored', (
      tester,
    ) async {
      await openLogin(tester);
      await submit(tester, sampleNsec);
      expect(find.text('Is this the npub registered as a solver?'), findsOne);
      expect(find.text(sampleNpub), findsOneWidget);
      expect(backend.core.loaded, isNull);
      expect(backend.store.entries, isEmpty);

      await tester.tap(find.text('Yes, log in'));
      await tester.pumpAndSettle();
      expect(find.text('Pending disputes'), findsOneWidget);
      expect(backend.log, ['unload', 'load:$sampleNsec', 'write']);
      expect(backend.store.entries[SolverKeyService.storageKey], sampleNsec);
    });

    testWidgets('"No, use another key" returns to the key, kept', (
      tester,
    ) async {
      await openLogin(tester);
      await submit(tester, sampleNsec);
      await tester.tap(find.text('No, use another key'));
      await tester.pumpAndSettle();
      expect(find.text('Your solver secret key'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        sampleNsec,
      );
    });

    testWidgets('a refused save says so and stays', (tester) async {
      await openLogin(tester);
      backend.store.failWrite = true;
      await submit(tester, sampleNsec);
      await tester.tap(find.text('Yes, log in'));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(backend.core.loaded, isNull);
    });

    testWidgets('Paste fills the field from the clipboard', (tester) async {
      await openLogin(tester);
      mockClipboard(tester, '  $sampleNsec ');
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        sampleNsec,
      );
    });

    testWidgets('Paste on an empty clipboard says so', (tester) async {
      await openLogin(tester);
      mockClipboard(tester, null);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(find.text('The clipboard is empty.'), findsOneWidget);
    });

    testWidgets('Scan QR fills the field with what it read', (tester) async {
      await openLogin(tester);
      await tester.tap(find.text('Scan QR'));
      await tester.pumpAndSettle();
      expect(find.text('Your solver secret key'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        sampleNsec,
      );
    });

    testWidgets('the key field is hidden until shown', (tester) async {
      await openLogin(tester);
      TextField field() => tester.widget<TextField>(find.byType(TextField));
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show key'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });
  });

  group('Create new account', () {
    testWidgets('backup first, then the key is stored and the npub shown', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 900);
      final backend = FakeKeyBackend();
      await pumpApp(
        tester,
        location: AppRoute.welcome,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(signedIn: false, backend: backend),
      );
      await tester.tap(find.text('Create new account'));
      await tester.pumpAndSettle();

      expect(find.text(sampleNsec), findsOneWidget);
      expect(find.textContaining('Never use the key you trade with'), findsOne);
      final continueButton = find.widgetWithText(FilledButton, 'Continue');
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      expect(backend.store.entries, isEmpty);

      await tester.tap(find.text('I saved my secret key somewhere safe'));
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(backend.store.entries[SolverKeyService.storageKey], sampleNsec);
      expect(find.text('Your npub'), findsOneWidget);
      expect(find.text(sampleNpub), findsOneWidget);
      expect(find.bySemanticsLabel('QR code of your npub'), findsOneWidget);
      // The nsec is not on screen any more.
      expect(find.text(sampleNsec), findsNothing);

      await tester.tap(find.text('Go to disputes'));
      await tester.pumpAndSettle();
      expect(find.text('Pending disputes'), findsOneWidget);
    });
  });

  group('Settings', () {
    late FakeKeyBackend backend;

    Future<void> openSettings(WidgetTester tester) async {
      setSurface(tester, width: 400, height: 800);
      backend = FakeKeyBackend(
        stored: {SolverKeyService.storageKey: sampleNsec},
        loaded: true,
      );
      await pumpApp(
        tester,
        location: AppRoute.settings,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(backend: backend),
      );
    }

    testWidgets('the secret key only behind a warning', (tester) async {
      await openSettings(tester);
      await tester.tap(find.text('Back up secret key'));
      await tester.pumpAndSettle();
      expect(find.text('Show your secret key?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text(sampleNsec), findsNothing);

      await tester.tap(find.text('Back up secret key'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show secret key'));
      await tester.pumpAndSettle();
      expect(find.text('Secret key backup'), findsOneWidget);
      expect(find.text(sampleNsec), findsOneWidget);
    });

    testWidgets('the npub opens with its QR', (tester) async {
      await openSettings(tester);
      await tester.tap(find.text('Your npub'));
      await tester.pumpAndSettle();
      expect(find.text(sampleNpub), findsOneWidget);
      expect(find.bySemanticsLabel('QR code of your npub'), findsOneWidget);
    });

    testWidgets('log out asks first, then removes the key', (tester) async {
      await openSettings(tester);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.store.entries, isNotEmpty);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out').last);
      await tester.pumpAndSettle();
      expect(backend.store.entries, isEmpty);
      expect(backend.core.loaded, isNull);
      expect(find.text('Create new account'), findsOneWidget);
    });

    testWidgets('a refused log out says so and keeps the key', (tester) async {
      await openSettings(tester);
      backend.store.failDelete = true;
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out').last);
      await tester.pumpAndSettle();
      expect(find.text('Could not log out. Try again.'), findsOneWidget);
      expect(backend.core.loaded, sampleNsec);
    });
  });
}
