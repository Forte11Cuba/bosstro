import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/shared/mascot/mostro_mascot.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// An empty list that explains itself (DS-CMP-14): the mascot, a title, the
/// reason, and the action that fixes it when there is one.
class ListEmptyState extends StatelessWidget {
  const ListEmptyState({
    super.key,
    required this.sticker,
    required this.title,
    required this.body,
    this.action,
    this.header,
  });

  /// The sticker's name, as in `assets/images/mascot/mostro-<name>.webp`.
  final String sticker;
  final String title;
  final String body;

  /// The fix, when there is one: a `PrimaryButton` or a link.
  final Widget? action;

  /// Something the screen says above the state, in the same scroll (a
  /// banner).
  final Widget? header;

  static const double _artHeight = 120;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: redesignSidePadding,
        vertical: 32,
      ),
      child: Column(
        children: [
          if (header case final top?) ...[top, const SizedBox(height: 24)],
          ExcludeSemantics(
            child: Image.asset(
              MostroMascot.stickerAsset(sticker),
              height: _artHeight,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: pal.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: pal.textSecondary,
            ),
          ),
          if (action case final fix?) ...[const SizedBox(height: 24), fix],
        ],
      ),
    );
  }
}
