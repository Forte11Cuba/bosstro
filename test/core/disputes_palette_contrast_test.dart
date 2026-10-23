import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/core/shell_palette.dart';

import '../support/contrast.dart';

void main() {
  for (final (mode, pal, shell) in [
    ('dark', DisputesPalette.dark, ShellPalette.dark),
    ('light', DisputesPalette.light, ShellPalette.light),
  ]) {
    group('DisputesPalette.$mode', () {
      test('group headers sit on the page', () {
        expectAA('group header', pal.groupHeader, shell.bg);
      });

      test('the detail segments over their track on the page', () {
        final track = flatten(pal.segmentTrack, shell.bg);
        expectAA('inactive', pal.segmentInk, track);
        expectAA(
          'active',
          pal.segmentActiveInk,
          flatten(pal.segmentActiveFill, track),
        );
      });

      test('chat bubbles: text, time, sender and failure', () {
        final mine = flatten(pal.bubbleMineFill, shell.bg);
        final party = flatten(pal.bubblePartyFill, shell.bg);
        for (final (name, fill) in [('mine', mine), ('party', party)]) {
          expectAA('$name text', pal.bubbleInk, fill);
          expectAA('$name meta', pal.bubbleMeta, fill);
        }
        expectAA('you', pal.bubbleYouLabel, mine);
        // "Not sent" sits under the bubble, on the page.
        expectAA('not sent', shell.dangerText, shell.bg);
      });

      test('the message field', () {
        final fill = flatten(pal.composerFill, shell.bg);
        expectAA('text', pal.bubbleInk, fill);
        expectAA('placeholder', pal.composerPlaceholder, fill);
      });

      for (final (surface, bg) in [
        ('page', shell.bg),
        ('card', shell.surface),
      ]) {
        test('status chips over their own fill on the $surface', () {
          expectAA('turn', pal.chipTurnInk, flatten(pal.chipTurnBg, bg));
          expectAA(
            'neutral',
            pal.chipNeutralInk,
            flatten(pal.chipNeutralBg, bg),
          );
        });
      }
    });
  }
}
