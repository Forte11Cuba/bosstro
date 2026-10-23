import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/platform_capabilities.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/features/solver_key/widgets/key_widgets.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/input_source_action.dart';
import 'package:bosstro/shared/widgets/key_card.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/secret_field.dart';
import 'package:bosstro/shared/widgets/secure_window.dart';
import 'package:bosstro/shared/widgets/warning_note.dart';

/// Log in (D9): the solver's nsec, pasted, typed or scanned, then the npub
/// it stands for — "Is this the npub registered as a solver?" — before it is
/// loaded and stored (AGENTS.md → "Key handling", 7).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _secret = TextEditingController();

  /// The entered key's npub once it parsed: the confirmation step.
  String? _npub;
  String? _fieldError;
  String? _saveError;
  bool _busy = false;

  @override
  void dispose() {
    _secret.clear();
    _secret.dispose();
    super.dispose();
  }

  void _continue() {
    try {
      final npub = ref.read(solverKeyServiceProvider).previewNpub(_secret.text);
      setState(() {
        _npub = npub;
        _fieldError = null;
        _saveError = null;
      });
    } on SolverKeyError catch (error) {
      setState(
        () => _fieldError = keyErrorText(AppLocalizations.of(context), error),
      );
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _saveError = null;
    });
    try {
      await ref.read(solverKeyProvider.notifier).logIn(_secret.text);
      _secret.clear();
      if (mounted) {
        context.go(AppRoute.chooseNode);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveError = AppLocalizations.of(context).keySaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToKey() => setState(() {
    _npub = null;
    _saveError = null;
  });

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      setState(() => _fieldError = AppLocalizations.of(context).clipboardEmpty);
      return;
    }
    setState(() {
      _secret.text = text;
      _fieldError = null;
    });
  }

  Future<void> _scan() async {
    final value = await context.push<String>(AppRoute.scanQr);
    if (!mounted || value == null) return;
    setState(() {
      _secret.text = value;
      _fieldError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final npub = _npub;
    final confirming = npub != null;

    // Secure: the key typed in the field can be shown.
    return SecureWindow(
      child: PopScope(
        // Back from the confirmation returns to the key, not to Welcome.
        canPop: !confirming,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && confirming && !_busy) _backToKey();
        },
        child: Scaffold(
          backgroundColor: pal.bg,
          appBar: redesignAppBar(
            context,
            title: l10n.loginTitle,
            onBack:
                confirming ? (_busy ? null : _backToKey) : () => context.pop(),
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
                  confirming
                      ? _confirmation(pal, l10n, npub)
                      : _keyEntry(pal, l10n),
            ),
          ),
          bottomNavigationBar: ActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_saveError case final error?) ...[
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: pal.dangerText),
                  ),
                  const SizedBox(height: 10),
                ],
                PrimaryButton(
                  label:
                      confirming ? l10n.loginConfirmAnswer : l10n.loginContinue,
                  busy: _busy,
                  onPressed: confirming ? _confirm : _continue,
                ),
                if (confirming)
                  TextLink(
                    label: l10n.loginConfirmBack,
                    onPressed: _busy ? null : _backToKey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _keyEntry(ShellPalette pal, AppLocalizations l10n) => [
    StepHeading(l10n.loginHeading),
    const SizedBox(height: 8),
    StepBody(
      PlatformCapabilities.scanQr ? l10n.loginBody : l10n.loginBodyPaste,
    ),
    const SizedBox(height: 18),
    SecretField(
      controller: _secret,
      hint: l10n.secretKeyHint,
      showLabel: l10n.showSecretKey,
      hideLabel: l10n.hideSecretKey,
      errorText: _fieldError,
      onChanged: (_) {
        if (_fieldError != null) setState(() => _fieldError = null);
      },
      onSubmitted: (_) => _continue(),
    ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: InputSourceAction(
            icon: Icons.content_paste_rounded,
            label: l10n.pasteAction,
            onTap: _paste,
          ),
        ),
        if (PlatformCapabilities.scanQr) ...[
          const SizedBox(width: 10),
          Expanded(
            child: InputSourceAction(
              icon: Icons.qr_code_scanner_rounded,
              label: l10n.scanQrAction,
              accent: true,
              onTap: _scan,
            ),
          ),
        ],
      ],
    ),
    const SizedBox(height: 18),
    WarningNote(text: l10n.traderKeyWarning),
  ];

  List<Widget> _confirmation(
    ShellPalette pal,
    AppLocalizations l10n,
    String npub,
  ) => [
    StepHeading(l10n.loginConfirmHeading),
    const SizedBox(height: 8),
    StepBody(l10n.loginConfirmBody),
    const SizedBox(height: 18),
    KeyCard(
      label: l10n.npubLabel,
      value: npub,
      copyLabel: l10n.copyNpub,
      onCopy: () => copyId(context, npub),
    ),
  ];
}
