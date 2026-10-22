import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/features/solver_key/widgets/key_widgets.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/key_card.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/warning_note.dart';

/// Create new account (D9): a new nsec, shown once with a backup
/// confirmation, then the npub to send to the node operator.
///
/// The key is generated on entry and lives only on this screen until the
/// solver confirms the backup; leaving before that discards it. Confirming
/// loads and stores it (the safe replace), and the second step shows the
/// npub. The nsec is not kept on screen after that.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  /// The new key until it is stored; null once the npub step shows.
  NewSolverAccount? _account;
  late final String _npub;

  @override
  void initState() {
    super.initState();
    final account = ref.read(solverKeyServiceProvider).createAccount();
    _account = account;
    _npub = account.npub;
  }

  bool _savedBackup = false;
  bool _busy = false;
  String? _error;

  bool get _showingNpub => _account == null;

  Future<void> _continue() async {
    final account = _account;
    if (account == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(solverKeyProvider.notifier).logIn(account.nsec);
      if (!mounted) return;
      setState(() => _account = null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context).keySaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final account = _account;

    return PopScope(
      // The npub step is terminal: the key is stored, Welcome is behind.
      canPop: !_showingNpub && !_busy,
      child: Scaffold(
        backgroundColor: pal.bg,
        appBar: redesignAppBar(
          context,
          title: l10n.createTitle,
          onBack: _showingNpub || _busy ? null : () => context.pop(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            redesignSidePadding,
            8,
            redesignSidePadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                account == null
                    ? [
                      StepHeading(l10n.createNpubHeading),
                      const SizedBox(height: 8),
                      StepBody(l10n.createNpubBody),
                      const SizedBox(height: 18),
                      NpubShare(npub: _npub),
                    ]
                    : [
                      StepHeading(l10n.createKeyHeading),
                      const SizedBox(height: 8),
                      StepBody(l10n.createKeyBody),
                      const SizedBox(height: 18),
                      KeyCard(
                        label: l10n.secretKeyLabel,
                        value: account.nsec,
                        copyLabel: l10n.copySecretKey,
                        onCopy: () => copyId(context, account.nsec),
                      ),
                      const SizedBox(height: 12),
                      WarningNote(text: l10n.traderKeyWarning),
                      const SizedBox(height: 12),
                      _BackupConfirmation(
                        label: l10n.createBackupConfirm,
                        value: _savedBackup,
                        onChanged:
                            _busy
                                ? null
                                : (value) =>
                                    setState(() => _savedBackup = value),
                      ),
                    ],
          ),
        ),
        bottomNavigationBar: ActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error case final error?) ...[
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: pal.dangerText),
                ),
                const SizedBox(height: 10),
              ],
              _showingNpub
                  ? PrimaryButton(
                    label: l10n.createDone,
                    onPressed: () => context.go(AppRoute.pending),
                  )
                  : PrimaryButton(
                    label: l10n.createContinue,
                    busy: _busy,
                    onPressed: _savedBackup ? _continue : null,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "I saved my secret key somewhere safe": the whole row toggles the box,
/// at least 48 tall (DS-CMP-6), announced as a checkbox.
class _BackupConfirmation extends StatelessWidget {
  const _BackupConfirmation({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged:
                    onChanged == null ? null : (v) => onChanged(v ?? false),
                activeColor: pal.lime,
                checkColor: pal.onLime,
                side: BorderSide(color: pal.textSecondary, width: 2),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: pal.textBody),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
