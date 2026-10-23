import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/observer/providers/observer_providers.dart';
import 'package:bosstro/features/observer/services/observer_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/input_source_action.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/secret_field.dart';
import 'package:bosstro/shared/widgets/secure_window.dart';

/// The navigator a paste dialog is open on, if any: a second tap opens
/// nothing (as the take dialog).
NavigatorState? _openOn;

/// Ask for a chat key for [disputeId] and check it against the relays.
/// Resolves to true once the key read the chat (it is then held, in memory),
/// false when the solver closed the dialog.
Future<bool> openPasteKeyDialog(
  BuildContext context, {
  required String disputeId,
}) async {
  if (_openOn?.mounted ?? false) return false;
  final navigator = Navigator.of(context, rootNavigator: true);
  _openOn = navigator;
  try {
    final read = await showMostroDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PasteKeyDialog(disputeId: disputeId),
    );
    return read ?? false;
  } finally {
    if (identical(_openOn, navigator)) _openOn = null;
  }
}

/// The dialog: one field that never shows the key back (no toggle, so it is
/// never selectable either), Paste from the clipboard, and the answer that
/// checks it. The window is secure while it is open (FLAG_SECURE on
/// Android): the key is a secret of the parties.
///
/// The key crosses to Rust as bytes, wiped right after the call; the field
/// is cleared too. The Strings it came from (the field, the clipboard) are
/// immutable in Dart (the accepted limit of the solver key, AGENTS.md).
class PasteKeyDialog extends ConsumerStatefulWidget {
  const PasteKeyDialog({super.key, required this.disputeId});

  final String disputeId;

  @override
  ConsumerState<PasteKeyDialog> createState() => _PasteKeyDialogState();
}

class _PasteKeyDialogState extends ConsumerState<PasteKeyDialog> {
  final _key = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _key.clear();
    _key.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (text == null || text.isEmpty) {
        _error = l10n.clipboardEmpty;
      } else {
        _key.text = text;
        _error = null;
      }
    });
  }

  Future<void> _check() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    if (_key.text.trim().isEmpty) {
      setState(() => _error = l10n.observerInvalidKey);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final bytes = Uint8List.fromList(utf8.encode(_key.text));
    final ObserverError? refused;
    try {
      refused = await ref
          .read(observedChatProvider(widget.disputeId).notifier)
          .paste(bytes);
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
    if (!mounted) return;
    if (refused == null) {
      _key.clear();
      Navigator.of(context).pop(true);
      return;
    }
    final since =
        ref
            .read(observedChatProvider(widget.disputeId))
            .valueOrNull
            ?.chat
            .since
            .toInt();
    setState(() {
      _busy = false;
      _error = pasteErrorText(l10n, refused!, since: since, locale: locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Keeps the observed chat alive while its key is checked.
    ref.watch(observedChatProvider(widget.disputeId));
    return SecureWindow(
      // No way out while the relays answer: the result would be lost.
      child: PopScope(
        canPop: !_busy,
        child: MostroDialog(
          title: l10n.observerPasteTitle,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.observerPasteBody,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: ShellPalette.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              SecretField(
                controller: _key,
                hint: l10n.observerPasteHint,
                showLabel: l10n.showSecretKey,
                hideLabel: l10n.hideSecretKey,
                canReveal: false,
                errorText: _error,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _check(),
              ),
              const SizedBox(height: 12),
              InputSourceAction(
                icon: Icons.content_paste_rounded,
                label: l10n.pasteAction,
                onTap: _busy ? null : _paste,
              ),
            ],
          ),
          secondary: ModalAction(
            label: l10n.cancel,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
          primary: ModalAction(
            label: l10n.observerPasteConfirm,
            busy: _busy,
            onPressed: _check,
          ),
        ),
      ),
    );
  }
}

/// Why a pasted key was refused, under the field. [since] (Unix seconds) is
/// where the read started.
String pasteErrorText(
  AppLocalizations l10n,
  ObserverError error, {
  required int? since,
  required String locale,
}) => switch (error) {
  ObserverError.invalidKey ||
  ObserverError.noSharedKey => l10n.observerInvalidKey,
  ObserverError.keyOpensNothing => l10n.observerOpensNothingShort(
    observerSinceLabel(since, locale),
  ),
  ObserverError.noPartyKeys => l10n.observerNoPartyKeysBody,
  ObserverError.unknownDispute ||
  ObserverError.noKey ||
  ObserverError.noNode => l10n.observerNotYours,
  ObserverError.noRelays || ObserverError.fetchFailed =>
    '${l10n.observerReadFailedTitle}. ${l10n.observerReadFailedBody}',
};

/// Where a read starts, as a date ("16 nov 2023"); a dash when unknown.
String observerSinceLabel(int? since, String locale) =>
    since == null
        ? '—'
        : DateFormat.yMMMd(
          locale,
        ).format(DateTime.fromMillisecondsSinceEpoch(since * 1000));
