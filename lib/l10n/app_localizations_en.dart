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
      'When a trade on this node opens a dispute, it shows up here for you to take.';

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

  @override
  String get welcomeTitle => 'Resolve Mostro disputes';

  @override
  String get welcomeBody =>
      'Take a node\'s disputes, talk with the buyer and the seller, and close them, from your phone.';

  @override
  String get welcomeLogIn => 'Log in';

  @override
  String get welcomeCreateAccount => 'Create new account';

  @override
  String get welcomeKeyUnreadable =>
      'The saved key could not be read on this phone. Log in again with your secret key. Logging in with another key replaces the saved one.';

  @override
  String get traderKeyWarning =>
      'Never use the key you trade with. A solver key that is also a trading key links both roles publicly.';

  @override
  String get loginTitle => 'Log in';

  @override
  String get loginHeading => 'Your solver secret key';

  @override
  String get loginBody =>
      'Paste or scan the secret key (nsec) whose npub your node operator registered as a solver.';

  @override
  String get secretKeyHint => 'nsec1…';

  @override
  String get showSecretKey => 'Show key';

  @override
  String get hideSecretKey => 'Hide key';

  @override
  String get pasteAction => 'Paste';

  @override
  String get scanQrAction => 'Scan QR';

  @override
  String get clipboardEmpty => 'The clipboard is empty.';

  @override
  String get loginContinue => 'Continue';

  @override
  String get keyErrorEmpty => 'Enter your secret key.';

  @override
  String get keyErrorPublicKey =>
      'That is a public key (npub). Logging in needs the secret key (nsec).';

  @override
  String get keyErrorInvalid =>
      'This is not a valid secret key. Enter an nsec1… key or its 64-character hex form.';

  @override
  String get loginConfirmHeading => 'Is this the npub registered as a solver?';

  @override
  String get loginConfirmBody =>
      'Compare it with the npub your node operator added. If it is not the same, this key cannot resolve disputes on that node.';

  @override
  String get loginConfirmAnswer => 'Yes, log in';

  @override
  String get loginConfirmBack => 'No, use another key';

  @override
  String get keySaveFailed =>
      'The key could not be saved on this phone. Try again.';

  @override
  String get npubLabel => 'npub';

  @override
  String get secretKeyLabel => 'Secret key (nsec)';

  @override
  String get copyNpub => 'Copy npub';

  @override
  String get copySecretKey => 'Copy secret key';

  @override
  String get shareNpub => 'Share npub';

  @override
  String get npubQrLabel => 'QR code of your npub';

  @override
  String get scanTitle => 'Scan QR';

  @override
  String get scanHint => 'Point the camera at the QR code of your secret key.';

  @override
  String get scanUnavailable =>
      'The camera is not available. Go back and paste the key instead.';

  @override
  String get createTitle => 'Create new account';

  @override
  String get createKeyHeading => 'Your new secret key';

  @override
  String get createKeyBody =>
      'It is the only way to log in to this account. Write it down somewhere safe and private: anyone who has it can resolve disputes as you.';

  @override
  String get createBackupConfirm => 'I saved my secret key somewhere safe';

  @override
  String get createContinue => 'Continue';

  @override
  String get createNpubHeading => 'Your npub';

  @override
  String get createNpubBody =>
      'Send this npub to your node operator so they register you as a solver. Until then you can see the disputes but not take them.';

  @override
  String get createDone => 'Go to disputes';

  @override
  String get settingsGroupKey => 'Solver key';

  @override
  String get settingsNpub => 'Your npub';

  @override
  String get settingsBackup => 'Back up secret key';

  @override
  String get settingsLogOut => 'Log out';

  @override
  String get backupWarnTitle => 'Show your secret key?';

  @override
  String get backupWarnBody =>
      'Anyone who sees it can resolve disputes as you. Make sure nobody is looking at your screen.';

  @override
  String get backupWarnAnswer => 'Show secret key';

  @override
  String get cancel => 'Cancel';

  @override
  String get backupTitle => 'Secret key backup';

  @override
  String get backupBody =>
      'Keep it somewhere safe and private. It is the only way to log in to this account on another phone.';

  @override
  String get backupUnavailable =>
      'The secret key could not be read on this phone.';

  @override
  String get logOutTitle => 'Log out?';

  @override
  String get logOutBody =>
      'Your secret key will be removed from this phone. Without a backup you cannot log in to this account again.';

  @override
  String get logOutAnswer => 'Log out';

  @override
  String get logOutFailed => 'Could not log out. Try again.';

  @override
  String get secretKeyCopied =>
      'Secret key copied. It is cleared from the clipboard in 60 seconds.';
}
