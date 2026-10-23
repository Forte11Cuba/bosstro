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

      test('attachments: in the bubble, in the image frame, under it', () {
        final mine = flatten(pal.bubbleMineFill, shell.bg);
        final party = flatten(pal.bubblePartyFill, shell.bg);
        for (final (name, fill) in [('mine', mine), ('party', party)]) {
          // A file card's name, details and failure, on the bubble.
          expectAA('$name file name', pal.bubbleInk, fill);
          expectAA('$name problem', shell.textPrimary, fill);
          // A failure in place of an image, on the frame inside the bubble.
          expectAA(
            '$name frame problem',
            shell.textPrimary,
            flatten(shell.inset, fill),
          );
          expectAA(
            '$name frame retry',
            shell.limeText,
            flatten(shell.inset, fill),
          );
        }
        // An upload that failed: the words and its actions, on the page.
        expectAA('upload failed', shell.dangerText, shell.bg);
        expectAA('retry', shell.limeText, shell.bg);
        expectAA('discard', shell.textSecondary, shell.bg);
        // The viewer: a failure in place of the image, on the page.
        expectAA('viewer problem', shell.textPrimary, shell.bg);
        expectAA('viewer retry', shell.limeText, shell.bg);
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
