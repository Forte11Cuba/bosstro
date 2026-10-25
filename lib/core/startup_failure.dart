import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosstro/core/app_theme.dart' show AppFonts;
import 'package:bosstro/core/project_links.dart';

/// Painted instead of the app when startup fails before it can be (from
/// ../app's `startup_failure.dart`).
///
/// Deliberately dependency-free: no localization, no app theme, no Rust, no
/// providers. Any of those can be the thing that failed, and a rescue surface
/// that needs what broke is a second blank page. So it is the one screen in
/// English only, with its colors written here (each pinned at 4.5:1 or more
/// by `startup_failure_contrast_test.dart`).
///
/// [step] names the startup step that threw, phrased to read inside the
/// sentence below ("It failed while loading the engine."). That name is the
/// whole point of this screen: "Bosstro won't open" is unactionable, "it
/// failed loading the engine" is a starting point — both for the solver
/// reporting it and for whoever reads the report.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key, required this.step, this.error});

  final String step;

  /// What was thrown, rendered as a second, selectable line.
  ///
  /// On Android and Linux there is no console for the solver hitting this to
  /// read, so the step name alone is all they could report. Selectable so it
  /// can be copied into that report, and capped so a runaway toString does not
  /// bury the sentence above it.
  final Object? error;

  static const int _maxErrorChars = 300;

  @visibleForTesting
  static const background = Color(0xFF1D212C);

  /// The title: 16.1:1 on [background].
  @visibleForTesting
  static const title = Colors.white;

  /// The sentence, the link text and the copy icons: 7.9:1 on [background].
  @visibleForTesting
  static const body = Color(0xFFB0B6C3);

  /// The cause and the footer, at 12 px, the smallest text here: 5.3:1 on
  /// [background].
  @visibleForTesting
  static const detail = Color(0xFF8C94A8);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Only the family name: the font is a bundled asset, and if it fails to
      // load Flutter falls back to the platform face instead of throwing.
      theme: ThemeData(fontFamily: AppFonts.ui),
      // On the web the initial route is the browser's URL, and Flutter's
      // default handling pushes one route per path segment: a deep URL would
      // stack copies of this screen. Returning the list yields exactly one.
      onGenerateInitialRoutes:
          (_) => [MaterialPageRoute<void>(builder: _buildBody)],
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: _buildBody),
    );
  }

  /// Both lines as one block, so a pasted report carries the step as well as
  /// the cause. The cause goes in whole: the clipboard has no layout to
  /// protect.
  String _report() {
    final cause = error == null ? '' : '\n${error!}';
    return 'Bosstro could not start: $step$cause';
  }

  static String _shortError(Object error) {
    // Counted in characters, not UTF-16 units: cutting inside an emoji leaves
    // half of it, which renders as a replacement glyph.
    final text = error.toString().characters;
    return text.length <= _maxErrorChars
        ? text.toString()
        : '${text.take(_maxErrorChars)}…';
  }

  Widget _buildBody(BuildContext context) {
    final cause =
        error == null
            ? null
            : SelectableText(
              _shortError(error!),
              textAlign: TextAlign.center,
              style: const TextStyle(color: detail, fontSize: 12),
            );
    final sentence = Text(
      'It failed while $step.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: body, fontSize: 15),
    );

    final main = Column(
      children: [
        const Text(
          'Bosstro could not start',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: title,
            fontSize: _titleSize,
            height: _titleLineHeight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12 + _titleSize * _titleLineHeight),
        if (cause != null) ...[sentence, const SizedBox(height: 8)],
        // The copy buttons sit next to what they copy — the cause when there
        // is one, otherwise the step — in one shared column. The link has its
        // own: typing a URL off a failure screen is where a report gets
        // abandoned.
        _copyTable(context, [
          ('Copy details', _report(), cause ?? sentence),
          (
            'Copy link',
            issuesUrl,
            Text(
              'Please report this at\n${issuesUrl.substring('https://'.length)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: body, fontSize: 13),
            ),
          ),
        ]),
      ],
    );

    // Clearing the app's data is deliberately not offered as a fix, and why
    // is spelled out: the secret key is kept only on this device.
    const footer = Padding(
      padding: EdgeInsets.only(top: 32),
      child: Text(
        'If you have no backup of your secret key, don\'t uninstall the app '
        'or clear its data: the key is kept only on this device, and without '
        'it you can no longer chat in or resolve the disputes you took.',
        textAlign: TextAlign.center,
        style: TextStyle(color: detail, fontSize: 12),
      ),
    );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            const vertical = 32.0;
            return SingleChildScrollView(
              // Scrollable so a long cause on a short screen moves out of the
              // way instead of overflowing. Side padding grows on wide
              // windows so lines stay at most 520 wide.
              padding: EdgeInsets.symmetric(
                horizontal: ((viewport.maxWidth - 520) / 2).clamp(
                  24.0,
                  double.infinity,
                ),
                vertical: vertical,
              ),
              child: ConstrainedBox(
                // At least the screen's height, so the warning sits at the
                // bottom as a footer when there is room.
                constraints: BoxConstraints(
                  minHeight: (viewport.maxHeight - 2 * vertical).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const SizedBox.shrink(), main, footer],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const _titleSize = 26.0;
  static const _titleLineHeight = 1.4;

  /// Each row's content with a copy button to its right: a three-column
  /// table whose side columns share the leftover width, so the contents are
  /// centred and the buttons line up. The middle column never takes more
  /// than the screen minus a tap target on each side, so a long text wraps
  /// instead of pushing the buttons off the screen.
  Widget _copyTable(
    BuildContext context,
    List<(String tooltip, String text, Widget content)> rows,
  ) {
    return LayoutBuilder(
      builder:
          (context, box) => Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FlexColumnWidth(),
              1: MinColumnWidth(
                const IntrinsicColumnWidth(),
                FixedColumnWidth(box.maxWidth - 2 * kMinInteractiveDimension),
              ),
              2: const FlexColumnWidth(),
            },
            children: [
              for (final (tooltip, text, content) in rows)
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: content,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _copyButton(context, tooltip, text),
                    ),
                  ],
                ),
            ],
          ),
    );
  }

  /// Awaited: on the web the write can be refused, and "Copied" over an empty
  /// clipboard sends someone off with nothing to paste.
  Widget _copyButton(BuildContext context, String tooltip, String text) {
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.copy, size: 18),
      color: body,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await Clipboard.setData(ClipboardData(text: text));
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Copied'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (_) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Could not copy. Select the text instead.'),
            ),
          );
        }
      },
    );
  }
}
