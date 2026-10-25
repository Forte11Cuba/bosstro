import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/settings_palette.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';

/// A node's face (from MostroP2P/app's `NodeAvatar`): its kind 0 picture as the
/// device keeps it, else from its URL, else its initial on a tint derived
/// from its name. Decorative: the name next to it says who the node is.
class NodeAvatar extends ConsumerWidget {
  const NodeAvatar({super.key, required this.entry, this.size = 36});

  final MostroNodeEntry entry;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = SettingsPalette.of(context);
    final name = nodeDisplayName(entry);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    // Tint derived from the name, never a generated identicon.
    final lime = name.codeUnits.fold<int>(0, (a, b) => a + b).isEven;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lime ? pal.avatarLimeBg : pal.avatarYellowBg,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: lime ? pal.avatarLimeInk : pal.avatarYellowInk,
        ),
      ),
    );
    final picture = entry.picture;
    if (picture == null) return ExcludeSemantics(child: fallback);
    final stored = ref.watch(nodePictureProvider(entry.pubkey));
    final kept = stored.valueOrNull;
    final ImageProvider image;
    if (kept != null && kept.url == picture) {
      image = nodePictureImage(kept.bytes);
    } else if (stored.isLoading && !stored.hasValue) {
      // The device answers within a frame or two: no download meanwhile.
      return SizedBox.square(dimension: size);
    } else {
      image = ResizeImage(NetworkImage(picture), width: nodePictureCacheWidth);
    }
    return ExcludeSemantics(
      child: ClipOval(
        child: Image(
          image: image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
