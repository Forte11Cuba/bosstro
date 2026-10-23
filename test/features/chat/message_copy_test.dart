import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/chat_bubble.dart';
import 'package:bosstro/features/chat/widgets/message_copy.dart';
import 'package:bosstro/features/observer/widgets/observed_bubble.dart';
import 'package:bosstro/l10n/app_localizations.dart';

import '../../support/screen_harness.dart';

const _id = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';
final _now = DateTime.fromMillisecondsSinceEpoch(1700005000 * 1000);

/// A chat key as ../app discloses it (never a real one).
const _key =
    'Shared key: 0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0';

/// What reached the plain clipboard.
List<String> _plainClipboard(WidgetTester tester) {
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

Future<FakeDeviceSecurity> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  double textScale = 1,
}) async {
  final device = FakeDeviceSecurity();
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakeCoreOverrides(device: device),
      child: MaterialApp(
        theme:
            brightness == Brightness.dark
                ? buildDarkTheme()
                : buildLightTheme(),
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return device;
}

Widget _bubble(ChatMessageView message) => ChatBubble(
  chat: (disputeId: _id, party: ChatParty.buyer),
  message: message,
  now: _now,
);

void main() {
  test('a chat key is told apart from a message that mentions one', () {
    expect(holdsChatKey(_key), isTrue);
    expect(holdsChatKey('  $_key\n'), isTrue);
    expect(holdsChatKey('Te paso la clave en un rato'), isFalse);
    expect(holdsChatKey('Shared key: 1234'), isFalse);
  });

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('a long press copies the message whole, $theme', (
      tester,
    ) async {
      final copied = _plainClipboard(tester);
      await _pump(
        tester,
        _bubble(sampleMessage(id: 'm1', content: 'Referencia: 77310-ABC')),
        brightness: brightness,
        textScale: 2,
      );
      await tester.longPress(find.text('Referencia: 77310-ABC'));
      await tester.pump();
      expect(copied, ['Referencia: 77310-ABC']);
      expect(find.text('Copiado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a chat key is copied as a secret, never in plain text', (
    tester,
  ) async {
    final copied = _plainClipboard(tester);
    final device = await _pump(
      tester,
      _bubble(sampleMessage(id: 'k', content: _key)),
    );
    await tester.longPress(find.text(_key));
    await tester.pump();
    expect(copied, isEmpty);
    expect(device.calls, contains('copy:$_key'));
    expect(
      find.text(
        'Clave del chat copiada. Se borra del portapapeles en 60 segundos.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('off Android a chat key is not offered for copying', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final copied = _plainClipboard(tester);
    final device = await _pump(
      tester,
      _bubble(sampleMessage(id: 'k', content: _key)),
    );
    await tester.longPress(find.text(_key));
    await tester.pump();
    expect(copied, isEmpty);
    expect(device.calls.where((c) => c.startsWith('copy:')), isEmpty);
    // Normal messages still copy there.
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a file copies its name, not its content', (tester) async {
    final copied = _plainClipboard(tester);
    await _pump(
      tester,
      _bubble(
        sampleMessage(
          id: 'f',
          content: '{"type":"file_encrypted"}',
          attachment: const ChatAttachment(
            kind: ChatAttachmentKind.file,
            fileName: 'comprobante.pdf',
            mimeType: 'application/pdf',
            size: 120000,
          ),
        ),
      ),
    );
    await tester.longPress(find.text('comprobante.pdf'));
    await tester.pump();
    expect(copied, ['comprobante.pdf']);
  });

  testWidgets('the chat between the parties copies too', (tester) async {
    final copied = _plainClipboard(tester);
    await _pump(
      tester,
      ObservedBubble(
        message: observedMessage(
          id: 'o1',
          sender: ChatParty.seller,
          content: 'En mi banco no aparece nada todavía.',
        ),
        now: _now,
      ),
    );
    await tester.longPress(find.text('En mi banco no aparece nada todavía.'));
    await tester.pump();
    expect(copied, ['En mi banco no aparece nada todavía.']);
  });

  testWidgets('screen readers are told a long press copies', (tester) async {
    final handle = tester.ensureSemantics();
    _plainClipboard(tester);
    await _pump(tester, _bubble(sampleMessage(id: 'm1', content: 'Hola')));
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('Hola'))),
      isSemantics(
        hasLongPressAction: true,
        onLongPressHint: 'Copiar el mensaje',
      ),
    );
    handle.dispose();
  });
}
