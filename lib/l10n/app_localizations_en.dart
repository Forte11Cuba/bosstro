// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bosstro';

  @override
  String get navPending => 'Pending';

  @override
  String get navInProgress => 'In progress';

  @override
  String get navSettings => 'Settings';

  @override
  String get noNodeSelected => 'No node selected';

  @override
  String get pendingTitle => 'Pending disputes';

  @override
  String get pendingEmptyTitle => 'No disputes to solve';

  @override
  String get pendingEmptyBody =>
      'When a trade on this node opens a dispute, it shows up here for a solver to take.';

  @override
  String get inProgressTitle => 'Your disputes';

  @override
  String get inProgressEmptyTitle => 'No disputes in progress';

  @override
  String get inProgressEmptyBody =>
      'Disputes you take show up here, with a chat for the buyer and one for the seller.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get copied => 'Copied';

  @override
  String get idLabel => 'ID';

  @override
  String get copyIdHint => 'Copy ID';

  @override
  String get easterEggWhitepaper =>
      '31 October 2008: nine pages, nobody\'s permission. Happy Halloween.';

  @override
  String get easterEggGenesis =>
      'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks';

  @override
  String get easterEggPizzaDay =>
      '22 May 2010: 10,000 BTC for two pizzas. Hope they were good.';
}
