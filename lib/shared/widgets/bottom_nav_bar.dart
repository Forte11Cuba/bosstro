import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/l10n/app_localizations.dart';

const double _barHeight = 76;

/// One destination of the bottom bar.
typedef NavDestination = ({IconData icon, IconData activeIcon, String label});

/// Bottom navigation bar: Pending · In progress · Settings.
///
/// As in ../app: on the navigation surface under a hairline, each
/// destination a 20-dp icon over a 10-dp label, lime when active, the content
/// centred in a 76-dp bar above the system inset.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    this.badges = const [0, 0, 0],
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Unread count per destination; any above zero shows a dot.
  final List<int> badges;

  static List<NavDestination> destinations(AppLocalizations l10n) => [
    (
      icon: Icons.gavel_outlined,
      activeIcon: Icons.gavel,
      label: l10n.navPending,
    ),
    (
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum,
      label: l10n.navInProgress,
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: l10n.navSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final items = destinations(AppLocalizations.of(context));

    // Material (not a coloured box) so the items' ink splashes paint on it.
    return Material(
      color: pal.surfaceNav,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: pal.navBorder)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: SizedBox(
            height: _barHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final (index, item) in items.indexed)
                    Expanded(
                      child: _NavItem(
                        icon:
                            index == currentIndex ? item.activeIcon : item.icon,
                        label: item.label,
                        badgeCount: index < badges.length ? badges[index] : 0,
                        isActive: index == currentIndex,
                        palette: pal,
                        onTap: () => onSelect(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.isActive,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
  final bool isActive;
  final ShellPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? palette.limeText : palette.textTertiary;

    // A custom tappable (DS-A11Y-1): a button, selected when active.
    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: color),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: palette.notif,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
