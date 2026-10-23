import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/boxed_field.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';

/// Add a node by its public key, with an optional name (../app's
/// `AddCustomNodeDialog`). Completes with the added node, or null when the
/// solver backs out. The core checks the key: an error stays in the dialog,
/// under the field (DS-CMP-15).
Future<MostroNodeEntry?> showAddNodeDialog(BuildContext context) =>
    showMostroDialog<MostroNodeEntry>(
      context: context,
      builder: (_) => const _AddNodeDialog(),
    );

class _AddNodeDialog extends ConsumerStatefulWidget {
  const _AddNodeDialog();

  @override
  ConsumerState<_AddNodeDialog> createState() => _AddNodeDialogState();
}

class _AddNodeDialogState extends ConsumerState<_AddNodeDialog> {
  final _pubkey = TextEditingController();
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pubkey.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final entry = await ref
          .read(nodeRegistryProvider.notifier)
          .addNode(input: _pubkey.text, name: _name.text);
      if (mounted) Navigator.of(context).pop(entry);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = localizedNodeError(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MostroDialog(
      title: l10n.addNodeTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.addNodeBody,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: ShellPalette.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          BoxedField(
            controller: _pubkey,
            label: l10n.addNodePubkeyLabel,
            hint: 'npub1…',
            mono: true,
            autofocus: true,
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          BoxedField(
            controller: _name,
            label: l10n.addNodeNameLabel,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
          ),
        ],
      ),
      secondary: ModalAction(
        label: l10n.cancel,
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
      ),
      primary: ModalAction(
        label: l10n.addNodeAnswer,
        busy: _busy,
        onPressed: _add,
      ),
    );
  }
}
