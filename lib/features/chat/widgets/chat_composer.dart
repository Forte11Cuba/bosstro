import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/features/chat/providers/chat_providers.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// The message field of a dispute chat, pinned under the messages: a boxed
/// multi-line field (DS-CMP-11) and a 48-dp send button. What the core
/// refuses is said under the field, and the text stays there to fix.
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({super.key, required this.chat});

  final ChatKey chat;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final _controller = TextEditingController();
  bool _busy = false;
  ChatError? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => !_busy && _controller.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(chatCoreProvider)
          .send(widget.chat.disputeId, widget.chat.party, _controller.text);
      _controller.clear();
      await ref.read(chatThreadProvider(widget.chat).notifier).refresh();
    } on ChatError catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = DisputesPalette.of(context);
    final shell = ShellPalette.of(context);
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.cta),
      borderSide: BorderSide(color: color),
    );
    final hint = switch (widget.chat.party) {
      ChatParty.buyer => l10n.chatComposerBuyerHint,
      ChatParty.seller => l10n.chatComposerSellerHint,
    };
    final error = switch (_error) {
      null || ChatError.empty => null,
      ChatError.tooLong => l10n.chatErrorTooLong,
      ChatError.closed => l10n.chatErrorClosed,
      ChatError.noRelays => l10n.chatErrorNoRelays,
      ChatError.unknownDispute => l10n.chatErrorNotYours,
      _ => l10n.chatErrorGeneric,
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          redesignSidePadding,
          8,
          redesignSidePadding - 6,
          10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: shell.lime,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: pal.bubbleInk,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: pal.composerFill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: outline(pal.composerBorder),
                  enabledBorder: outline(pal.composerBorder),
                  focusedBorder: outline(pal.composerFocusBorder),
                  errorBorder: outline(shell.dangerText),
                  focusedErrorBorder: outline(shell.dangerText),
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: pal.composerPlaceholder,
                  ),
                  errorText: error,
                  errorMaxLines: 3,
                  errorStyle: TextStyle(fontSize: 12, color: shell.dangerText),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _canSend ? _send : null,
              tooltip: l10n.chatSend,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(
                Icons.send_rounded,
                size: 22,
                color: _canSend ? shell.limeIcon : shell.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
