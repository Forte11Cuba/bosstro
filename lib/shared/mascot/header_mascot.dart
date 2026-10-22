import 'package:flutter/material.dart';

import 'package:bosstro/shared/mascot/mostro_mascot.dart';

/// The Mostro in every tab's app bar: tap it and it reacts.
///
/// ../app's version also takes the mood of the app around it (relay outages,
/// trade steps). Bosstro has no relays yet; the moods arrive with them
/// (phase 2), and this stays the place they plug in.
class HeaderMascot extends StatelessWidget {
  const HeaderMascot({super.key});

  /// Height of the artwork in the app bar.
  static const double height = 26;

  @override
  Widget build(BuildContext context) =>
      const MostroMascot(height: height, interactive: true);
}
