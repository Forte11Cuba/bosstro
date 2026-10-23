import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/mascot/header_mascot.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// How the app reaches the active node, as the tab app bar shows it: through
/// the relays (phase 2), so it reads the relay pool's state.
enum NodeLinkStatus {
  /// No node chosen yet.
  none,

  /// At least one relay is connected.
  online,

  /// None connected yet, one is trying.
  connecting,

  /// No relay answers.
  offline,
}

/// App bar of every tab root (DS-CMP-12): the Mostro mascot, then the active
/// node's name and its status, the same in every tab so the bar does not
/// change as the solver moves between them. The name of each screen lives in
/// the header below it.
///
/// The status is a word with a dot, never the dot alone (DS-COL-10).
class TabAppBar extends StatelessWidget {
  const TabAppBar({
    super.key,
    this.nodeName,
    this.status = NodeLinkStatus.none,
    this.statusLabel,
  });

  /// The active node's name; null before one is chosen.
  final String? nodeName;

  final NodeLinkStatus status;

  /// The status word ("Online"); null shows "No node selected".
  final String? statusLabel;

  /// Material's minimum touch target (DS-CMP-6).
  static const double _target = 48;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final top = math.max(28.0, MediaQuery.paddingOf(context).top + 8);
    final dot = switch (status) {
      NodeLinkStatus.online => pal.limeDot,
      NodeLinkStatus.connecting ||
      NodeLinkStatus.offline ||
      NodeLinkStatus.none => pal.neutralDot,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        redesignSidePadding,
        top,
        redesignSidePadding,
        12,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _target),
        child: Row(
          children: [
            Semantics(label: l10n.appName, child: const HeaderMascot()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nodeName ?? l10n.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: pal.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusLabel ?? l10n.noNodeSelected,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: pal.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The screen's title under the tab app bar: 19/600 (§3.2, screen headline).
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        4,
        redesignSidePadding,
        12,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: pal.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// `PENDING  2`: a group title and, when [count] is set, how many rows it
/// holds.
class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.title,
    this.count,
    required this.color,
  });

  final String title;
  final int? count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: color,
              ),
            ),
          ),
          if (count case final n?) ...[
            const SizedBox(width: 8),
            Text(
              '$n',
              style: TextStyle(
                fontFamily: AppFonts.figures,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
