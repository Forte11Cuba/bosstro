import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The app's name. A brand: keep it unchanged in every locale
  ///
  /// In en, this message translates to:
  /// **'Bosstro'**
  String get appName;

  /// Bottom bar destination: disputes waiting for a solver to take them
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get navPending;

  /// Bottom bar destination: disputes this solver took and is resolving
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get navInProgress;

  /// Bottom bar destination: settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Tab app bar status line, before the solver chooses a Mostro node
  ///
  /// In en, this message translates to:
  /// **'No node selected'**
  String get noNodeSelected;

  /// Header of the Pending tab
  ///
  /// In en, this message translates to:
  /// **'Pending disputes'**
  String get pendingTitle;

  /// Empty state title of the Pending tab
  ///
  /// In en, this message translates to:
  /// **'No disputes to solve'**
  String get pendingEmptyTitle;

  /// Empty state explanation of the Pending tab
  ///
  /// In en, this message translates to:
  /// **'When a trade on this node opens a dispute, it shows up here for you to take.'**
  String get pendingEmptyBody;

  /// Header of the In progress tab: disputes this solver took
  ///
  /// In en, this message translates to:
  /// **'Your disputes'**
  String get inProgressTitle;

  /// Empty state title of the In progress tab
  ///
  /// In en, this message translates to:
  /// **'No disputes in progress'**
  String get inProgressEmptyTitle;

  /// Empty state explanation of the In progress tab
  ///
  /// In en, this message translates to:
  /// **'Disputes you take show up here, with a chat for the buyer and one for the seller.'**
  String get inProgressEmptyBody;

  /// Header of the Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings group header: information about the app
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsGroupAbout;

  /// Settings row label: the app version, read from the Rust core
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Snackbar confirming a value was copied to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// Data row label of an id (a dispute's or an order's)
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// Screen reader hint of a row that copies an id
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get copyIdHint;

  /// Easter egg shown when the mascot is tapped on 31 October, the whitepaper's anniversary — and Halloween
  ///
  /// In en, this message translates to:
  /// **'31 October 2008: nine pages, nobody\'s permission. Happy Halloween.'**
  String get easterEggWhitepaper;

  /// Easter egg shown when the mascot is tapped on 3 January: the headline Satoshi embedded in the genesis block. A quotation — keep it in English, unchanged, in every locale
  ///
  /// In en, this message translates to:
  /// **'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks'**
  String get easterEggGenesis;

  /// Easter egg shown when the mascot is tapped on 22 May, Bitcoin Pizza Day
  ///
  /// In en, this message translates to:
  /// **'22 May 2010: 10,000 BTC for two pizzas. Hope they were good.'**
  String get easterEggPizzaDay;

  /// Welcome screen headline
  ///
  /// In en, this message translates to:
  /// **'Resolve Mostro disputes'**
  String get welcomeTitle;

  /// Welcome screen: what the app is for
  ///
  /// In en, this message translates to:
  /// **'Take a node\'s disputes, talk with the buyer and the seller, and close them, from your phone.'**
  String get welcomeBody;

  /// Welcome primary action: log in with an existing solver secret key
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get welcomeLogIn;

  /// Welcome secondary action: generate a new solver key
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get welcomeCreateAccount;

  /// Welcome: shown when the stored solver key could not be read or loaded at startup. Nothing was deleted
  ///
  /// In en, this message translates to:
  /// **'The saved key could not be read on this phone. Log in again with your secret key. Logging in with another key replaces the saved one.'**
  String get welcomeKeyUnreadable;

  /// Warning on Log in and Create new account: the solver key must not be the trader identity's key
  ///
  /// In en, this message translates to:
  /// **'Never use the key you trade with. A solver key that is also a trading key links both roles publicly.'**
  String get traderKeyWarning;

  /// App bar title of the Log in screen
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginTitle;

  /// Log in: heading above the secret key field
  ///
  /// In en, this message translates to:
  /// **'Your solver secret key'**
  String get loginHeading;

  /// Log in: what to enter
  ///
  /// In en, this message translates to:
  /// **'Paste or scan the secret key (nsec) whose npub your node operator registered as a solver.'**
  String get loginBody;

  /// Placeholder of the secret key field; the nsec prefix, keep as is
  ///
  /// In en, this message translates to:
  /// **'nsec1…'**
  String get secretKeyHint;

  /// Tooltip: reveal the secret key typed in the field
  ///
  /// In en, this message translates to:
  /// **'Show key'**
  String get showSecretKey;

  /// Tooltip: hide the secret key typed in the field
  ///
  /// In en, this message translates to:
  /// **'Hide key'**
  String get hideSecretKey;

  /// Action under a field: paste from the clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteAction;

  /// Action under a field: scan a QR code with the camera
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQrAction;

  /// Error under the field when Paste finds nothing
  ///
  /// In en, this message translates to:
  /// **'The clipboard is empty.'**
  String get clipboardEmpty;

  /// Log in: check the entered key and show its npub
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginContinue;

  /// Log in error: nothing entered
  ///
  /// In en, this message translates to:
  /// **'Enter your secret key.'**
  String get keyErrorEmpty;

  /// Log in error: an npub was entered instead of an nsec
  ///
  /// In en, this message translates to:
  /// **'That is a public key (npub). Logging in needs the secret key (nsec).'**
  String get keyErrorPublicKey;

  /// Log in error: not an nsec nor a hex secret key
  ///
  /// In en, this message translates to:
  /// **'This is not a valid secret key. Enter an nsec1… key or its 64-character hex form.'**
  String get keyErrorInvalid;

  /// Log in confirmation step: question above the npub the entered key stands for
  ///
  /// In en, this message translates to:
  /// **'Is this the npub registered as a solver?'**
  String get loginConfirmHeading;

  /// Log in confirmation step: why to compare the npub
  ///
  /// In en, this message translates to:
  /// **'Compare it with the npub your node operator added. If it is not the same, this key cannot resolve disputes on that node.'**
  String get loginConfirmBody;

  /// Log in confirmation: confirm the npub and log in. Repeats the opener's verb
  ///
  /// In en, this message translates to:
  /// **'Yes, log in'**
  String get loginConfirmAnswer;

  /// Log in confirmation: go back and enter another key
  ///
  /// In en, this message translates to:
  /// **'No, use another key'**
  String get loginConfirmBack;

  /// Error when loading or storing the solver key failed
  ///
  /// In en, this message translates to:
  /// **'The key could not be saved on this phone. Try again.'**
  String get keySaveFailed;

  /// Label of a public key in npub form; keep as is
  ///
  /// In en, this message translates to:
  /// **'npub'**
  String get npubLabel;

  /// Label of the secret key card
  ///
  /// In en, this message translates to:
  /// **'Secret key (nsec)'**
  String get secretKeyLabel;

  /// Action / screen reader label: copy the npub
  ///
  /// In en, this message translates to:
  /// **'Copy npub'**
  String get copyNpub;

  /// Action / screen reader label: copy the secret key
  ///
  /// In en, this message translates to:
  /// **'Copy secret key'**
  String get copySecretKey;

  /// Action: share the npub through the system share sheet
  ///
  /// In en, this message translates to:
  /// **'Share npub'**
  String get shareNpub;

  /// Screen reader label of the npub QR code
  ///
  /// In en, this message translates to:
  /// **'QR code of your npub'**
  String get npubQrLabel;

  /// App bar title of the QR scanner
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanTitle;

  /// QR scanner: instruction over the camera preview
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code of your secret key.'**
  String get scanHint;

  /// QR scanner: the camera could not start (no camera or permission refused)
  ///
  /// In en, this message translates to:
  /// **'The camera is not available. Go back and paste the key instead.'**
  String get scanUnavailable;

  /// App bar title of Create new account
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createTitle;

  /// Create new account, step 1: heading
  ///
  /// In en, this message translates to:
  /// **'Your new secret key'**
  String get createKeyHeading;

  /// Create new account, step 1: why the secret key must be saved
  ///
  /// In en, this message translates to:
  /// **'It is the only way to log in to this account. Write it down somewhere safe and private: anyone who has it can resolve disputes as you.'**
  String get createKeyBody;

  /// Create new account, step 1: checkbox the solver ticks before continuing
  ///
  /// In en, this message translates to:
  /// **'I saved my secret key somewhere safe'**
  String get createBackupConfirm;

  /// Create new account, step 1: go on once the backup is confirmed
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get createContinue;

  /// Create new account, step 2: heading
  ///
  /// In en, this message translates to:
  /// **'Your npub'**
  String get createNpubHeading;

  /// Create new account, step 2: what to do with the npub
  ///
  /// In en, this message translates to:
  /// **'Send this npub to your node operator so they register you as a solver. Until then you can see the disputes but not take them.'**
  String get createNpubBody;

  /// Create new account, step 2: finish and open the tabs
  ///
  /// In en, this message translates to:
  /// **'Go to disputes'**
  String get createDone;

  /// Settings group header: the solver's key
  ///
  /// In en, this message translates to:
  /// **'Solver key'**
  String get settingsGroupKey;

  /// Settings row: the solver's npub; opens it with its QR
  ///
  /// In en, this message translates to:
  /// **'Your npub'**
  String get settingsNpub;

  /// Settings row: show the secret key for backup
  ///
  /// In en, this message translates to:
  /// **'Back up secret key'**
  String get settingsBackup;

  /// Settings row: remove the key from this phone
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogOut;

  /// Dialog before showing the secret key
  ///
  /// In en, this message translates to:
  /// **'Show your secret key?'**
  String get backupWarnTitle;

  /// Dialog before showing the secret key: the risk
  ///
  /// In en, this message translates to:
  /// **'Anyone who sees it can resolve disputes as you. Make sure nobody is looking at your screen.'**
  String get backupWarnBody;

  /// Dialog answer: show the secret key
  ///
  /// In en, this message translates to:
  /// **'Show secret key'**
  String get backupWarnAnswer;

  /// Dialog way out
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// App bar title of the backup screen
  ///
  /// In en, this message translates to:
  /// **'Secret key backup'**
  String get backupTitle;

  /// Backup screen: what the secret key is for
  ///
  /// In en, this message translates to:
  /// **'Keep it somewhere safe and private. It is the only way to log in to this account on another phone.'**
  String get backupBody;

  /// Backup screen: the stored key could not be read
  ///
  /// In en, this message translates to:
  /// **'The secret key could not be read on this phone.'**
  String get backupUnavailable;

  /// Log out confirmation title
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutTitle;

  /// Log out confirmation: what happens
  ///
  /// In en, this message translates to:
  /// **'Your secret key will be removed from this phone. Without a backup you cannot log in to this account again.'**
  String get logOutBody;

  /// Log out confirmation answer (destructive). Repeats the opener's verb
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOutAnswer;

  /// Error when removing the key failed
  ///
  /// In en, this message translates to:
  /// **'Could not log out. Try again.'**
  String get logOutFailed;

  /// Snackbar after copying the secret key: it is marked sensitive and cleared from the clipboard after 60 seconds
  ///
  /// In en, this message translates to:
  /// **'Secret key copied. It is cleared from the clipboard in 60 seconds.'**
  String get secretKeyCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
