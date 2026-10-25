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
  String get navInProgress => 'My disputes';

  @override
  String get navSettings => 'Settings';

  @override
  String get noNodeSelected => 'No node selected';

  @override
  String get pendingTitle => 'Pending disputes';

  @override
  String get pendingEmptyTitle => 'No disputes waiting';

  @override
  String get pendingEmptyBody =>
      'No dispute on this node is waiting for a solver. When a trade opens one, it shows up here for you to take.';

  @override
  String get inProgressTitle => 'Your disputes';

  @override
  String get inProgressEmptyTitle => 'No disputes in progress';

  @override
  String get inProgressEmptyBody =>
      'Disputes you take show up here. If a take got no answer, recover it.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSheetTitle => 'Choose a language';

  @override
  String get languageSystem => 'System language';

  @override
  String languageSystemDetail(String language) {
    return 'Same as your device: $language';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutTagline => 'The app for Mostro dispute solvers';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutLicenseName => 'AGPLv3+';

  @override
  String get aboutLicenseDialogTitle => 'GNU Affero General Public License v3';

  @override
  String get aboutSourceCode => 'Source code';

  @override
  String get aboutOpenSourceLicenses => 'Open-source licenses';

  @override
  String get aboutLinkCopied => 'Couldn\'t open the browser: link copied';

  @override
  String get copied => 'Copied';

  @override
  String get chatKeyCopied =>
      'Chat key copied. It is cleared from the clipboard in 60 seconds.';

  @override
  String get chatCopyHint => 'Copy the message';

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
  String get loginBodyPaste =>
      'Paste the secret key (nsec) whose npub your node operator registered as a solver.';

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
  String get createDone => 'Choose your node';

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

  @override
  String linkOnline(int connected, int total) {
    return 'Online · $connected/$total relays';
  }

  @override
  String get linkConnecting => 'Connecting to relays…';

  @override
  String get linkOffline => 'Offline · no relay answers';

  @override
  String get chooseNodeTitle => 'Choose your node';

  @override
  String get chooseNodeBody =>
      'Pick the Mostro node whose operator registered your key as a solver. You can switch nodes later in Settings.';

  @override
  String get chooseNodeAppBar => 'Node';

  @override
  String get nodeChipTrusted => 'Trusted';

  @override
  String get nodeChipCustom => 'Added by you';

  @override
  String get nodeChipActive => 'Active';

  @override
  String get nodeAddOwn => 'Add your own node';

  @override
  String get nodeInfoTooltip => 'Node info';

  @override
  String nodeSwitched(String name) {
    return 'Now on $name';
  }

  @override
  String get nodeSelectFailed => 'Could not switch to this node. Try again.';

  @override
  String get nodeListFailed =>
      'The node list could not be loaded. Restart the app to try again.';

  @override
  String get addNodeTitle => 'Add a node';

  @override
  String get addNodeBody =>
      'Paste the node\'s public key (npub or hex). Its operator can give it to you.';

  @override
  String get addNodePubkeyLabel => 'Public key';

  @override
  String get addNodeNameLabel => 'Name (optional)';

  @override
  String get addNodeAnswer => 'Add node';

  @override
  String get nodeErrorInvalidPubkey =>
      'Enter a valid public key (npub or 64 hex characters).';

  @override
  String get nodeErrorPrivateKey =>
      'That is a secret key — never share it. Enter the node\'s public key.';

  @override
  String get nodeErrorAlreadyExists => 'This node is already in the list.';

  @override
  String get nodeErrorActive =>
      'This is your active node. Switch to another node before removing it.';

  @override
  String get nodeErrorStorage =>
      'Your nodes could not be saved on this device.';

  @override
  String get nodeErrorGeneric => 'Something went wrong. Try again.';

  @override
  String get removeNodeAction => 'Remove node';

  @override
  String get removeNodeTitle => 'Remove this node?';

  @override
  String get removeNodeBody =>
      'It leaves your list. You can add it again with its public key.';

  @override
  String get removeNodeAnswer => 'Remove node';

  @override
  String get nodeRemoved => 'Node removed';

  @override
  String get nodeInfoTitle => 'Node info';

  @override
  String get nodeInfoUse => 'Use this node';

  @override
  String get nodeInfoGroupNode => 'Node';

  @override
  String get nodeInfoPubkey => 'Public key';

  @override
  String get nodeInfoRegion => 'Region';

  @override
  String get nodeInfoWebsite => 'Website';

  @override
  String get nodeInfoAbout => 'About';

  @override
  String get nodeInfoEmptyTitle => 'No instance info yet';

  @override
  String get nodeInfoEmptyBody =>
      'This node has not published its instance info on your relays, or they have not answered yet. It is asked for again each time you open this screen.';

  @override
  String get nodeInfoRefreshFailed =>
      'The relays did not answer. This is the info last seen.';

  @override
  String get nodeInfoStale =>
      'This info is more than 7 days old and may be out of date.';

  @override
  String nodeInfoUnsupported(int version) {
    return 'This node speaks protocol v$version. Bosstro speaks only v2, so it cannot resolve disputes there.';
  }

  @override
  String get nodeInfoUpdatedNow => 'Updated just now';

  @override
  String nodeInfoUpdatedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count minutes ago',
      one: 'Updated 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count hours ago',
      one: 'Updated 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count days ago',
      one: 'Updated 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get nodeInfoGroupProtocol => 'Protocol';

  @override
  String get nodeInfoProtocolVersion => 'Protocol version';

  @override
  String get nodeInfoTransport => 'Wire transport';

  @override
  String get nodeInfoGroupDaemon => 'Mostro daemon';

  @override
  String get nodeInfoVersion => 'Version';

  @override
  String get nodeInfoCommit => 'Commit';

  @override
  String get nodeInfoMaxOrder => 'Max order';

  @override
  String get nodeInfoMinOrder => 'Min order';

  @override
  String get nodeInfoExpirationHours => 'Order expiration';

  @override
  String get nodeInfoExpirationSeconds => 'Taken order expiration';

  @override
  String get nodeInfoHoldWindow => 'Hold invoice window';

  @override
  String get nodeInfoHoldCltv => 'Hold invoice CLTV delta';

  @override
  String get nodeInfoInvoiceWindow => 'Invoice window';

  @override
  String get nodeInfoMaxOrders => 'Max orders per response';

  @override
  String get nodeInfoFee => 'Fee';

  @override
  String get nodeInfoPow => 'Required PoW';

  @override
  String get nodeInfoPowFirst => 'PoW on first contact';

  @override
  String get nodeInfoBonds => 'Anti-abuse deposits';

  @override
  String get nodeInfoGroupLightning => 'Lightning node';

  @override
  String get nodeInfoAlias => 'Alias';

  @override
  String get nodeInfoLnPubkey => 'Node pubkey';

  @override
  String get nodeInfoLndVersion => 'LND version';

  @override
  String get nodeInfoChains => 'Chains';

  @override
  String get nodeInfoNetworks => 'Networks';

  @override
  String get nodeInfoUri => 'URI';

  @override
  String get nodeInfoGroupFiat => 'Fiat currencies';

  @override
  String get nodeInfoFiatAll => 'All currencies are accepted.';

  @override
  String get nodeInfoUnknown => 'Unknown';

  @override
  String get nodeInfoEnabled => 'Enabled';

  @override
  String get nodeInfoDisabled => 'Disabled';

  @override
  String unitSats(String amount) {
    return '$amount sats';
  }

  @override
  String unitHours(int count) {
    return '$count h';
  }

  @override
  String unitSeconds(int count) {
    return '$count s';
  }

  @override
  String unitBlocks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocks',
      one: '1 block',
    );
    return '$_temp0';
  }

  @override
  String unitBits(int count) {
    return '$count bits';
  }

  @override
  String unitPercent(String value) {
    return '$value %';
  }

  @override
  String get relaysTitle => 'Relays';

  @override
  String get relaysBody =>
      'Bosstro talks to your node through these relays. The relays your node announces are added for you.';

  @override
  String get relayStatusConnected => 'Connected';

  @override
  String get relayStatusConnecting => 'Connecting';

  @override
  String get relayStatusDisconnected => 'Disconnected';

  @override
  String get relayStatusError => 'Refused';

  @override
  String get relaySourceDefault => 'Default';

  @override
  String get relaySourceNode => 'From your node';

  @override
  String get relaySourceUser => 'Added by you';

  @override
  String get relayAdd => 'Add relay';

  @override
  String get addRelayTitle => 'Add a relay';

  @override
  String get addRelayLabel => 'Relay address';

  @override
  String get addRelayAnswer => 'Add relay';

  @override
  String get relayRemoveTooltip => 'Remove relay';

  @override
  String get removeRelayTitle => 'Remove this relay?';

  @override
  String get removeRelayBody =>
      'Bosstro stops using it. A relay your node announced comes back only if you add it yourself.';

  @override
  String get removeRelayAnswer => 'Remove relay';

  @override
  String get relayErrorInvalidUrl =>
      'Enter a relay address that starts with wss://.';

  @override
  String get relayErrorExists => 'This relay is already in the list.';

  @override
  String get relayErrorLast =>
      'This is your last relay. Add another before removing it.';

  @override
  String get relaysNotRunningTitle => 'The relays did not start';

  @override
  String get relaysNotRunningBody =>
      'Bosstro could not open its connection to the relays. Restart the app to try again.';

  @override
  String get settingsGroupNode => 'Node';

  @override
  String get settingsNode => 'Node';

  @override
  String get settingsNodeNone => 'Choose';

  @override
  String get settingsNodeInfo => 'Node info';

  @override
  String get settingsRelays => 'Relays';

  @override
  String settingsRelaysValue(int connected, int total) {
    return '$connected/$total';
  }

  @override
  String get pendingNoNodeTitle => 'Choose your node first';

  @override
  String get pendingNoNodeBody =>
      'Disputes are read from one Mostro node at a time. Pick the node where you are a solver.';

  @override
  String get pendingNoNodeAction => 'Choose node';

  @override
  String get loadingNodes => 'Loading nodes';

  @override
  String get loadingNodeInfo => 'Loading node info';

  @override
  String get loadingRelays => 'Loading relays';

  @override
  String get loadingDisputes => 'Loading disputes';

  @override
  String get pendingLoadErrorTitle => 'Disputes could not be read';

  @override
  String get pendingLoadErrorBody =>
      'Something went wrong reading this node\'s disputes on this phone. Close and reopen Bosstro to try again.';

  @override
  String get disputeStatusInitiated => 'Waiting for a solver';

  @override
  String get disputeStatusInProgress => 'In progress';

  @override
  String get disputeStatusSettled => 'Buyer paid';

  @override
  String get disputeStatusSellerRefunded => 'Seller refunded';

  @override
  String get disputeStatusReleased => 'Released by the seller';

  @override
  String get disputeStatusCooperativelyCanceled => 'Canceled by both parties';

  @override
  String get disputeOpenedByBuyer => 'Opened by the buyer';

  @override
  String get disputeOpenedBySeller => 'Opened by the seller';

  @override
  String get disputeOpenedByUnknown => 'Opener not known';

  @override
  String get disputeOpenedJustNow => 'Opened just now';

  @override
  String disputeOpenedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Opened $count minutes ago',
      one: 'Opened 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Opened $count hours ago',
      one: 'Opened 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Opened $count days ago',
      one: 'Opened 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get disputeOpenedUnknown => 'Open time not known';

  @override
  String disputeRowLabel(String id) {
    return 'Dispute $id';
  }

  @override
  String get close => 'Close';

  @override
  String get takeDisputeHint => 'Take dispute';

  @override
  String get takeDisputeTitle => 'Take this dispute?';

  @override
  String get takeDisputeBody =>
      'You become its solver: the node tells the buyer and the seller, and the dispute moves to Your disputes. Take only a dispute you can see through.';

  @override
  String get takeDisputeAnswer => 'Take dispute';

  @override
  String get takeTakenSnack => 'Dispute taken. It is in Your disputes.';

  @override
  String get recoverAction => 'Recover';

  @override
  String get recoverTitle => 'Recover a dispute';

  @override
  String get recoverNote =>
      'The node does not publish who holds a dispute. So this list shows every dispute in progress on this node that is not among Your disputes on this phone: yours whose answer was lost, and other solvers\'. Recover them one at a time.';

  @override
  String get recoverEmptyTitle => 'Nothing to recover';

  @override
  String get recoverEmptyBody =>
      'No dispute in progress on this node is missing from Your disputes.';

  @override
  String get recoverDisputeHint => 'Recover dispute';

  @override
  String get recoverDisputeTitle => 'Recover this dispute?';

  @override
  String get recoverDisputeBody =>
      'Bosstro asks the node for this dispute again. If it is yours, the node sends its data back. If another solver holds it, the node says no, unless that solver is read-only, like Serbero, and your key can pay the buyer and refund the seller: then the dispute becomes yours (a take-over).';

  @override
  String get recoverDisputeAnswer => 'Recover dispute';

  @override
  String get recoverTakenSnack => 'Dispute recovered. It is in Your disputes.';

  @override
  String get notSolverTitle => 'You are not a solver on this node';

  @override
  String get notSolverBody =>
      'Switch to your node to resolve disputes. If this is your node, send your npub to its operator.';

  @override
  String get switchNodeAction => 'Switch node';

  @override
  String get cannotTakeOverTitle => 'Another solver holds this dispute';

  @override
  String get cannotTakeOverBody =>
      'Only a dispute held by a read-only solver, like Serbero, can be taken over, and only by a solver who can pay the buyer and refund the seller.';

  @override
  String get takeRefusedTitle => 'The node did not give you this dispute';

  @override
  String get takeRefusedBody =>
      'It refused the request. Try again later, or ask the node\'s operator.';

  @override
  String get takeRefusedNotFoundBody =>
      'The node no longer has this dispute\'s order.';

  @override
  String get noAnswerTitle => 'The node did not answer';

  @override
  String get noAnswerBody =>
      'Your request may have reached it all the same, so Bosstro did not send it again. In a moment, look in Your disputes, or ask again from Recover a dispute.';

  @override
  String get takeFailedTitle => 'The request was not sent';

  @override
  String get takeFailedBody =>
      'No relay took it. Check your connection and the relays, then try again.';

  @override
  String get takeAlreadyTakingBody =>
      'A request for this dispute is already waiting for the node\'s answer.';

  @override
  String get takeClosedBody =>
      'This dispute is closed: there is nothing to take.';

  @override
  String get takeUnknownBody =>
      'This dispute is not among this node\'s disputes on this phone.';

  @override
  String get takeProtocolBody =>
      'This node announces another protocol version. Bosstro talks to nodes on protocol 2 only.';

  @override
  String get takeNodeInfoBody =>
      'Bosstro could not read this node\'s settings, so it does not know the proof of work the node asks for. Check the relays and try again.';

  @override
  String get disputeTakenJustNow => 'Taken just now';

  @override
  String disputeTakenMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Taken $count minutes ago',
      one: 'Taken 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Taken $count hours ago',
      one: 'Taken 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Taken $count days ago',
      one: 'Taken 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String disputeAmountSats(String amount) {
    return '$amount sats';
  }

  @override
  String disputeAmountFiat(String amount, String code) {
    return '$amount $code';
  }

  @override
  String get disputeAmountUnknown => 'Amount not known';

  @override
  String get settingsSolverStatus => 'Solver on this node';

  @override
  String get settingsSolverYes => 'Yes';

  @override
  String get settingsSolverNo => 'No';

  @override
  String get settingsPermission => 'Permission';

  @override
  String get permissionRead => 'Mediate only';

  @override
  String get permissionReadWrite => 'Mediate, pay and refund';

  @override
  String get disputeDetailTitle => 'Dispute';

  @override
  String get detailSegmentInfo => 'Info';

  @override
  String get detailSegmentBuyer => 'Buyer';

  @override
  String get detailSegmentSeller => 'Seller';

  @override
  String get detailSegmentsLabel => 'Dispute sections';

  @override
  String get detailDisputeId => 'Dispute ID';

  @override
  String get detailOrderId => 'Order ID';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailOpenedBy => 'Opened by';

  @override
  String get detailOpenedAt => 'Opened';

  @override
  String get detailTakenAt => 'Taken';

  @override
  String get detailAmount => 'Amount';

  @override
  String get detailCurrency => 'Currency';

  @override
  String get detailFactsTitle => 'Dispute information';

  @override
  String get detailFiatAmount => 'Fiat amount';

  @override
  String get detailPaymentMethod => 'Payment method';

  @override
  String get detailPremium => 'Premium';

  @override
  String get detailFee => 'Node fee';

  @override
  String get detailOrderKind => 'Order type';

  @override
  String get detailBuyerKey => 'Buyer\'s trade key';

  @override
  String get detailSellerKey => 'Seller\'s trade key';

  @override
  String get detailPartyBuyer => 'Buyer';

  @override
  String get detailPartySeller => 'Seller';

  @override
  String get detailPartyUnknown => 'Not known';

  @override
  String get detailOrderKindBuy => 'Buy order';

  @override
  String get detailOrderKindSell => 'Sell order';

  @override
  String detailPremiumValue(String value) {
    return '$value %';
  }

  @override
  String get detailNotYoursTitle => 'This dispute is not yours now';

  @override
  String get detailNotYoursBody =>
      'The node reopened it, or it belongs to another key. It is no longer in Your disputes.';

  @override
  String get chatSenderYou => 'You';

  @override
  String get chatSenderBuyer => 'Buyer';

  @override
  String get chatSenderSeller => 'Seller';

  @override
  String get chatEmptyBuyerTitle => 'No messages with the buyer';

  @override
  String get chatEmptySellerTitle => 'No messages with the seller';

  @override
  String get chatEmptyBody =>
      'Only you and this party can read this conversation. The other party does not see it.';

  @override
  String get chatNoPartyKeyTitle => 'No chat with this party';

  @override
  String get chatNoPartyKeyBody =>
      'The node\'s answer to the take did not include this party\'s key, so Bosstro cannot reach them.';

  @override
  String get chatClosedNote => 'This dispute is closed. The chat is read only.';

  @override
  String get chatComposerBuyerHint => 'Write to the buyer';

  @override
  String get chatComposerSellerHint => 'Write to the seller';

  @override
  String get chatSend => 'Send';

  @override
  String get chatSending => 'Sending…';

  @override
  String get chatNotSent => 'Not sent';

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatErrorTooLong => 'The message is too long. Split it in two.';

  @override
  String get chatErrorClosed =>
      'This dispute is closed. The chat is read only.';

  @override
  String get chatErrorNoRelays =>
      'Not connected to any relay. Check your connection.';

  @override
  String get chatErrorNotYours => 'This dispute is no longer yours.';

  @override
  String get chatErrorGeneric => 'The message could not be sent.';

  @override
  String get chatLoading => 'Loading the messages';

  @override
  String chatMessageLabel(String sender, String time, String text) {
    return '$sender, $time: $text';
  }

  @override
  String get openDisputeHint => 'Open the dispute';

  @override
  String get chatAttach => 'Attach a file';

  @override
  String get attachSheetTitle => 'Attach';

  @override
  String get attachSourcePhoto => 'Photo from the gallery';

  @override
  String get attachSourceCamera => 'Take a photo';

  @override
  String get attachSourcePdf => 'PDF document';

  @override
  String get attachSheetNote =>
      'The file is encrypted on this device. Only you and this party can open it. JPEG, PNG or PDF, up to 25 MB.';

  @override
  String get attachConfirmTitle => 'Send this file?';

  @override
  String attachConfirmBuyer(String name, String size) {
    return '$name ($size) goes to the buyer, encrypted. A photo is sent without its location or camera details.';
  }

  @override
  String attachConfirmSeller(String name, String size) {
    return '$name ($size) goes to the seller, encrypted. A photo is sent without its location or camera details.';
  }

  @override
  String get attachmentTooLarge => 'The file is over 25 MB.';

  @override
  String get attachmentUnsupported =>
      'Only JPEG and PNG images and PDF documents can be sent.';

  @override
  String get attachmentInvalidImage => 'The image could not be read.';

  @override
  String get attachmentReadFailed => 'The file could not be read.';

  @override
  String get attachmentUploadFailed =>
      'The file could not be uploaded. Check your connection and try again.';

  @override
  String get attachmentSendFailed => 'The file could not be sent.';

  @override
  String get attachmentUploading => 'Encrypting and sending…';

  @override
  String get attachmentDiscard => 'Discard';

  @override
  String get attachmentLoading => 'Decrypting the file';

  @override
  String get attachmentNotVerified => 'The file could not be verified.';

  @override
  String get attachmentDownloadFailed => 'The file could not be downloaded.';

  @override
  String get attachmentUnsupportedReceived =>
      'This type of file cannot be opened here.';

  @override
  String get attachmentOpenFailed => 'The file could not be opened.';

  @override
  String attachmentImageLabel(String name) {
    return 'Image $name';
  }

  @override
  String get attachmentOpenImage => 'Open the image';

  @override
  String get attachmentSave => 'Save';

  @override
  String get attachmentSaveHint => 'Save the file';

  @override
  String get attachmentSaved => 'Saved';

  @override
  String get attachmentSaveFailed => 'The file could not be saved.';

  @override
  String attachmentFileLabel(String name, String details) {
    return '$name, $details';
  }

  @override
  String get attachmentViewerZoomHint => 'Pinch to zoom';

  @override
  String get observerTitle => 'Chat between the parties';

  @override
  String observerSharedByBuyer(String date) {
    return 'The buyer shared their chat key on $date.';
  }

  @override
  String observerSharedBySeller(String date) {
    return 'The seller shared their chat key on $date.';
  }

  @override
  String get observerPastedKey => 'You pasted a chat key for this dispute.';

  @override
  String get observerStoredOnly =>
      'Messages kept from an earlier read. Paste the chat key again to look for new ones.';

  @override
  String get observerNoKey =>
      'Neither party has shared their chat key yet. If one sends it to you another way, paste it here.';

  @override
  String get observerReadAction => 'Read the chat between the parties';

  @override
  String get observerPasteAction => 'Paste a chat key';

  @override
  String get observerRefresh => 'Refresh';

  @override
  String get observerReadOnlyBuyer =>
      'Read only, with the key the buyer shared.';

  @override
  String get observerReadOnlySeller =>
      'Read only, with the key the seller shared.';

  @override
  String get observerReadOnlyBoth =>
      'Read only, with the key both parties shared.';

  @override
  String get observerReadOnlyPasted => 'Read only, with a key you pasted.';

  @override
  String get observerReadOnlyStored =>
      'Read only: messages from an earlier read.';

  @override
  String get observerNoKeyTitle => 'No chat key yet';

  @override
  String get observerOpensNothingTitle =>
      'The key opens no message of this dispute';

  @override
  String observerOpensNothingBody(String date) {
    return 'No message of this dispute\'s buyer or seller since $date opens with it. It may be another trade\'s key, or they did not write in that time.';
  }

  @override
  String get observerReadFailedTitle => 'The relays could not be asked';

  @override
  String get observerReadFailedBody => 'Check the connection and try again.';

  @override
  String get observerNoPartyKeysTitle => 'The parties are not known';

  @override
  String get observerNoPartyKeysBody =>
      'The node did not name the trade keys of the buyer and the seller, so no message can be shown as theirs.';

  @override
  String get observerPasteTitle => 'Paste a chat key';

  @override
  String get observerPasteBody =>
      'A party can send you the key of their chat with the other party. With it you read that chat; you can never write in it.';

  @override
  String get observerPasteHint => '64 hexadecimal characters';

  @override
  String get observerPasteConfirm => 'Read the chat';

  @override
  String get observerInvalidKey =>
      'That is not a chat key: it is 64 hexadecimal characters, alone or after “Shared key: ”.';

  @override
  String observerOpensNothingShort(String date) {
    return 'The key opens no message of this dispute since $date.';
  }

  @override
  String get observerNotYours =>
      'This dispute is no longer yours on this node.';

  @override
  String get observerFileLocked => 'It cannot be opened with a chat key.';

  @override
  String get observerFileAdviceBuyer =>
      'Ask the buyer to send it to you in your chat with them.';

  @override
  String get observerFileAdviceSeller =>
      'Ask the seller to send it to you in your chat with them.';

  @override
  String get observerFileImage => 'Image';

  @override
  String get observerFileOther => 'File';

  @override
  String get resolveCardTitle => 'Resolve the dispute';

  @override
  String get resolveCardBody =>
      'Once you have heard both parties, decide where the sats go. It cannot be undone.';

  @override
  String get payBuyerAction => 'Pay the buyer';

  @override
  String get refundSellerAction => 'Refund the seller';

  @override
  String get payBuyerAnswer => 'Pay the buyer';

  @override
  String get refundSellerAnswer => 'Refund the seller';

  @override
  String get resolveReadOnlyNote =>
      'Your solver key can mediate on this node but not pay or refund. Ask the operator for read-write permission.';

  @override
  String get resolveUnansweredPayNote =>
      'Your request to pay the buyer got no answer. The node may have paid all the same: check the dispute\'s status before you try again.';

  @override
  String get resolveUnansweredRefundNote =>
      'Your request to refund the seller got no answer. The node may have refunded all the same: check the dispute\'s status before you try again.';

  @override
  String get payBuyerTitle => 'Pay the buyer?';

  @override
  String get refundSellerTitle => 'Refund the seller?';

  @override
  String get payBuyerRecipient => 'The buyer receives';

  @override
  String get refundSellerRecipient => 'The seller gets back';

  @override
  String payBuyerBreakdown(String amount, String fee) {
    return 'The order\'s $amount less the node\'s fee of $fee.';
  }

  @override
  String refundSellerBreakdown(String amount, String fee) {
    return 'The order\'s $amount plus the node\'s fee of $fee, as the seller locked them.';
  }

  @override
  String resolveTradeFiat(String fiat) {
    return 'Trade: $fiat';
  }

  @override
  String get payBuyerOtherSide =>
      'The seller\'s hold invoice is settled: the seller does not get these sats back.';

  @override
  String get refundSellerOtherSide =>
      'The seller\'s hold invoice is canceled: the buyer receives nothing from this trade.';

  @override
  String get resolveBondsUnknown =>
      'Bosstro does not know whether this node uses deposits: its info could not be read or does not say. If there are any, none is slashed.';

  @override
  String get resolveIrreversible =>
      'This cannot be undone. Once sent, Bosstro never sends it again by itself.';

  @override
  String get resolveWaiting =>
      'Waiting for the node\'s answer. Keep Bosstro open.';

  @override
  String get resolvedPaidTitle => 'Resolved: you paid the buyer';

  @override
  String get resolvedPaidBody =>
      'The node settled the seller\'s hold invoice and pays the buyer. The dispute is closed.';

  @override
  String get resolvedRefundedTitle => 'Resolved: you refunded the seller';

  @override
  String get resolvedRefundedBody =>
      'The node canceled the seller\'s hold invoice: the sats go back to the seller. The dispute is closed.';

  @override
  String get resolvedCoopTitle => 'The parties had already canceled';

  @override
  String get resolvedCoopBody =>
      'Buyer and seller canceled the trade between them before your request, so nothing was paid or refunded by you. The dispute is closed.';

  @override
  String get readOnlySolverTitle => 'You cannot pay or refund on this node';

  @override
  String get takenOverTitle => 'Another solver holds this dispute now';

  @override
  String get takenOverBody =>
      'The node gave it to another solver, so nothing was paid or refunded. It has left Your disputes.';

  @override
  String get notInDisputeTitle => 'This order is no longer in dispute';

  @override
  String get notInDisputeBody =>
      'It was paid, refunded or released already, perhaps by an earlier request whose answer was lost. The dispute\'s status will say how it ended.';

  @override
  String get resolveRefusedTitle => 'The node refused the request';

  @override
  String get resolveRefusedBody =>
      'Nothing was paid or refunded. Try again later, or ask the node\'s operator.';

  @override
  String get resolveNoAnswerBody =>
      'It may have acted all the same: the sats may have moved. Bosstro did not send the request again. Check the dispute\'s status before you try again; it changes as soon as the node publishes it.';

  @override
  String get resolveClosedBody =>
      'This dispute is closed: there is nothing to resolve.';

  @override
  String get resolveNoOrderBody =>
      'Bosstro does not know this dispute\'s order, and the request needs it. Recover the dispute to read it again.';

  @override
  String get resolveBackToDispute => 'Back to the dispute';

  @override
  String get resolveGoToDisputes => 'Go to Your disputes';

  @override
  String get closedPaidBuyer => 'You paid the buyer';

  @override
  String get closedRefundedSeller => 'You refunded the seller';

  @override
  String get closedCooperatively =>
      'The parties canceled it before your decision';

  @override
  String get detailResult => 'Result';

  @override
  String get bondsTitle => 'Deposits';

  @override
  String get bondsPickerHint =>
      'This node uses anti-abuse deposits. Choose whose is slashed, if anyone\'s. It goes in the same request.';

  @override
  String get bondNoSlash => 'Don\'t slash';

  @override
  String get bondNoSlashDetail => 'Every deposit goes back to its owner.';

  @override
  String get bondSlashBuyer => 'Slash the buyer';

  @override
  String get bondSlashBuyerDetail =>
      'The buyer loses their deposit; the seller can claim their share.';

  @override
  String get bondSlashSeller => 'Slash the seller';

  @override
  String get bondSlashSellerDetail =>
      'The seller loses their deposit; the buyer can claim their share.';

  @override
  String get bondSlashBoth => 'Slash both';

  @override
  String get bondSlashBothDetail => 'Both lose their deposit.';

  @override
  String get bondNotPostedTitle => 'That party posted no deposit';

  @override
  String get bondNotPostedBody =>
      'The node has no deposit from the party you chose to slash, so nothing was paid or refunded. Choose another deposit option.';

  @override
  String get bondChooseAgain => 'Choose another option';

  @override
  String get resolvedSlashedBuyer => 'The buyer\'s deposit was slashed.';

  @override
  String get resolvedSlashedSeller => 'The seller\'s deposit was slashed.';

  @override
  String get resolvedSlashedBoth => 'Both deposits were slashed.';

  @override
  String get detailBonds => 'Deposits';

  @override
  String get detailPreviousStatus => 'Status before the dispute';

  @override
  String get orderStatusActive => 'Active';

  @override
  String get orderStatusFiatSent => 'Fiat sent';

  @override
  String get myDisputesOpenSegment => 'In progress';

  @override
  String get myDisputesClosedSegment => 'Closed';

  @override
  String get myDisputesSegmentsLabel => 'Open or closed disputes';

  @override
  String get closedEmptyTitle => 'No closed disputes yet';

  @override
  String get closedEmptyBody =>
      'The disputes you take show up here once they close, whether you resolved them or the parties ended the trade themselves.';

  @override
  String get disputeClosedJustNow => 'Closed just now';

  @override
  String disputeClosedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Closed $count minutes ago',
      one: 'Closed 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String disputeClosedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Closed $count hours ago',
      one: 'Closed 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String disputeClosedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Closed $count days ago',
      one: 'Closed 1 day ago',
    );
    return '$_temp0';
  }
}
