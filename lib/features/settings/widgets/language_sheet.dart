import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/settings/models/languages.dart';
import 'package:bosstro/features/settings/providers/language_provider.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';

/// Open the language sheet: the system's language, then every language the
/// app ships, by its own name.
Future<void> showLanguageSheet(BuildContext context) => showMostroSheet<void>(
  context: context,
  builder: (_) => const LanguageSheet(),
);

/// The choice of the app's language, as ../app's language selector, with
/// "System language" first: the default, and the way back to it.
class LanguageSheet extends ConsumerWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(languageProvider);
    final system = systemLanguage(
      WidgetsBinding.instance.platformDispatcher.locales,
    );

    void choose(String? code) {
      final notifier = ref.read(languageProvider.notifier);
      Navigator.of(context).pop();
      if (code == current) return;
      // After the sheet is gone: a new locale rebuilds the whole app, and
      // ../app found that doing it under an open sheet trips Flutter's
      // inherited-widget assertions.
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => notifier.choose(code),
      );
    }

    return MostroSheet(
      title: l10n.languageSheetTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LanguageOption(
            label: l10n.languageSystem,
            detail: l10n.languageSystemDetail(languageName(system)),
            selected: current == null,
            onTap: () => choose(null),
          ),
          for (final code in appLanguages)
            _LanguageOption(
              label: languageName(code),
              selected: current == code,
              onTap: () => choose(code),
              // Each name in its own language, so a reader of it finds it.
              locale: Locale(code),
            ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.locale,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: detail == null ? label : '$label. $detail',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? pal.limeIcon : pal.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        locale: locale,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: pal.textPrimary,
                        ),
                      ),
                      if (detail case final detail?) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: pal.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
