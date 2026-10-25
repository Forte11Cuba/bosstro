import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/utils/short_id.dart';

/// MostroP2P/app's default node, the first of the registry. Its kind 0 name is
/// used once known; until then it is called by its brand.
const mostroNodePubkey =
    '82fa8cb978b43c79b2156585bac2c011176a21d2aead6d9f7c575c005be88390';

/// The brand name of [mostroNodePubkey]: a proper noun, never translated.
const mostroNodeName = 'Mostro';

/// The leading emoji of a region label like `🇨🇺 Cuba`, or null.
String? regionFlag(String? region) {
  if (region == null || region.isEmpty) return null;
  final first = region.split(' ').first;
  final isEmoji =
      first.runes.isNotEmpty && first.runes.every((r) => r >= 0x1F000);
  return isEmoji ? first : null;
}

/// A region label without its flag (`Cuba`), or null when nothing is left.
String? regionPlace(String? region) {
  if (region == null) return null;
  final place =
      regionFlag(region) == null ? region : region.split(' ').skip(1).join(' ');
  return place.trim().isEmpty ? null : place.trim();
}

/// A node's title (from MostroP2P/app's `nodeDisplayName`): the solver's or the
/// kind 0 name, then the region's place, then "Mostro" for the default node,
/// then the short pubkey.
String nodeDisplayName(MostroNodeEntry entry) {
  final name = entry.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  final place = regionPlace(entry.region);
  if (place != null) return place;
  if (entry.pubkey == mostroNodePubkey) return mostroNodeName;
  return shortOrderId(entry.pubkey);
}

/// The copy for a node error. The core's errors are stable markers
/// (`rust/src/api/nodes.rs`); prose never crosses the bridge.
String localizedNodeError(AppLocalizations l10n, Object error) {
  final marker = error.toString();
  if (marker.contains('PrivateKeyNotAllowed')) return l10n.nodeErrorPrivateKey;
  if (marker.contains('NodeAlreadyExists')) return l10n.nodeErrorAlreadyExists;
  if (marker.contains('InvalidPubkey')) return l10n.nodeErrorInvalidPubkey;
  if (marker.contains('CannotRemoveActiveNode')) return l10n.nodeErrorActive;
  if (marker.contains('NotInitialized')) return l10n.nodeErrorStorage;
  return l10n.nodeErrorGeneric;
}

/// The copy for a relay error (markers of `rust/src/api/relays.rs`).
String localizedRelayError(AppLocalizations l10n, Object error) {
  final marker = error.toString();
  if (marker.contains('InvalidRelayUrl')) return l10n.relayErrorInvalidUrl;
  if (marker.contains('RelayAlreadyExists')) return l10n.relayErrorExists;
  if (marker.contains('LastRelay')) return l10n.relayErrorLast;
  if (marker.contains('NotInitialized')) return l10n.relaysNotRunningTitle;
  return l10n.nodeErrorGeneric;
}

/// "Updated 3 hours ago" for an event published at [unixSeconds].
String updatedAgo(AppLocalizations l10n, int unixSeconds, DateTime now) {
  final age = now.millisecondsSinceEpoch ~/ 1000 - unixSeconds;
  if (age < 60) return l10n.nodeInfoUpdatedNow;
  if (age < 3600) return l10n.nodeInfoUpdatedMinutes(age ~/ 60);
  if (age < 86400) return l10n.nodeInfoUpdatedHours(age ~/ 3600);
  return l10n.nodeInfoUpdatedDays(age ~/ 86400);
}
