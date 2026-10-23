import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/platform_capabilities.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/providers/device_security_providers.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/snackbar.dart';

/// A chat key a party disclosed (../app's `share_chat_key_with_solver`):
/// `Shared key: ` and the 64-hex secret of a conversation's `K_conv`.
final _chatKey = RegExp(r'Shared key:\s*[0-9a-fA-F]{64}');

/// Whether [text] carries a chat key, a secret: it reads a conversation.
bool holdsChatKey(String text) => _chatKey.hasMatch(text);

/// What a long press on a chat message copies, or null when it copies
/// nothing. A message is copied whole, as plain text, like an id
/// ([copyId]); a file, by its name (as Mostrix). A message that carries a
/// chat key is a secret and is copied the way the solver key is
/// (`copySecretKey`): marked sensitive and cleared after a minute, and only
/// where the device can (Android, `PlatformCapabilities.copySecret`);
/// elsewhere it is not offered, and the key is read in the app anyway.
///
/// Never selectable text: a selectable bubble takes the taps meant for the
/// file in it, and the system's copy menu skips the sensitive path.
VoidCallback? messageCopier(BuildContext context, String text) {
  final value = text.trim();
  if (value.isEmpty) return null;
  if (holdsChatKey(value)) {
    if (!PlatformCapabilities.copySecret) return null;
    return () => _copySecret(context, value);
  }
  return () => copyId(context, value);
}

Future<void> _copySecret(BuildContext context, String secret) async {
  final copied = AppLocalizations.of(context).chatKeyCopied;
  HapticFeedback.selectionClick();
  await ProviderScope.containerOf(
    context,
    listen: false,
  ).read(sensitiveClipboardProvider).copy(secret);
  if (context.mounted) showMostroSnackBar(context, copied);
}
