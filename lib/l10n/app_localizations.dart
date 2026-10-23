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
  /// **'No disputes waiting'**
  String get pendingEmptyTitle;

  /// Empty state explanation of the Pending tab
  ///
  /// In en, this message translates to:
  /// **'No dispute on this node is waiting for a solver. When a trade opens one, it shows up here for you to take.'**
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
  /// **'Disputes you take show up here. If a take got no answer, recover it.'**
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

  /// Log in: what to enter, where there is no QR scanner (Linux, web)
  ///
  /// In en, this message translates to:
  /// **'Paste the secret key (nsec) whose npub your node operator registered as a solver.'**
  String get loginBodyPaste;

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

  /// Last button of Create new account: opens the node selector
  ///
  /// In en, this message translates to:
  /// **'Choose your node'**
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

  /// Tab app bar status line: the relays answer. connected = relays connected, total = relays in use
  ///
  /// In en, this message translates to:
  /// **'Online · {connected}/{total} relays'**
  String linkOnline(int connected, int total);

  /// Tab app bar status line while no relay is connected yet but one is trying
  ///
  /// In en, this message translates to:
  /// **'Connecting to relays…'**
  String get linkConnecting;

  /// Tab app bar status line when no relay is connected
  ///
  /// In en, this message translates to:
  /// **'Offline · no relay answers'**
  String get linkOffline;

  /// Header of the node selector, after logging in and from Configuración → Node
  ///
  /// In en, this message translates to:
  /// **'Choose your node'**
  String get chooseNodeTitle;

  /// Explanation under the node selector's header
  ///
  /// In en, this message translates to:
  /// **'Pick the Mostro node whose operator registered your key as a solver. You can switch nodes later in Settings.'**
  String get chooseNodeBody;

  /// App bar title of the node selector when opened from Settings
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get chooseNodeAppBar;

  /// Chip on a node from the compiled-in list of trusted Mostro communities
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get nodeChipTrusted;

  /// Chip on a node the solver added by its public key
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get nodeChipCustom;

  /// Chip on the node the app is using now
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get nodeChipActive;

  /// Button under the node list: add a node by its public key
  ///
  /// In en, this message translates to:
  /// **'Add your own node'**
  String get nodeAddOwn;

  /// Tooltip and accessible label of the info button on a node card
  ///
  /// In en, this message translates to:
  /// **'Node info'**
  String get nodeInfoTooltip;

  /// Snackbar after switching to another node
  ///
  /// In en, this message translates to:
  /// **'Now on {name}'**
  String nodeSwitched(String name);

  /// Error when saving the active node failed
  ///
  /// In en, this message translates to:
  /// **'Could not switch to this node. Try again.'**
  String get nodeSelectFailed;

  /// Error state of the node selector
  ///
  /// In en, this message translates to:
  /// **'The node list could not be loaded. Restart the app to try again.'**
  String get nodeListFailed;

  /// Title of the add-node dialog
  ///
  /// In en, this message translates to:
  /// **'Add a node'**
  String get addNodeTitle;

  /// Explanation in the add-node dialog
  ///
  /// In en, this message translates to:
  /// **'Paste the node\'s public key (npub or hex). Its operator can give it to you.'**
  String get addNodeBody;

  /// Label of the public key field in the add-node dialog
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get addNodePubkeyLabel;

  /// Label of the optional name field in the add-node dialog
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get addNodeNameLabel;

  /// Add-node dialog confirmation
  ///
  /// In en, this message translates to:
  /// **'Add node'**
  String get addNodeAnswer;

  /// Add-node error: not a public key
  ///
  /// In en, this message translates to:
  /// **'Enter a valid public key (npub or 64 hex characters).'**
  String get nodeErrorInvalidPubkey;

  /// Add-node error: an nsec was entered
  ///
  /// In en, this message translates to:
  /// **'That is a secret key — never share it. Enter the node\'s public key.'**
  String get nodeErrorPrivateKey;

  /// Add-node error: duplicate
  ///
  /// In en, this message translates to:
  /// **'This node is already in the list.'**
  String get nodeErrorAlreadyExists;

  /// Remove-node error: the node is active
  ///
  /// In en, this message translates to:
  /// **'This is your active node. Switch to another node before removing it.'**
  String get nodeErrorActive;

  /// Node error: the local database is not available
  ///
  /// In en, this message translates to:
  /// **'Your nodes could not be saved on this device.'**
  String get nodeErrorStorage;

  /// Node error with no specific copy
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get nodeErrorGeneric;

  /// Action on the info screen of a node the solver added
  ///
  /// In en, this message translates to:
  /// **'Remove node'**
  String get removeNodeAction;

  /// Remove-node confirmation title
  ///
  /// In en, this message translates to:
  /// **'Remove this node?'**
  String get removeNodeTitle;

  /// Remove-node confirmation body
  ///
  /// In en, this message translates to:
  /// **'It leaves your list. You can add it again with its public key.'**
  String get removeNodeBody;

  /// Remove-node confirmation answer (destructive). Repeats the opener's verb
  ///
  /// In en, this message translates to:
  /// **'Remove node'**
  String get removeNodeAnswer;

  /// Snackbar after removing a node
  ///
  /// In en, this message translates to:
  /// **'Node removed'**
  String get nodeRemoved;

  /// App bar title of the node info screen
  ///
  /// In en, this message translates to:
  /// **'Node info'**
  String get nodeInfoTitle;

  /// Primary action of the node info screen for a node that is not active
  ///
  /// In en, this message translates to:
  /// **'Use this node'**
  String get nodeInfoUse;

  /// Group header: the node's identity (public key, kind 0 profile)
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get nodeInfoGroupNode;

  /// Row label: the node's public key
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get nodeInfoPubkey;

  /// Row label: the region of a trusted community
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get nodeInfoRegion;

  /// Row label: the website of the node's profile
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get nodeInfoWebsite;

  /// Row label: the description in the node's profile
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get nodeInfoAbout;

  /// Empty state of the node info screen: the node's kind 38385 event was not found
  ///
  /// In en, this message translates to:
  /// **'No instance info yet'**
  String get nodeInfoEmptyTitle;

  /// Empty state body of the node info screen
  ///
  /// In en, this message translates to:
  /// **'This node has not published its instance info on your relays, or they have not answered yet. It is asked for again each time you open this screen.'**
  String get nodeInfoEmptyBody;

  /// Note when fetching the node info failed but a cached copy is shown
  ///
  /// In en, this message translates to:
  /// **'The relays did not answer. This is the info last seen.'**
  String get nodeInfoRefreshFailed;

  /// Warning when the node's instance info is older than 7 days
  ///
  /// In en, this message translates to:
  /// **'This info is more than 7 days old and may be out of date.'**
  String get nodeInfoStale;

  /// Warning for a node that advertises a protocol other than v2
  ///
  /// In en, this message translates to:
  /// **'This node speaks protocol v{version}. Bosstro speaks only v2, so it cannot resolve disputes there.'**
  String nodeInfoUnsupported(int version);

  /// When the node last published its info: under a minute ago
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get nodeInfoUpdatedNow;

  /// When the node last published its info
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Updated 1 minute ago} other{Updated {count} minutes ago}}'**
  String nodeInfoUpdatedMinutes(int count);

  /// When the node last published its info
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Updated 1 hour ago} other{Updated {count} hours ago}}'**
  String nodeInfoUpdatedHours(int count);

  /// When the node last published its info
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Updated 1 day ago} other{Updated {count} days ago}}'**
  String nodeInfoUpdatedDays(int count);

  /// Group header (Mostrix's Mostro Info tab)
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get nodeInfoGroupProtocol;

  /// Row label: kind 38385 protocol_version
  ///
  /// In en, this message translates to:
  /// **'Protocol version'**
  String get nodeInfoProtocolVersion;

  /// Row label: the transport Bosstro uses with the node
  ///
  /// In en, this message translates to:
  /// **'Wire transport'**
  String get nodeInfoTransport;

  /// Group header: the node's mostrod settings
  ///
  /// In en, this message translates to:
  /// **'Mostro daemon'**
  String get nodeInfoGroupDaemon;

  /// Row label: mostro_version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get nodeInfoVersion;

  /// Row label: mostro_commit_hash or lnd_commit_hash
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get nodeInfoCommit;

  /// Row label: max_order_amount, in sats
  ///
  /// In en, this message translates to:
  /// **'Max order'**
  String get nodeInfoMaxOrder;

  /// Row label: min_order_amount, in sats
  ///
  /// In en, this message translates to:
  /// **'Min order'**
  String get nodeInfoMinOrder;

  /// Row label: expiration_hours
  ///
  /// In en, this message translates to:
  /// **'Order expiration'**
  String get nodeInfoExpirationHours;

  /// Row label: expiration_seconds
  ///
  /// In en, this message translates to:
  /// **'Taken order expiration'**
  String get nodeInfoExpirationSeconds;

  /// Row label: hold_invoice_expiration_window, seconds
  ///
  /// In en, this message translates to:
  /// **'Hold invoice window'**
  String get nodeInfoHoldWindow;

  /// Row label: hold_invoice_cltv_delta, blocks
  ///
  /// In en, this message translates to:
  /// **'Hold invoice CLTV delta'**
  String get nodeInfoHoldCltv;

  /// Row label: invoice_expiration_window, seconds
  ///
  /// In en, this message translates to:
  /// **'Invoice window'**
  String get nodeInfoInvoiceWindow;

  /// Row label: max_orders_per_response
  ///
  /// In en, this message translates to:
  /// **'Max orders per response'**
  String get nodeInfoMaxOrders;

  /// Row label: the node's fee
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get nodeInfoFee;

  /// Row label: pow, in bits
  ///
  /// In en, this message translates to:
  /// **'Required PoW'**
  String get nodeInfoPow;

  /// Row label: pow_first_contact, in bits
  ///
  /// In en, this message translates to:
  /// **'PoW on first contact'**
  String get nodeInfoPowFirst;

  /// Row label: bond_enabled
  ///
  /// In en, this message translates to:
  /// **'Anti-abuse bonds'**
  String get nodeInfoBonds;

  /// Group header: the node's LND
  ///
  /// In en, this message translates to:
  /// **'Lightning node'**
  String get nodeInfoGroupLightning;

  /// Row label: lnd_node_alias
  ///
  /// In en, this message translates to:
  /// **'Alias'**
  String get nodeInfoAlias;

  /// Row label: lnd_node_pubkey
  ///
  /// In en, this message translates to:
  /// **'Node pubkey'**
  String get nodeInfoLnPubkey;

  /// Row label: lnd_version
  ///
  /// In en, this message translates to:
  /// **'LND version'**
  String get nodeInfoLndVersion;

  /// Row label: lnd_chains
  ///
  /// In en, this message translates to:
  /// **'Chains'**
  String get nodeInfoChains;

  /// Row label: lnd_networks
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get nodeInfoNetworks;

  /// Row label: one of lnd_uris
  ///
  /// In en, this message translates to:
  /// **'URI'**
  String get nodeInfoUri;

  /// Group header: fiat_currencies_accepted
  ///
  /// In en, this message translates to:
  /// **'Fiat currencies'**
  String get nodeInfoGroupFiat;

  /// When the node accepts every fiat currency
  ///
  /// In en, this message translates to:
  /// **'All currencies are accepted.'**
  String get nodeInfoFiatAll;

  /// A value the node does not publish
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get nodeInfoUnknown;

  /// bond_enabled true
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get nodeInfoEnabled;

  /// bond_enabled false
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get nodeInfoDisabled;

  /// An amount in satoshis. amount is formatted
  ///
  /// In en, this message translates to:
  /// **'{amount} sats'**
  String unitSats(String amount);

  /// A duration in hours
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String unitHours(int count);

  /// A duration in seconds
  ///
  /// In en, this message translates to:
  /// **'{count} s'**
  String unitSeconds(int count);

  /// A number of blocks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 block} other{{count} blocks}}'**
  String unitBlocks(int count);

  /// Proof-of-work difficulty in bits
  ///
  /// In en, this message translates to:
  /// **'{count} bits'**
  String unitBits(int count);

  /// A percentage. value is formatted
  ///
  /// In en, this message translates to:
  /// **'{value} %'**
  String unitPercent(String value);

  /// App bar title of the relays screen
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get relaysTitle;

  /// Explanation at the top of the relays screen
  ///
  /// In en, this message translates to:
  /// **'Bosstro talks to your node through these relays. The relays your node announces are added for you.'**
  String get relaysBody;

  /// A relay's status
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get relayStatusConnected;

  /// A relay's status
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get relayStatusConnecting;

  /// A relay's status
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get relayStatusDisconnected;

  /// A relay's status: the relay refused the connection (banned)
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get relayStatusError;

  /// Where a relay came from: seeded on first launch
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get relaySourceDefault;

  /// Where a relay came from: the node's relay list
  ///
  /// In en, this message translates to:
  /// **'From your node'**
  String get relaySourceNode;

  /// Where a relay came from: the solver added it
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get relaySourceUser;

  /// Button on the relays screen
  ///
  /// In en, this message translates to:
  /// **'Add relay'**
  String get relayAdd;

  /// Title of the add-relay dialog
  ///
  /// In en, this message translates to:
  /// **'Add a relay'**
  String get addRelayTitle;

  /// Label of the field in the add-relay dialog
  ///
  /// In en, this message translates to:
  /// **'Relay address'**
  String get addRelayLabel;

  /// Add-relay dialog confirmation
  ///
  /// In en, this message translates to:
  /// **'Add relay'**
  String get addRelayAnswer;

  /// Tooltip and accessible label of a relay's remove button
  ///
  /// In en, this message translates to:
  /// **'Remove relay'**
  String get relayRemoveTooltip;

  /// Remove-relay confirmation title
  ///
  /// In en, this message translates to:
  /// **'Remove this relay?'**
  String get removeRelayTitle;

  /// Remove-relay confirmation body
  ///
  /// In en, this message translates to:
  /// **'Bosstro stops using it. A relay your node announced comes back only if you add it yourself.'**
  String get removeRelayBody;

  /// Remove-relay confirmation answer (destructive). Repeats the opener's verb
  ///
  /// In en, this message translates to:
  /// **'Remove relay'**
  String get removeRelayAnswer;

  /// Add-relay error: not a websocket URL
  ///
  /// In en, this message translates to:
  /// **'Enter a relay address that starts with wss://.'**
  String get relayErrorInvalidUrl;

  /// Add-relay error: duplicate
  ///
  /// In en, this message translates to:
  /// **'This relay is already in the list.'**
  String get relayErrorExists;

  /// Remove-relay error: it is the only one
  ///
  /// In en, this message translates to:
  /// **'This is your last relay. Add another before removing it.'**
  String get relayErrorLast;

  /// Error state of the relays screen
  ///
  /// In en, this message translates to:
  /// **'The relays did not start'**
  String get relaysNotRunningTitle;

  /// Error state body of the relays screen
  ///
  /// In en, this message translates to:
  /// **'Bosstro could not open its connection to the relays. Restart the app to try again.'**
  String get relaysNotRunningBody;

  /// Settings group header: the active node and its relays
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get settingsGroupNode;

  /// Settings row: opens the node selector; its value is the active node's name
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get settingsNode;

  /// Value of the Node row when no node is chosen
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get settingsNodeNone;

  /// Settings row: opens the active node's info
  ///
  /// In en, this message translates to:
  /// **'Node info'**
  String get settingsNodeInfo;

  /// Settings row: opens the relays screen
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get settingsRelays;

  /// Value of the Relays row: connected relays / relays in use
  ///
  /// In en, this message translates to:
  /// **'{connected}/{total}'**
  String settingsRelaysValue(int connected, int total);

  /// Pending tab empty state before a node is chosen
  ///
  /// In en, this message translates to:
  /// **'Choose your node first'**
  String get pendingNoNodeTitle;

  /// Pending tab empty state body before a node is chosen
  ///
  /// In en, this message translates to:
  /// **'Disputes are read from one Mostro node at a time. Pick the node where you are a solver.'**
  String get pendingNoNodeBody;

  /// Pending tab empty state action: opens the node selector
  ///
  /// In en, this message translates to:
  /// **'Choose node'**
  String get pendingNoNodeAction;

  /// Screen-reader label of the node list skeleton
  ///
  /// In en, this message translates to:
  /// **'Loading nodes'**
  String get loadingNodes;

  /// Screen-reader label of the node info skeleton
  ///
  /// In en, this message translates to:
  /// **'Loading node info'**
  String get loadingNodeInfo;

  /// Screen-reader label of the relay list skeleton
  ///
  /// In en, this message translates to:
  /// **'Loading relays'**
  String get loadingRelays;

  /// Screen-reader label of the Pending list skeleton
  ///
  /// In en, this message translates to:
  /// **'Loading disputes'**
  String get loadingDisputes;

  /// Pending tab state when the stored disputes cannot be read
  ///
  /// In en, this message translates to:
  /// **'Disputes could not be read'**
  String get pendingLoadErrorTitle;

  /// Explanation under pendingLoadErrorTitle
  ///
  /// In en, this message translates to:
  /// **'Something went wrong reading this node\'s disputes on this phone. Close and reopen Bosstro to try again.'**
  String get pendingLoadErrorBody;

  /// Status chip of a dispute nobody has taken yet (initiated). Shown upper-case
  ///
  /// In en, this message translates to:
  /// **'Waiting for a solver'**
  String get disputeStatusInitiated;

  /// Status chip of a dispute a solver took (in-progress). Shown upper-case
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get disputeStatusInProgress;

  /// Status chip of a dispute a solver closed by paying the buyer (settled). Shown upper-case
  ///
  /// In en, this message translates to:
  /// **'Buyer paid'**
  String get disputeStatusSettled;

  /// Status chip of a dispute a solver closed by refunding the seller (seller-refunded). Shown upper-case
  ///
  /// In en, this message translates to:
  /// **'Seller refunded'**
  String get disputeStatusSellerRefunded;

  /// Status chip of a dispute the seller ended by releasing the funds (released). Shown upper-case
  ///
  /// In en, this message translates to:
  /// **'Released by the seller'**
  String get disputeStatusReleased;

  /// Status chip of a dispute the buyer and seller ended by canceling together (cooperatively-canceled). Shown upper-case
  ///
  /// In en, this message translates to:
  /// **'Canceled by both parties'**
  String get disputeStatusCooperativelyCanceled;

  /// Who opened a dispute: the buyer
  ///
  /// In en, this message translates to:
  /// **'Opened by the buyer'**
  String get disputeOpenedByBuyer;

  /// Who opened a dispute: the seller
  ///
  /// In en, this message translates to:
  /// **'Opened by the seller'**
  String get disputeOpenedBySeller;

  /// Who opened a dispute: the node did not say
  ///
  /// In en, this message translates to:
  /// **'Opener not known'**
  String get disputeOpenedByUnknown;

  /// Age of a dispute opened less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'Opened just now'**
  String get disputeOpenedJustNow;

  /// Age of a dispute, in minutes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Opened 1 minute ago} other{Opened {count} minutes ago}}'**
  String disputeOpenedMinutesAgo(int count);

  /// Age of a dispute, in hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Opened 1 hour ago} other{Opened {count} hours ago}}'**
  String disputeOpenedHoursAgo(int count);

  /// Age of a dispute, in days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Opened 1 day ago} other{Opened {count} days ago}}'**
  String disputeOpenedDaysAgo(int count);

  /// Age of a dispute whose event carries no open time
  ///
  /// In en, this message translates to:
  /// **'Open time not known'**
  String get disputeOpenedUnknown;

  /// Screen-reader label of a dispute row; id is the short dispute id
  ///
  /// In en, this message translates to:
  /// **'Dispute {id}'**
  String disputeRowLabel(String id);

  /// Answer of a dialog that only informs
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Screen-reader hint of a Pending row: tapping it opens the take confirmation (glossary: take a dispute)
  ///
  /// In en, this message translates to:
  /// **'Take dispute'**
  String get takeDisputeHint;

  /// Title of the confirmation before taking a dispute
  ///
  /// In en, this message translates to:
  /// **'Take this dispute?'**
  String get takeDisputeTitle;

  /// Body of the take confirmation
  ///
  /// In en, this message translates to:
  /// **'You become its solver: the node tells the buyer and the seller, and the dispute moves to Your disputes. Take only a dispute you can see through.'**
  String get takeDisputeBody;

  /// Answer of the take confirmation; repeats the opener's verb (DS-CMP-26, glossary: take a dispute)
  ///
  /// In en, this message translates to:
  /// **'Take dispute'**
  String get takeDisputeAnswer;

  /// Snackbar once the node gave the solver the dispute
  ///
  /// In en, this message translates to:
  /// **'Dispute taken. It is in Your disputes.'**
  String get takeTakenSnack;

  /// Label of the action in the Your disputes header that opens Recover a dispute
  ///
  /// In en, this message translates to:
  /// **'Recover'**
  String get recoverAction;

  /// Title of the Recover a dispute screen, and the link to it
  ///
  /// In en, this message translates to:
  /// **'Recover a dispute'**
  String get recoverTitle;

  /// Note at the top of Recover a dispute
  ///
  /// In en, this message translates to:
  /// **'The node does not publish who holds a dispute. So this list shows every dispute in progress on this node that is not among Your disputes on this phone: yours whose answer was lost, and other solvers\'. Recover them one at a time.'**
  String get recoverNote;

  /// Recover a dispute with no candidate
  ///
  /// In en, this message translates to:
  /// **'Nothing to recover'**
  String get recoverEmptyTitle;

  /// Explanation under recoverEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No dispute in progress on this node is missing from Your disputes.'**
  String get recoverEmptyBody;

  /// Screen-reader hint of a Recover row: tapping it opens the recover confirmation
  ///
  /// In en, this message translates to:
  /// **'Recover dispute'**
  String get recoverDisputeHint;

  /// Title of the confirmation before recovering a dispute
  ///
  /// In en, this message translates to:
  /// **'Recover this dispute?'**
  String get recoverDisputeTitle;

  /// Body of the recover confirmation; warns about the take-over
  ///
  /// In en, this message translates to:
  /// **'Bosstro asks the node for this dispute again. If it is yours, the node sends its data back. If another solver holds it, the node says no, unless that solver is read-only, like Serbero, and your key can pay the buyer and refund the seller: then the dispute becomes yours (a take-over).'**
  String get recoverDisputeBody;

  /// Answer of the recover confirmation; repeats the opener's verb (DS-CMP-26)
  ///
  /// In en, this message translates to:
  /// **'Recover dispute'**
  String get recoverDisputeAnswer;

  /// Snackbar once the node gave the dispute back
  ///
  /// In en, this message translates to:
  /// **'Dispute recovered. It is in Your disputes.'**
  String get recoverTakenSnack;

  /// Banner on Pending and take outcome when the node refused a dispute waiting for a solver
  ///
  /// In en, this message translates to:
  /// **'You are not a solver on this node'**
  String get notSolverTitle;

  /// Body under notSolverTitle
  ///
  /// In en, this message translates to:
  /// **'Switch to your node to resolve disputes. If this is your node, send your npub to its operator.'**
  String get notSolverBody;

  /// Action that opens the node selector from the not-a-solver banner or outcome
  ///
  /// In en, this message translates to:
  /// **'Switch node'**
  String get switchNodeAction;

  /// Take outcome when the node refused a dispute a solver already holds
  ///
  /// In en, this message translates to:
  /// **'Another solver holds this dispute'**
  String get cannotTakeOverTitle;

  /// Body under cannotTakeOverTitle
  ///
  /// In en, this message translates to:
  /// **'Only a dispute held by a read-only solver, like Serbero, can be taken over, and only by a solver who can pay the buyer and refund the seller.'**
  String get cannotTakeOverBody;

  /// Take outcome for any other refusal
  ///
  /// In en, this message translates to:
  /// **'The node did not give you this dispute'**
  String get takeRefusedTitle;

  /// Body under takeRefusedTitle
  ///
  /// In en, this message translates to:
  /// **'It refused the request. Try again later, or ask the node\'s operator.'**
  String get takeRefusedBody;

  /// Body under takeRefusedTitle when the node did not find the order
  ///
  /// In en, this message translates to:
  /// **'The node no longer has this dispute\'s order.'**
  String get takeRefusedNotFoundBody;

  /// Take outcome when no answer arrived in time
  ///
  /// In en, this message translates to:
  /// **'The node did not answer'**
  String get noAnswerTitle;

  /// Body under noAnswerTitle
  ///
  /// In en, this message translates to:
  /// **'Your request may have reached it all the same, so Bosstro did not send it again. In a moment, look in Your disputes, or ask again from Recover a dispute.'**
  String get noAnswerBody;

  /// Take outcome when the request could not leave
  ///
  /// In en, this message translates to:
  /// **'The request was not sent'**
  String get takeFailedTitle;

  /// Body under takeFailedTitle
  ///
  /// In en, this message translates to:
  /// **'No relay took it. Check your connection and the relays, then try again.'**
  String get takeFailedBody;

  /// Body under takeFailedTitle when a take of this dispute is pending
  ///
  /// In en, this message translates to:
  /// **'A request for this dispute is already waiting for the node\'s answer.'**
  String get takeAlreadyTakingBody;

  /// Body under takeFailedTitle when the dispute closed meanwhile
  ///
  /// In en, this message translates to:
  /// **'This dispute is closed: there is nothing to take.'**
  String get takeClosedBody;

  /// Body under takeFailedTitle when the dispute is not stored
  ///
  /// In en, this message translates to:
  /// **'This dispute is not among this node\'s disputes on this phone.'**
  String get takeUnknownBody;

  /// Body under takeFailedTitle when the node does not speak protocol 2
  ///
  /// In en, this message translates to:
  /// **'This node announces another protocol version. Bosstro talks to nodes on protocol 2 only.'**
  String get takeProtocolBody;

  /// Body under takeFailedTitle when the node's kind 38385 (its settings, with the proof of work a request needs) was never read
  ///
  /// In en, this message translates to:
  /// **'Bosstro could not read this node\'s settings, so it does not know the proof of work the node asks for. Check the relays and try again.'**
  String get takeNodeInfoBody;

  /// How long ago the solver took a dispute, under a minute
  ///
  /// In en, this message translates to:
  /// **'Taken just now'**
  String get disputeTakenJustNow;

  /// How long ago the solver took a dispute, in minutes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Taken 1 minute ago} other{Taken {count} minutes ago}}'**
  String disputeTakenMinutesAgo(int count);

  /// How long ago the solver took a dispute, in hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Taken 1 hour ago} other{Taken {count} hours ago}}'**
  String disputeTakenHoursAgo(int count);

  /// How long ago the solver took a dispute, in days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Taken 1 day ago} other{Taken {count} days ago}}'**
  String disputeTakenDaysAgo(int count);

  /// A dispute's trade amount in sats; amount is already formatted
  ///
  /// In en, this message translates to:
  /// **'{amount} sats'**
  String disputeAmountSats(String amount);

  /// A dispute's fiat amount; amount is already formatted, code is the currency (EUR)
  ///
  /// In en, this message translates to:
  /// **'{amount} {code}'**
  String disputeAmountFiat(String amount, String code);

  /// A taken dispute whose amount the node did not send
  ///
  /// In en, this message translates to:
  /// **'Amount not known'**
  String get disputeAmountUnknown;

  /// Settings row: whether the node let this key take a dispute
  ///
  /// In en, this message translates to:
  /// **'Solver on this node'**
  String get settingsSolverStatus;

  /// Value of settingsSolverStatus
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get settingsSolverYes;

  /// Value of settingsSolverStatus
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get settingsSolverNo;

  /// Settings row: what the solver key may do on this node
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get settingsPermission;

  /// Permission value: read-only solver (takes and chats, never pays or refunds)
  ///
  /// In en, this message translates to:
  /// **'Mediate only'**
  String get permissionRead;

  /// Permission value: read-write solver
  ///
  /// In en, this message translates to:
  /// **'Mediate, pay and refund'**
  String get permissionReadWrite;

  /// App bar title of the dispute detail
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get disputeDetailTitle;

  /// Segment of the dispute detail with the dispute's data
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get detailSegmentInfo;

  /// Segment of the dispute detail with the chat with the buyer
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get detailSegmentBuyer;

  /// Segment of the dispute detail with the chat with the seller
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get detailSegmentSeller;

  /// Screen-reader label of the Info / Buyer / Seller control
  ///
  /// In en, this message translates to:
  /// **'Dispute sections'**
  String get detailSegmentsLabel;

  /// Data row: the dispute id, copyable
  ///
  /// In en, this message translates to:
  /// **'Dispute ID'**
  String get detailDisputeId;

  /// Data row: the order id, copyable
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get detailOrderId;

  /// Data row: the dispute's status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailStatus;

  /// Data row: who opened the dispute
  ///
  /// In en, this message translates to:
  /// **'Opened by'**
  String get detailOpenedBy;

  /// Data row: when the dispute was opened
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get detailOpenedAt;

  /// Data row: when this solver took the dispute
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get detailTakenAt;

  /// Data row: the order's amount in sats
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get detailAmount;

  /// Data row: the order's fiat amount
  ///
  /// In en, this message translates to:
  /// **'Fiat amount'**
  String get detailFiatAmount;

  /// Data row: the order's payment method
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get detailPaymentMethod;

  /// Data row: the order's premium over the market price
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get detailPremium;

  /// Data row: the node's fee for the order, in sats
  ///
  /// In en, this message translates to:
  /// **'Node fee'**
  String get detailFee;

  /// Data row: whether the order was a buy or a sell order
  ///
  /// In en, this message translates to:
  /// **'Order type'**
  String get detailOrderKind;

  /// Data row: the buyer's trade public key, copyable
  ///
  /// In en, this message translates to:
  /// **'Buyer\'s trade key'**
  String get detailBuyerKey;

  /// Data row: the seller's trade public key, copyable
  ///
  /// In en, this message translates to:
  /// **'Seller\'s trade key'**
  String get detailSellerKey;

  /// Value of the Opened by row: the buyer
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get detailPartyBuyer;

  /// Value of the Opened by row: the seller
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get detailPartySeller;

  /// Value of a data row the node did not send
  ///
  /// In en, this message translates to:
  /// **'Not known'**
  String get detailPartyUnknown;

  /// Value of the Order type row: a buy order
  ///
  /// In en, this message translates to:
  /// **'Buy order'**
  String get detailOrderKindBuy;

  /// Value of the Order type row: a sell order
  ///
  /// In en, this message translates to:
  /// **'Sell order'**
  String get detailOrderKindSell;

  /// Value of the Premium row
  ///
  /// In en, this message translates to:
  /// **'{value} %'**
  String detailPremiumValue(String value);

  /// Shown in the detail when the dispute is no longer held by this solver key
  ///
  /// In en, this message translates to:
  /// **'This dispute is not yours now'**
  String get detailNotYoursTitle;

  /// Explanation under detailNotYoursTitle
  ///
  /// In en, this message translates to:
  /// **'The node reopened it, or it belongs to another key. It is no longer in Your disputes.'**
  String get detailNotYoursBody;

  /// Tablet split view: shown on the right before a dispute is chosen
  ///
  /// In en, this message translates to:
  /// **'Choose a dispute'**
  String get detailSelectTitle;

  /// Explanation under detailSelectTitle
  ///
  /// In en, this message translates to:
  /// **'Its data and the chats with the buyer and the seller show here.'**
  String get detailSelectBody;

  /// Sender label of the solver's own chat message
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatSenderYou;

  /// Sender label of a chat message from the buyer
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get chatSenderBuyer;

  /// Sender label of a chat message from the seller
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get chatSenderSeller;

  /// Empty state title of the chat with the buyer
  ///
  /// In en, this message translates to:
  /// **'No messages with the buyer'**
  String get chatEmptyBuyerTitle;

  /// Empty state title of the chat with the seller
  ///
  /// In en, this message translates to:
  /// **'No messages with the seller'**
  String get chatEmptySellerTitle;

  /// Empty state explanation of a dispute chat
  ///
  /// In en, this message translates to:
  /// **'Only you and this party can read this conversation. The other party does not see it.'**
  String get chatEmptyBody;

  /// Shown instead of a chat when the node did not name the party's trade key
  ///
  /// In en, this message translates to:
  /// **'No chat with this party'**
  String get chatNoPartyKeyTitle;

  /// Explanation under chatNoPartyKeyTitle
  ///
  /// In en, this message translates to:
  /// **'The node\'s answer to the take did not include this party\'s key, so Bosstro cannot reach them.'**
  String get chatNoPartyKeyBody;

  /// Shown in place of the message field when the dispute is over
  ///
  /// In en, this message translates to:
  /// **'This dispute is closed. The chat is read only.'**
  String get chatClosedNote;

  /// Placeholder of the message field in the chat with the buyer
  ///
  /// In en, this message translates to:
  /// **'Write to the buyer'**
  String get chatComposerBuyerHint;

  /// Placeholder of the message field in the chat with the seller
  ///
  /// In en, this message translates to:
  /// **'Write to the seller'**
  String get chatComposerSellerHint;

  /// Tooltip and screen-reader label of the send button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// Status of a solver's message being sent
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get chatSending;

  /// Status of a solver's message no relay took
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get chatNotSent;

  /// Action on a message that was not sent: send it again
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chatRetry;

  /// Shown under the message field when the message is over the limit
  ///
  /// In en, this message translates to:
  /// **'The message is too long. Split it in two.'**
  String get chatErrorTooLong;

  /// Shown under the message field when the dispute closed meanwhile
  ///
  /// In en, this message translates to:
  /// **'This dispute is closed. The chat is read only.'**
  String get chatErrorClosed;

  /// Shown under the message field when the relays are not running
  ///
  /// In en, this message translates to:
  /// **'Not connected to any relay. Check your connection.'**
  String get chatErrorNoRelays;

  /// Shown under the message field when the dispute is no longer held by this key
  ///
  /// In en, this message translates to:
  /// **'This dispute is no longer yours.'**
  String get chatErrorNotYours;

  /// Shown under the message field for any other refusal
  ///
  /// In en, this message translates to:
  /// **'The message could not be sent.'**
  String get chatErrorGeneric;

  /// Screen-reader label of the chat's loading skeleton
  ///
  /// In en, this message translates to:
  /// **'Loading the messages'**
  String get chatLoading;

  /// Screen-reader label of one chat message
  ///
  /// In en, this message translates to:
  /// **'{sender}, {time}: {text}'**
  String chatMessageLabel(String sender, String time, String text);

  /// Screen-reader hint of a row in Your disputes
  ///
  /// In en, this message translates to:
  /// **'Open the dispute'**
  String get openDisputeHint;
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
