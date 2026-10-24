// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appName => 'Bosstro';

  @override
  String get navPending => 'Openstaand';

  @override
  String get navInProgress => 'Lopend';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get noNodeSelected => 'Geen node gekozen';

  @override
  String get pendingTitle => 'Openstaande disputen';

  @override
  String get pendingEmptyTitle => 'Geen wachtende disputen';

  @override
  String get pendingEmptyBody =>
      'Geen enkel dispuut op deze node wacht op een solver. Wordt er in een trade een dispuut geopend, dan verschijnt het hier zodat je het kunt oppakken.';

  @override
  String get inProgressTitle => 'Jouw disputen';

  @override
  String get inProgressEmptyTitle => 'Geen lopende disputen';

  @override
  String get inProgressEmptyBody =>
      'Disputen die je oppakt, verschijnen hier. Kwam er geen antwoord op het oppakken, haal het dispuut dan terug.';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get languageSheetTitle => 'Taal kiezen';

  @override
  String get languageSystem => 'Systeemtaal';

  @override
  String languageSystemDetail(String language) {
    return 'Taal van je apparaat: $language';
  }

  @override
  String get copied => 'Gekopieerd';

  @override
  String get chatKeyCopied =>
      'Chatsleutel gekopieerd. Na 60 seconden wordt hij van het klembord gewist.';

  @override
  String get chatCopyHint => 'Bericht kopiëren';

  @override
  String get idLabel => 'ID';

  @override
  String get copyIdHint => 'ID kopiëren';

  @override
  String get easterEggWhitepaper =>
      '31 oktober 2008: negen pagina’s, niemands toestemming. Fijne Halloween.';

  @override
  String get easterEggGenesis =>
      'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks';

  @override
  String get easterEggPizzaDay =>
      '22 mei 2010: 10.000 BTC voor twee pizza’s. Hopelijk waren ze lekker.';

  @override
  String get welcomeTitle => 'Los Mostro-disputen op';

  @override
  String get welcomeBody =>
      'Pak de disputen van een node op, praat met de koper en de verkoper en sluit ze af, vanaf je telefoon.';

  @override
  String get welcomeLogIn => 'Inloggen';

  @override
  String get welcomeCreateAccount => 'Nieuw account aanmaken';

  @override
  String get welcomeKeyUnreadable =>
      'De opgeslagen sleutel kon op deze telefoon niet worden gelezen. Log opnieuw in met je geheime sleutel. Log je in met een andere sleutel, dan vervangt die de opgeslagen sleutel.';

  @override
  String get traderKeyWarning =>
      'Gebruik nooit de sleutel waarmee je handelt. Een solversleutel die ook een handelssleutel is, koppelt beide rollen publiekelijk aan elkaar.';

  @override
  String get loginTitle => 'Inloggen';

  @override
  String get loginHeading => 'Je geheime solversleutel';

  @override
  String get loginBody =>
      'Plak of scan de geheime sleutel (nsec) waarvan je node-beheerder de npub als solver heeft geregistreerd.';

  @override
  String get loginBodyPaste =>
      'Plak de geheime sleutel (nsec) waarvan je node-beheerder de npub als solver heeft geregistreerd.';

  @override
  String get secretKeyHint => 'nsec1…';

  @override
  String get showSecretKey => 'Sleutel tonen';

  @override
  String get hideSecretKey => 'Sleutel verbergen';

  @override
  String get pasteAction => 'Plakken';

  @override
  String get scanQrAction => 'QR scannen';

  @override
  String get clipboardEmpty => 'Het klembord is leeg.';

  @override
  String get loginContinue => 'Doorgaan';

  @override
  String get keyErrorEmpty => 'Vul je geheime sleutel in.';

  @override
  String get keyErrorPublicKey =>
      'Dat is een publieke sleutel (npub). Om in te loggen heb je de geheime sleutel (nsec) nodig.';

  @override
  String get keyErrorInvalid =>
      'Dit is geen geldige geheime sleutel. Vul een nsec1…-sleutel in of de hexvorm van 64 tekens.';

  @override
  String get loginConfirmHeading =>
      'Is dit de npub die als solver is geregistreerd?';

  @override
  String get loginConfirmBody =>
      'Vergelijk hem met de npub die je node-beheerder heeft toegevoegd. Komt hij niet overeen, dan kan deze sleutel op die node geen disputen oplossen.';

  @override
  String get loginConfirmAnswer => 'Ja, inloggen';

  @override
  String get loginConfirmBack => 'Nee, andere sleutel gebruiken';

  @override
  String get keySaveFailed =>
      'De sleutel kon niet op deze telefoon worden opgeslagen. Probeer het opnieuw.';

  @override
  String get npubLabel => 'npub';

  @override
  String get secretKeyLabel => 'Geheime sleutel (nsec)';

  @override
  String get copyNpub => 'npub kopiëren';

  @override
  String get copySecretKey => 'Geheime sleutel kopiëren';

  @override
  String get shareNpub => 'npub delen';

  @override
  String get npubQrLabel => 'QR-code van je npub';

  @override
  String get scanTitle => 'QR scannen';

  @override
  String get scanHint =>
      'Richt de camera op de QR-code van je geheime sleutel.';

  @override
  String get scanUnavailable =>
      'De camera is niet beschikbaar. Ga terug en plak de sleutel.';

  @override
  String get createTitle => 'Nieuw account aanmaken';

  @override
  String get createKeyHeading => 'Je nieuwe geheime sleutel';

  @override
  String get createKeyBody =>
      'Het is de enige manier om in te loggen op dit account. Schrijf hem op en bewaar hem op een veilige, privé plek: wie hem heeft, kan in jouw naam disputen oplossen.';

  @override
  String get createBackupConfirm =>
      'Ik heb mijn geheime sleutel veilig bewaard';

  @override
  String get createContinue => 'Doorgaan';

  @override
  String get createNpubHeading => 'Je npub';

  @override
  String get createNpubBody =>
      'Stuur deze npub naar je node-beheerder, zodat die je als solver registreert. Tot dan kun je de disputen zien, maar niet oppakken.';

  @override
  String get createDone => 'Kies je node';

  @override
  String get settingsGroupKey => 'Solversleutel';

  @override
  String get settingsNpub => 'Je npub';

  @override
  String get settingsBackup => 'Back-up van geheime sleutel';

  @override
  String get settingsLogOut => 'Uitloggen';

  @override
  String get backupWarnTitle => 'Je geheime sleutel tonen?';

  @override
  String get backupWarnBody =>
      'Wie hem ziet, kan in jouw naam disputen oplossen. Zorg dat niemand op je scherm meekijkt.';

  @override
  String get backupWarnAnswer => 'Geheime sleutel tonen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get backupTitle => 'Back-up van geheime sleutel';

  @override
  String get backupBody =>
      'Bewaar hem op een veilige, privé plek. Het is de enige manier om op een andere telefoon in te loggen op dit account.';

  @override
  String get backupUnavailable =>
      'De geheime sleutel kon op deze telefoon niet worden gelezen.';

  @override
  String get logOutTitle => 'Uitloggen?';

  @override
  String get logOutBody =>
      'Je geheime sleutel wordt van deze telefoon verwijderd. Zonder back-up kun je niet meer inloggen op dit account.';

  @override
  String get logOutAnswer => 'Uitloggen';

  @override
  String get logOutFailed => 'Uitloggen is mislukt. Probeer het opnieuw.';

  @override
  String get secretKeyCopied =>
      'Geheime sleutel gekopieerd. Na 60 seconden wordt hij van het klembord gewist.';

  @override
  String linkOnline(int connected, int total) {
    return 'Online · $connected/$total relays';
  }

  @override
  String get linkConnecting => 'Verbinden met relays…';

  @override
  String get linkOffline => 'Offline · geen relay reageert';

  @override
  String get chooseNodeTitle => 'Kies je node';

  @override
  String get chooseNodeBody =>
      'Kies de Mostro-node waarvan de beheerder je sleutel als solver heeft geregistreerd. Je kunt later in Instellingen van node wisselen.';

  @override
  String get chooseNodeAppBar => 'Node';

  @override
  String get nodeChipTrusted => 'Vertrouwd';

  @override
  String get nodeChipCustom => 'Door jou toegevoegd';

  @override
  String get nodeChipActive => 'Actief';

  @override
  String get nodeAddOwn => 'Je eigen node toevoegen';

  @override
  String get nodeInfoTooltip => 'Nodegegevens';

  @override
  String nodeSwitched(String name) {
    return 'Je gebruikt nu $name';
  }

  @override
  String get nodeSelectFailed =>
      'Overschakelen naar deze node is mislukt. Probeer het opnieuw.';

  @override
  String get nodeListFailed =>
      'De lijst met nodes kon niet worden geladen. Herstart de app om het opnieuw te proberen.';

  @override
  String get addNodeTitle => 'Node toevoegen';

  @override
  String get addNodeBody =>
      'Plak de publieke sleutel van de node (npub of hex). De beheerder kan hem je geven.';

  @override
  String get addNodePubkeyLabel => 'Publieke sleutel';

  @override
  String get addNodeNameLabel => 'Naam (optioneel)';

  @override
  String get addNodeAnswer => 'Node toevoegen';

  @override
  String get nodeErrorInvalidPubkey =>
      'Vul een geldige publieke sleutel in (npub of 64 tekens hex).';

  @override
  String get nodeErrorPrivateKey =>
      'Dat is een geheime sleutel. Deel die nooit; vul de publieke sleutel van de node in.';

  @override
  String get nodeErrorAlreadyExists => 'Deze node staat al in de lijst.';

  @override
  String get nodeErrorActive =>
      'Dit is je actieve node. Schakel over naar een andere node voordat je hem verwijdert.';

  @override
  String get nodeErrorStorage =>
      'Je nodes konden niet op dit apparaat worden opgeslagen.';

  @override
  String get nodeErrorGeneric => 'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get removeNodeAction => 'Node verwijderen';

  @override
  String get removeNodeTitle => 'Deze node verwijderen?';

  @override
  String get removeNodeBody =>
      'Hij verdwijnt uit je lijst. Je kunt hem opnieuw toevoegen met zijn publieke sleutel.';

  @override
  String get removeNodeAnswer => 'Node verwijderen';

  @override
  String get nodeRemoved => 'Node verwijderd';

  @override
  String get nodeInfoTitle => 'Nodegegevens';

  @override
  String get nodeInfoUse => 'Deze node gebruiken';

  @override
  String get nodeInfoGroupNode => 'Node';

  @override
  String get nodeInfoPubkey => 'Publieke sleutel';

  @override
  String get nodeInfoRegion => 'Regio';

  @override
  String get nodeInfoWebsite => 'Website';

  @override
  String get nodeInfoAbout => 'Beschrijving';

  @override
  String get nodeInfoEmptyTitle => 'Nog geen instantiegegevens';

  @override
  String get nodeInfoEmptyBody =>
      'Deze node heeft zijn instantiegegevens niet op je relays gepubliceerd, of die hebben nog niet gereageerd. Ze worden opnieuw opgevraagd telkens als je dit scherm opent.';

  @override
  String get nodeInfoRefreshFailed =>
      'De relays reageerden niet. Dit zijn de laatst geziene gegevens.';

  @override
  String get nodeInfoStale =>
      'Deze gegevens zijn meer dan 7 dagen oud en kunnen verouderd zijn.';

  @override
  String nodeInfoUnsupported(int version) {
    return 'Deze node spreekt protocol v$version. Bosstro spreekt alleen v2 en kan daar dus geen disputen oplossen.';
  }

  @override
  String get nodeInfoUpdatedNow => 'Zojuist bijgewerkt';

  @override
  String nodeInfoUpdatedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten geleden bijgewerkt',
      one: '1 minuut geleden bijgewerkt',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden bijgewerkt',
      one: '1 uur geleden bijgewerkt',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden bijgewerkt',
      one: '1 dag geleden bijgewerkt',
    );
    return '$_temp0';
  }

  @override
  String get nodeInfoGroupProtocol => 'Protocol';

  @override
  String get nodeInfoProtocolVersion => 'Protocolversie';

  @override
  String get nodeInfoTransport => 'Transport';

  @override
  String get nodeInfoGroupDaemon => 'Mostro-daemon';

  @override
  String get nodeInfoVersion => 'Versie';

  @override
  String get nodeInfoCommit => 'Commit';

  @override
  String get nodeInfoMaxOrder => 'Maximale order';

  @override
  String get nodeInfoMinOrder => 'Minimale order';

  @override
  String get nodeInfoExpirationHours => 'Vervaltijd van orders';

  @override
  String get nodeInfoExpirationSeconds => 'Vervaltijd van geaccepteerde orders';

  @override
  String get nodeInfoHoldWindow => 'Tijd om sats vast te zetten';

  @override
  String get nodeInfoHoldCltv => 'CLTV bij vastzetten';

  @override
  String get nodeInfoInvoiceWindow => 'Geldigheidsduur invoice';

  @override
  String get nodeInfoMaxOrders => 'Maximaal aantal orders per antwoord';

  @override
  String get nodeInfoFee => 'Kosten';

  @override
  String get nodeInfoPow => 'Vereiste PoW';

  @override
  String get nodeInfoPowFirst => 'PoW bij eerste contact';

  @override
  String get nodeInfoBonds => 'Borg tegen misbruik';

  @override
  String get nodeInfoGroupLightning => 'Lightning-node';

  @override
  String get nodeInfoAlias => 'Alias';

  @override
  String get nodeInfoLnPubkey => 'Publieke sleutel van de node';

  @override
  String get nodeInfoLndVersion => 'LND-versie';

  @override
  String get nodeInfoChains => 'Chains';

  @override
  String get nodeInfoNetworks => 'Netwerken';

  @override
  String get nodeInfoUri => 'URI';

  @override
  String get nodeInfoGroupFiat => 'Fiatvaluta';

  @override
  String get nodeInfoFiatAll => 'Alle valuta worden geaccepteerd.';

  @override
  String get nodeInfoUnknown => 'Onbekend';

  @override
  String get nodeInfoEnabled => 'Aan';

  @override
  String get nodeInfoDisabled => 'Uit';

  @override
  String unitSats(String amount) {
    return '$amount sats';
  }

  @override
  String unitHours(int count) {
    return '$count u';
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
      other: '$count blokken',
      one: '1 blok',
    );
    return '$_temp0';
  }

  @override
  String unitBits(int count) {
    return '$count bits';
  }

  @override
  String unitPercent(String value) {
    return '$value%';
  }

  @override
  String get relaysTitle => 'Relays';

  @override
  String get relaysBody =>
      'Bosstro praat via deze relays met je node. De relays die je node aankondigt, worden automatisch voor je toegevoegd.';

  @override
  String get relayStatusConnected => 'Verbonden';

  @override
  String get relayStatusConnecting => 'Verbinden';

  @override
  String get relayStatusDisconnected => 'Niet verbonden';

  @override
  String get relayStatusError => 'Geweigerd';

  @override
  String get relaySourceDefault => 'Standaard';

  @override
  String get relaySourceNode => 'Van je node';

  @override
  String get relaySourceUser => 'Door jou toegevoegd';

  @override
  String get relayAdd => 'Relay toevoegen';

  @override
  String get addRelayTitle => 'Relay toevoegen';

  @override
  String get addRelayLabel => 'Relay-adres';

  @override
  String get addRelayAnswer => 'Relay toevoegen';

  @override
  String get relayRemoveTooltip => 'Relay verwijderen';

  @override
  String get removeRelayTitle => 'Deze relay verwijderen?';

  @override
  String get removeRelayBody =>
      'Bosstro gebruikt hem niet meer. Een relay die je node aankondigde, komt alleen terug als je hem zelf toevoegt.';

  @override
  String get removeRelayAnswer => 'Relay verwijderen';

  @override
  String get relayErrorInvalidUrl =>
      'Vul een relay-adres in dat met wss:// begint.';

  @override
  String get relayErrorExists => 'Deze relay staat al in de lijst.';

  @override
  String get relayErrorLast =>
      'Dit is je laatste relay. Voeg een andere toe voordat je hem verwijdert.';

  @override
  String get relaysNotRunningTitle => 'De relays zijn niet gestart';

  @override
  String get relaysNotRunningBody =>
      'Bosstro kon geen verbinding met de relays openen. Herstart de app om het opnieuw te proberen.';

  @override
  String get settingsGroupNode => 'Node';

  @override
  String get settingsNode => 'Node';

  @override
  String get settingsNodeNone => 'Kiezen';

  @override
  String get settingsNodeInfo => 'Nodegegevens';

  @override
  String get settingsRelays => 'Relays';

  @override
  String settingsRelaysValue(int connected, int total) {
    return '$connected/$total';
  }

  @override
  String get pendingNoNodeTitle => 'Kies eerst je node';

  @override
  String get pendingNoNodeBody =>
      'Disputen worden van één Mostro-node tegelijk gelezen. Kies de node waar je solver bent.';

  @override
  String get pendingNoNodeAction => 'Node kiezen';

  @override
  String get loadingNodes => 'Nodes laden';

  @override
  String get loadingNodeInfo => 'Nodegegevens laden';

  @override
  String get loadingRelays => 'Relays laden';

  @override
  String get loadingDisputes => 'Disputen laden';

  @override
  String get pendingLoadErrorTitle => 'De disputen konden niet worden gelezen';

  @override
  String get pendingLoadErrorBody =>
      'Er ging iets mis bij het lezen van de disputen van deze node op deze telefoon. Sluit Bosstro en open het opnieuw om het nog eens te proberen.';

  @override
  String get disputeStatusInitiated => 'Wacht op een solver';

  @override
  String get disputeStatusInProgress => 'Lopend';

  @override
  String get disputeStatusSettled => 'Koper betaald';

  @override
  String get disputeStatusSellerRefunded => 'Verkoper terugbetaald';

  @override
  String get disputeStatusReleased => 'Vrijgegeven door verkoper';

  @override
  String get disputeStatusCooperativelyCanceled =>
      'Door beide partijen geannuleerd';

  @override
  String get disputeOpenedByBuyer => 'Geopend door de koper';

  @override
  String get disputeOpenedBySeller => 'Geopend door de verkoper';

  @override
  String get disputeOpenedByUnknown => 'Onbekend wie het opende';

  @override
  String get disputeOpenedJustNow => 'Zojuist geopend';

  @override
  String disputeOpenedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten geleden geopend',
      one: '1 minuut geleden geopend',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden geopend',
      one: '1 uur geleden geopend',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden geopend',
      one: '1 dag geleden geopend',
    );
    return '$_temp0';
  }

  @override
  String get disputeOpenedUnknown => 'Openingstijd onbekend';

  @override
  String disputeRowLabel(String id) {
    return 'Dispuut $id';
  }

  @override
  String get close => 'Sluiten';

  @override
  String get takeDisputeHint => 'Dispuut oppakken';

  @override
  String get takeDisputeTitle => 'Dit dispuut oppakken?';

  @override
  String get takeDisputeBody =>
      'Je wordt er de solver van: de node laat het de koper en de verkoper weten, en het dispuut gaat naar Jouw disputen. Pak alleen een dispuut op dat je tot het einde kunt afhandelen.';

  @override
  String get takeDisputeAnswer => 'Dispuut oppakken';

  @override
  String get takeTakenSnack => 'Dispuut opgepakt. Het staat in Jouw disputen.';

  @override
  String get recoverAction => 'Terughalen';

  @override
  String get recoverTitle => 'Dispuut terughalen';

  @override
  String get recoverNote =>
      'De node publiceert niet wie een dispuut in handen heeft. Daarom toont deze lijst elk lopend dispuut op deze node dat op deze telefoon niet bij Jouw disputen staat: die van jou waarvan het antwoord verloren ging, en die van andere solvers. Haal ze één voor één terug.';

  @override
  String get recoverEmptyTitle => 'Niets om terug te halen';

  @override
  String get recoverEmptyBody =>
      'Er ontbreekt geen enkel lopend dispuut van deze node in Jouw disputen.';

  @override
  String get recoverDisputeHint => 'Dispuut terughalen';

  @override
  String get recoverDisputeTitle => 'Dit dispuut terughalen?';

  @override
  String get recoverDisputeBody =>
      'Bosstro vraagt de node opnieuw om dit dispuut. Is het van jou, dan stuurt de node de gegevens ervan terug. Heeft een andere solver het, dan weigert de node, tenzij die solver alleen leesrecht heeft, zoals Serbero, en jouw sleutel de koper kan betalen en de verkoper kan terugbetalen: dan wordt het dispuut van jou (een overname).';

  @override
  String get recoverDisputeAnswer => 'Dispuut terughalen';

  @override
  String get recoverTakenSnack =>
      'Dispuut teruggehaald. Het staat in Jouw disputen.';

  @override
  String get notSolverTitle => 'Je bent geen solver op deze node';

  @override
  String get notSolverBody =>
      'Schakel over naar je node om disputen op te lossen. Is dit je node, stuur dan je npub naar de beheerder.';

  @override
  String get switchNodeAction => 'Van node wisselen';

  @override
  String get cannotTakeOverTitle => 'Een andere solver heeft dit dispuut';

  @override
  String get cannotTakeOverBody =>
      'Alleen een dispuut in handen van een solver met enkel leesrecht, zoals Serbero, kan worden overgenomen, en dan alleen door een solver die de koper kan betalen en de verkoper kan terugbetalen.';

  @override
  String get takeRefusedTitle => 'De node heeft je dit dispuut niet gegeven';

  @override
  String get takeRefusedBody =>
      'De node heeft het verzoek geweigerd. Probeer het later opnieuw, of vraag het de beheerder van de node.';

  @override
  String get takeRefusedNotFoundBody =>
      'De node heeft de order van dit dispuut niet meer.';

  @override
  String get noAnswerTitle => 'De node heeft niet geantwoord';

  @override
  String get noAnswerBody =>
      'Je verzoek kan de node toch hebben bereikt, dus Bosstro heeft het niet opnieuw verstuurd. Kijk zo meteen in Jouw disputen, of vraag het opnieuw aan via Dispuut terughalen.';

  @override
  String get takeFailedTitle => 'Het verzoek is niet verstuurd';

  @override
  String get takeFailedBody =>
      'Geen enkele relay heeft het geaccepteerd. Controleer je verbinding en de relays en probeer het opnieuw.';

  @override
  String get takeAlreadyTakingBody =>
      'Er wacht al een verzoek voor dit dispuut op het antwoord van de node.';

  @override
  String get takeClosedBody =>
      'Dit dispuut is gesloten: er valt niets op te pakken.';

  @override
  String get takeUnknownBody =>
      'Dit dispuut staat op deze telefoon niet tussen de disputen van deze node.';

  @override
  String get takeProtocolBody =>
      'Deze node kondigt een andere protocolversie aan. Bosstro praat alleen met nodes op protocol 2.';

  @override
  String get takeNodeInfoBody =>
      'Bosstro kon de instellingen van deze node niet lezen en weet dus niet welke proof of work de node vraagt. Controleer de relays en probeer het opnieuw.';

  @override
  String get disputeTakenJustNow => 'Zojuist opgepakt';

  @override
  String disputeTakenMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten geleden opgepakt',
      one: '1 minuut geleden opgepakt',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden opgepakt',
      one: '1 uur geleden opgepakt',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden opgepakt',
      one: '1 dag geleden opgepakt',
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
  String get disputeAmountUnknown => 'Bedrag onbekend';

  @override
  String get settingsSolverStatus => 'Solver op deze node';

  @override
  String get settingsSolverYes => 'Ja';

  @override
  String get settingsSolverNo => 'Nee';

  @override
  String get settingsPermission => 'Rechten';

  @override
  String get permissionRead => 'Alleen bemiddelen';

  @override
  String get permissionReadWrite => 'Bemiddelen, betalen en terugbetalen';

  @override
  String get disputeDetailTitle => 'Dispuut';

  @override
  String get detailSegmentInfo => 'Info';

  @override
  String get detailSegmentBuyer => 'Koper';

  @override
  String get detailSegmentSeller => 'Verkoper';

  @override
  String get detailSegmentsLabel => 'Onderdelen van het dispuut';

  @override
  String get detailDisputeId => 'Dispuut-ID';

  @override
  String get detailOrderId => 'Order-ID';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailOpenedBy => 'Geopend door';

  @override
  String get detailOpenedAt => 'Geopend';

  @override
  String get detailTakenAt => 'Opgepakt';

  @override
  String get detailAmount => 'Bedrag';

  @override
  String get detailCurrency => 'Valuta';

  @override
  String get detailFactsTitle => 'Dispuut en order';

  @override
  String get detailFiatAmount => 'Fiatbedrag';

  @override
  String get detailPaymentMethod => 'Betaalmethode';

  @override
  String get detailPremium => 'Premie';

  @override
  String get detailFee => 'Nodekosten';

  @override
  String get detailOrderKind => 'Ordertype';

  @override
  String get detailBuyerKey => 'Tradesleutel van de koper';

  @override
  String get detailSellerKey => 'Tradesleutel van de verkoper';

  @override
  String get detailPartyBuyer => 'Koper';

  @override
  String get detailPartySeller => 'Verkoper';

  @override
  String get detailPartyUnknown => 'Onbekend';

  @override
  String get detailOrderKindBuy => 'Kooporder';

  @override
  String get detailOrderKindSell => 'Verkooporder';

  @override
  String detailPremiumValue(String value) {
    return '$value%';
  }

  @override
  String get detailNotYoursTitle => 'Dit dispuut is niet meer van jou';

  @override
  String get detailNotYoursBody =>
      'De node heeft het heropend, of het hoort bij een andere sleutel. Het staat niet meer in Jouw disputen.';

  @override
  String get chatSenderYou => 'Jij';

  @override
  String get chatSenderBuyer => 'Koper';

  @override
  String get chatSenderSeller => 'Verkoper';

  @override
  String get chatEmptyBuyerTitle => 'Geen berichten met de koper';

  @override
  String get chatEmptySellerTitle => 'Geen berichten met de verkoper';

  @override
  String get chatEmptyBody =>
      'Alleen jij en deze partij kunnen dit gesprek lezen. De andere partij ziet het niet.';

  @override
  String get chatNoPartyKeyTitle => 'Geen chat met deze partij';

  @override
  String get chatNoPartyKeyBody =>
      'Het antwoord van de node op het oppakken bevatte de sleutel van deze partij niet, dus Bosstro kan deze partij niet bereiken.';

  @override
  String get chatClosedNote =>
      'Dit dispuut is gesloten. De chat is alleen-lezen.';

  @override
  String get chatComposerBuyerHint => 'Schrijf aan de koper';

  @override
  String get chatComposerSellerHint => 'Schrijf aan de verkoper';

  @override
  String get chatSend => 'Versturen';

  @override
  String get chatSending => 'Versturen…';

  @override
  String get chatNotSent => 'Niet verstuurd';

  @override
  String get chatRetry => 'Opnieuw proberen';

  @override
  String get chatErrorTooLong =>
      'Het bericht is te lang. Splits het in tweeën.';

  @override
  String get chatErrorClosed =>
      'Dit dispuut is gesloten. De chat is alleen-lezen.';

  @override
  String get chatErrorNoRelays =>
      'Met geen enkele relay verbonden. Controleer je verbinding.';

  @override
  String get chatErrorNotYours => 'Dit dispuut is niet meer van jou.';

  @override
  String get chatErrorGeneric => 'Het bericht kon niet worden verstuurd.';

  @override
  String get chatLoading => 'Berichten laden';

  @override
  String chatMessageLabel(String sender, String time, String text) {
    return '$sender, $time: $text';
  }

  @override
  String get openDisputeHint => 'Dispuut openen';

  @override
  String get chatAttach => 'Bestand toevoegen';

  @override
  String get attachSheetTitle => 'Toevoegen';

  @override
  String get attachSourcePhoto => 'Foto uit de galerij';

  @override
  String get attachSourceCamera => 'Foto maken';

  @override
  String get attachSourcePdf => 'PDF-document';

  @override
  String get attachSheetNote =>
      'Het bestand wordt op dit apparaat versleuteld. Alleen jij en deze partij kunnen het openen. JPEG, PNG of PDF, tot 25 MB.';

  @override
  String get attachConfirmTitle => 'Dit bestand versturen?';

  @override
  String attachConfirmBuyer(String name, String size) {
    return '$name ($size) gaat versleuteld naar de koper. Een foto wordt verstuurd zonder locatie of cameragegevens.';
  }

  @override
  String attachConfirmSeller(String name, String size) {
    return '$name ($size) gaat versleuteld naar de verkoper. Een foto wordt verstuurd zonder locatie of cameragegevens.';
  }

  @override
  String get attachmentTooLarge => 'Het bestand is groter dan 25 MB.';

  @override
  String get attachmentUnsupported =>
      'Alleen JPEG- en PNG-afbeeldingen en PDF-documenten kunnen worden verstuurd.';

  @override
  String get attachmentInvalidImage => 'De afbeelding kon niet worden gelezen.';

  @override
  String get attachmentReadFailed => 'Het bestand kon niet worden gelezen.';

  @override
  String get attachmentUploadFailed =>
      'Het bestand kon niet worden geüpload. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get attachmentSendFailed => 'Het bestand kon niet worden verstuurd.';

  @override
  String get attachmentUploading => 'Versleutelen en versturen…';

  @override
  String get attachmentDiscard => 'Verwijderen';

  @override
  String get attachmentLoading => 'Bestand ontsleutelen';

  @override
  String get attachmentNotVerified =>
      'Het bestand kon niet worden geverifieerd.';

  @override
  String get attachmentDownloadFailed =>
      'Het bestand kon niet worden gedownload.';

  @override
  String get attachmentUnsupportedReceived =>
      'Dit type bestand kan hier niet worden geopend.';

  @override
  String get attachmentOpenFailed => 'Het bestand kon niet worden geopend.';

  @override
  String attachmentImageLabel(String name) {
    return 'Afbeelding $name';
  }

  @override
  String get attachmentOpenImage => 'Afbeelding openen';

  @override
  String get attachmentSave => 'Opslaan';

  @override
  String get attachmentSaveHint => 'Bestand opslaan';

  @override
  String get attachmentSaved => 'Opgeslagen';

  @override
  String get attachmentSaveFailed => 'Het bestand kon niet worden opgeslagen.';

  @override
  String attachmentFileLabel(String name, String details) {
    return '$name, $details';
  }

  @override
  String get attachmentViewerZoomHint => 'Knijp om te zoomen';

  @override
  String get observerTitle => 'Chat tussen de partijen';

  @override
  String observerSharedByBuyer(String date) {
    return 'De koper heeft de chatsleutel gedeeld op $date.';
  }

  @override
  String observerSharedBySeller(String date) {
    return 'De verkoper heeft de chatsleutel gedeeld op $date.';
  }

  @override
  String get observerPastedKey =>
      'Je hebt een chatsleutel voor dit dispuut geplakt.';

  @override
  String get observerStoredOnly =>
      'Berichten bewaard uit een eerdere leesbeurt. Plak de chatsleutel opnieuw om naar nieuwe te zoeken.';

  @override
  String get observerNoKey =>
      'Nog geen van beide partijen heeft de chatsleutel gedeeld. Krijg je hem op een andere manier van een van hen, plak hem dan hier.';

  @override
  String get observerReadAction => 'Chat tussen de partijen lezen';

  @override
  String get observerPasteAction => 'Chatsleutel plakken';

  @override
  String get observerRefresh => 'Vernieuwen';

  @override
  String get observerReadOnlyBuyer =>
      'Alleen-lezen, met de sleutel die de koper deelde.';

  @override
  String get observerReadOnlySeller =>
      'Alleen-lezen, met de sleutel die de verkoper deelde.';

  @override
  String get observerReadOnlyBoth =>
      'Alleen-lezen, met de sleutel die beide partijen deelden.';

  @override
  String get observerReadOnlyPasted =>
      'Alleen-lezen, met een sleutel die jij hebt geplakt.';

  @override
  String get observerReadOnlyStored =>
      'Alleen-lezen: berichten uit een eerdere leesbeurt.';

  @override
  String get observerNoKeyTitle => 'Nog geen chatsleutel';

  @override
  String get observerOpensNothingTitle =>
      'De sleutel opent geen bericht van dit dispuut';

  @override
  String observerOpensNothingBody(String date) {
    return 'Geen enkel bericht van de koper of de verkoper van dit dispuut sinds $date gaat ermee open. Het kan de sleutel van een andere trade zijn, of ze hebben in die tijd niet geschreven.';
  }

  @override
  String get observerReadFailedTitle => 'De relays konden niet worden bevraagd';

  @override
  String get observerReadFailedBody =>
      'Controleer de verbinding en probeer het opnieuw.';

  @override
  String get observerNoPartyKeysTitle => 'De partijen zijn niet bekend';

  @override
  String get observerNoPartyKeysBody =>
      'De node heeft de tradesleutels van de koper en de verkoper niet genoemd, dus geen enkel bericht kan als het hunne worden getoond.';

  @override
  String get observerPasteTitle => 'Chatsleutel plakken';

  @override
  String get observerPasteBody =>
      'Een partij kan je de sleutel sturen van haar chat met de andere partij. Daarmee lees je die chat; schrijven kun je er nooit in.';

  @override
  String get observerPasteHint => '64 hexadecimale tekens';

  @override
  String get observerPasteConfirm => 'Chat lezen';

  @override
  String get observerInvalidKey =>
      'Dat is geen chatsleutel: die bestaat uit 64 hexadecimale tekens, los of na ‘Shared key: ’.';

  @override
  String observerOpensNothingShort(String date) {
    return 'De sleutel opent sinds $date geen bericht van dit dispuut.';
  }

  @override
  String get observerNotYours =>
      'Dit dispuut is op deze node niet meer van jou.';

  @override
  String get observerFileLocked =>
      'Het kan niet worden geopend met een chatsleutel.';

  @override
  String get observerFileAdviceBuyer =>
      'Vraag de koper om het je te sturen in jullie chat.';

  @override
  String get observerFileAdviceSeller =>
      'Vraag de verkoper om het je te sturen in jullie chat.';

  @override
  String get observerFileImage => 'Afbeelding';

  @override
  String get observerFileOther => 'Bestand';

  @override
  String get resolveCardTitle => 'Dispuut oplossen';

  @override
  String get resolveCardBody =>
      'Heb je beide partijen gehoord, beslis dan waar de sats naartoe gaan. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get payBuyerAction => 'Koper betalen';

  @override
  String get refundSellerAction => 'Verkoper terugbetalen';

  @override
  String get payBuyerAnswer => 'Koper betalen';

  @override
  String get refundSellerAnswer => 'Verkoper terugbetalen';

  @override
  String get resolveReadOnlyNote =>
      'Je solversleutel kan op deze node bemiddelen, maar niet betalen of terugbetalen. Vraag de beheerder om lees- en schrijfrechten.';

  @override
  String get resolveUnansweredPayNote =>
      'Je verzoek om de koper te betalen kreeg geen antwoord. De node kan toch hebben betaald: controleer de status van het dispuut voordat je het opnieuw probeert.';

  @override
  String get resolveUnansweredRefundNote =>
      'Je verzoek om de verkoper terug te betalen kreeg geen antwoord. De node kan toch hebben terugbetaald: controleer de status van het dispuut voordat je het opnieuw probeert.';

  @override
  String get payBuyerTitle => 'Koper betalen?';

  @override
  String get refundSellerTitle => 'Verkoper terugbetalen?';

  @override
  String get payBuyerRecipient => 'De koper ontvangt';

  @override
  String get refundSellerRecipient => 'De verkoper krijgt terug';

  @override
  String payBuyerBreakdown(String amount, String fee) {
    return 'De $amount van de order min de nodekosten van $fee.';
  }

  @override
  String refundSellerBreakdown(String amount, String fee) {
    return 'De $amount van de order plus de nodekosten van $fee, zoals de verkoper ze heeft vastgezet.';
  }

  @override
  String resolveTradeFiat(String fiat) {
    return 'Trade: $fiat';
  }

  @override
  String get payBuyerOtherSide =>
      'De sats die de verkoper heeft vastgezet, worden geïnd: de verkoper krijgt ze niet terug.';

  @override
  String get refundSellerOtherSide =>
      'De sats die de verkoper heeft vastgezet, gaan terug naar de verkoper: de koper ontvangt niets uit deze trade.';

  @override
  String get resolveBondsUnknown =>
      'Bosstro weet niet of deze node een borg gebruikt: de gegevens van de node konden niet worden gelezen of zeggen het niet. Is er een borg, dan wordt er geen ingehouden.';

  @override
  String get resolveIrreversible =>
      'Dit kan niet ongedaan worden gemaakt. Is het verzoek eenmaal verstuurd, dan stuurt Bosstro het nooit vanzelf opnieuw.';

  @override
  String get resolveWaiting =>
      'Wachten op het antwoord van de node. Houd Bosstro open.';

  @override
  String get resolvedPaidTitle => 'Opgelost: je hebt de koper betaald';

  @override
  String get resolvedPaidBody =>
      'De node heeft de door de verkoper vastgezette sats geïnd en betaalt de koper. Het dispuut is gesloten.';

  @override
  String get resolvedRefundedTitle =>
      'Opgelost: je hebt de verkoper terugbetaald';

  @override
  String get resolvedRefundedBody =>
      'De node heeft de vastgezette sats van de verkoper vrijgemaakt: ze gaan terug naar de verkoper. Het dispuut is gesloten.';

  @override
  String get resolvedCoopTitle => 'De partijen hadden al geannuleerd';

  @override
  String get resolvedCoopBody =>
      'Koper en verkoper hebben de trade onderling geannuleerd vóór je verzoek, dus jij hebt niets betaald of terugbetaald. Het dispuut is gesloten.';

  @override
  String get readOnlySolverTitle =>
      'Je kunt op deze node niet betalen of terugbetalen';

  @override
  String get takenOverTitle => 'Een andere solver heeft dit dispuut nu';

  @override
  String get takenOverBody =>
      'De node heeft het aan een andere solver gegeven, dus er is niets betaald of terugbetaald. Het staat niet meer in Jouw disputen.';

  @override
  String get notInDisputeTitle => 'Deze order is niet meer in dispuut';

  @override
  String get notInDisputeBody =>
      'Hij is al betaald, terugbetaald of vrijgegeven, misschien door een eerder verzoek waarvan het antwoord verloren ging. De status van het dispuut laat zien hoe het is afgelopen.';

  @override
  String get resolveRefusedTitle => 'De node heeft het verzoek geweigerd';

  @override
  String get resolveRefusedBody =>
      'Er is niets betaald of terugbetaald. Probeer het later opnieuw, of vraag het de beheerder van de node.';

  @override
  String get resolveNoAnswerBody =>
      'De node kan toch hebben gehandeld: de sats kunnen zijn verplaatst. Bosstro heeft het verzoek niet opnieuw verstuurd. Controleer de status van het dispuut voordat je het opnieuw probeert; die verandert zodra de node hem publiceert.';

  @override
  String get resolveClosedBody =>
      'Dit dispuut is gesloten: er valt niets op te lossen.';

  @override
  String get resolveNoOrderBody =>
      'Bosstro kent de order van dit dispuut niet, en het verzoek heeft die nodig. Haal het dispuut terug om hem opnieuw te lezen.';

  @override
  String get resolveBackToDispute => 'Terug naar het dispuut';

  @override
  String get resolveGoToDisputes => 'Naar Jouw disputen';

  @override
  String get inProgressClosedHeading => 'Gesloten';

  @override
  String get inProgressNoneOpen => 'Je hebt nu geen dispuut in handen.';

  @override
  String get closedPaidBuyer => 'Je hebt de koper betaald';

  @override
  String get closedRefundedSeller => 'Je hebt de verkoper terugbetaald';

  @override
  String get closedCooperatively =>
      'De partijen annuleerden het vóór je beslissing';

  @override
  String get detailResult => 'Uitkomst';

  @override
  String get bondsTitle => 'Borg';

  @override
  String get bondsPickerHint =>
      'Deze node gebruikt een borg tegen misbruik. Kies of en van wie de borg wordt ingehouden. Dat gaat mee in hetzelfde verzoek.';

  @override
  String get bondNoSlash => 'Niets inhouden';

  @override
  String get bondNoSlashDetail => 'Elke borg gaat terug naar de eigenaar.';

  @override
  String get bondSlashBuyer => 'Borg van de koper inhouden';

  @override
  String get bondSlashBuyerDetail =>
      'De koper verliest de borg; de verkoper kan een deel ervan opeisen.';

  @override
  String get bondSlashSeller => 'Borg van de verkoper inhouden';

  @override
  String get bondSlashSellerDetail =>
      'De verkoper verliest de borg; de koper kan een deel ervan opeisen.';

  @override
  String get bondSlashBoth => 'Beide borgen inhouden';

  @override
  String get bondSlashBothDetail => 'Beiden verliezen hun borg.';

  @override
  String get bondNotPostedTitle => 'Die partij heeft geen borg vastgezet';

  @override
  String get bondNotPostedBody =>
      'De node heeft geen borg van de partij waarvan je de borg wilde inhouden, dus er is niets betaald of terugbetaald. Kies een andere optie voor de borg.';

  @override
  String get bondChooseAgain => 'Andere optie kiezen';

  @override
  String get resolvedSlashedBuyer => 'De borg van de koper is ingehouden.';

  @override
  String get resolvedSlashedSeller => 'De borg van de verkoper is ingehouden.';

  @override
  String get resolvedSlashedBoth => 'Beide borgen zijn ingehouden.';

  @override
  String get detailBonds => 'Borg';

  @override
  String get detailPreviousStatus => 'Status vóór het dispuut';

  @override
  String get orderStatusActive => 'Actief';

  @override
  String get orderStatusFiatSent => 'Fiat verstuurd';
}
