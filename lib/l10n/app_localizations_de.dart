// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Bosstro';

  @override
  String get navPending => 'Offen';

  @override
  String get navInProgress => 'In Bearbeitung';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get noNodeSelected => 'Kein Node ausgewählt';

  @override
  String get pendingTitle => 'Offene Streitfälle';

  @override
  String get pendingEmptyTitle => 'Keine wartenden Streitfälle';

  @override
  String get pendingEmptyBody =>
      'Auf diesem Node wartet kein Streitfall auf einen Solver. Wenn ein Trade einen eröffnet, erscheint er hier, damit du ihn übernehmen kannst.';

  @override
  String get inProgressTitle => 'Deine Streitfälle';

  @override
  String get inProgressEmptyTitle => 'Keine Streitfälle in Bearbeitung';

  @override
  String get inProgressEmptyBody =>
      'Streitfälle, die du übernimmst, erscheinen hier. Kam auf eine Übernahme keine Antwort, hol den Streitfall zurück.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageSheetTitle => 'Sprache auswählen';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String languageSystemDetail(String language) {
    return 'Wie dein Gerät: $language';
  }

  @override
  String get copied => 'Kopiert';

  @override
  String get chatKeyCopied =>
      'Chat-Schlüssel kopiert. Er wird in 60 Sekunden aus der Zwischenablage gelöscht.';

  @override
  String get chatCopyHint => 'Nachricht kopieren';

  @override
  String get idLabel => 'ID';

  @override
  String get copyIdHint => 'ID kopieren';

  @override
  String get easterEggWhitepaper =>
      '31. Oktober 2008: neun Seiten, niemandes Erlaubnis. Frohes Halloween.';

  @override
  String get easterEggGenesis =>
      'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks';

  @override
  String get easterEggPizzaDay =>
      '22. Mai 2010: 10.000 BTC für zwei Pizzen. Hoffentlich haben sie geschmeckt.';

  @override
  String get welcomeTitle => 'Mostro-Streitfälle lösen';

  @override
  String get welcomeBody =>
      'Übernimm die Streitfälle eines Nodes, sprich mit Käufer und Verkäufer und schließ sie ab, von deinem Telefon aus.';

  @override
  String get welcomeLogIn => 'Anmelden';

  @override
  String get welcomeCreateAccount => 'Neues Konto erstellen';

  @override
  String get welcomeKeyUnreadable =>
      'Der gespeicherte Schlüssel konnte auf diesem Telefon nicht gelesen werden. Melde dich erneut mit deinem geheimen Schlüssel an. Meldest du dich mit einem anderen Schlüssel an, ersetzt er den gespeicherten.';

  @override
  String get traderKeyWarning =>
      'Verwende nie den Schlüssel, mit dem du handelst. Ist ein Solver-Schlüssel zugleich ein Handelsschlüssel, verknüpft das beide Rollen öffentlich.';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get loginHeading => 'Dein geheimer Solver-Schlüssel';

  @override
  String get loginBody =>
      'Füge den geheimen Schlüssel (nsec) ein, dessen npub dein Node-Betreiber als Solver registriert hat, oder scanne ihn.';

  @override
  String get loginBodyPaste =>
      'Füge den geheimen Schlüssel (nsec) ein, dessen npub dein Node-Betreiber als Solver registriert hat.';

  @override
  String get secretKeyHint => 'nsec1…';

  @override
  String get showSecretKey => 'Schlüssel anzeigen';

  @override
  String get hideSecretKey => 'Schlüssel verbergen';

  @override
  String get pasteAction => 'Einfügen';

  @override
  String get scanQrAction => 'QR scannen';

  @override
  String get clipboardEmpty => 'Die Zwischenablage ist leer.';

  @override
  String get loginContinue => 'Weiter';

  @override
  String get keyErrorEmpty => 'Gib deinen geheimen Schlüssel ein.';

  @override
  String get keyErrorPublicKey =>
      'Das ist ein öffentlicher Schlüssel (npub). Zum Anmelden brauchst du den geheimen Schlüssel (nsec).';

  @override
  String get keyErrorInvalid =>
      'Das ist kein gültiger geheimer Schlüssel. Gib einen nsec1…-Schlüssel oder seine 64-stellige Hex-Form ein.';

  @override
  String get loginConfirmHeading => 'Ist das der als Solver registrierte npub?';

  @override
  String get loginConfirmBody =>
      'Vergleiche ihn mit dem npub, den dein Node-Betreiber hinzugefügt hat. Stimmt er nicht überein, kann dieser Schlüssel auf diesem Node keine Streitfälle lösen.';

  @override
  String get loginConfirmAnswer => 'Ja, anmelden';

  @override
  String get loginConfirmBack => 'Nein, anderer Schlüssel';

  @override
  String get keySaveFailed =>
      'Der Schlüssel konnte auf diesem Telefon nicht gespeichert werden. Versuche es erneut.';

  @override
  String get npubLabel => 'npub';

  @override
  String get secretKeyLabel => 'Geheimer Schlüssel (nsec)';

  @override
  String get copyNpub => 'npub kopieren';

  @override
  String get copySecretKey => 'Geheimen Schlüssel kopieren';

  @override
  String get shareNpub => 'npub teilen';

  @override
  String get npubQrLabel => 'QR-Code deines npub';

  @override
  String get scanTitle => 'QR scannen';

  @override
  String get scanHint =>
      'Richte die Kamera auf den QR-Code deines geheimen Schlüssels.';

  @override
  String get scanUnavailable =>
      'Die Kamera ist nicht verfügbar. Geh zurück und füge den Schlüssel stattdessen ein.';

  @override
  String get createTitle => 'Neues Konto erstellen';

  @override
  String get createKeyHeading => 'Dein neuer geheimer Schlüssel';

  @override
  String get createKeyBody =>
      'Er ist die einzige Möglichkeit, dich bei diesem Konto anzumelden. Notiere ihn und bewahre ihn an einem sicheren, privaten Ort auf: Wer ihn hat, kann in deinem Namen Streitfälle lösen.';

  @override
  String get createBackupConfirm =>
      'Ich habe meinen geheimen Schlüssel an einem sicheren Ort aufbewahrt';

  @override
  String get createContinue => 'Weiter';

  @override
  String get createNpubHeading => 'Dein npub';

  @override
  String get createNpubBody =>
      'Sende diesen npub an deinen Node-Betreiber, damit er dich als Solver registriert. Bis dahin kannst du die Streitfälle sehen, aber nicht übernehmen.';

  @override
  String get createDone => 'Deinen Node wählen';

  @override
  String get settingsGroupKey => 'Solver-Schlüssel';

  @override
  String get settingsNpub => 'Dein npub';

  @override
  String get settingsBackup => 'Geheimen Schlüssel sichern';

  @override
  String get settingsLogOut => 'Abmelden';

  @override
  String get backupWarnTitle => 'Deinen geheimen Schlüssel anzeigen?';

  @override
  String get backupWarnBody =>
      'Wer ihn sieht, kann in deinem Namen Streitfälle lösen. Achte darauf, dass niemand auf deinen Bildschirm schaut.';

  @override
  String get backupWarnAnswer => 'Geheimen Schlüssel anzeigen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get backupTitle => 'Geheimen Schlüssel sichern';

  @override
  String get backupBody =>
      'Bewahre ihn an einem sicheren, privaten Ort auf. Er ist die einzige Möglichkeit, dich auf einem anderen Telefon bei diesem Konto anzumelden.';

  @override
  String get backupUnavailable =>
      'Der geheime Schlüssel konnte auf diesem Telefon nicht gelesen werden.';

  @override
  String get logOutTitle => 'Abmelden?';

  @override
  String get logOutBody =>
      'Dein geheimer Schlüssel wird von diesem Telefon entfernt. Ohne Sicherung kannst du dich nicht wieder bei diesem Konto anmelden.';

  @override
  String get logOutAnswer => 'Abmelden';

  @override
  String get logOutFailed => 'Abmelden fehlgeschlagen. Versuche es erneut.';

  @override
  String get secretKeyCopied =>
      'Geheimer Schlüssel kopiert. Er wird in 60 Sekunden aus der Zwischenablage gelöscht.';

  @override
  String linkOnline(int connected, int total) {
    return 'Online · $connected/$total Relays';
  }

  @override
  String get linkConnecting => 'Verbindung zu Relays…';

  @override
  String get linkOffline => 'Offline · kein Relay antwortet';

  @override
  String get chooseNodeTitle => 'Wähle deinen Node';

  @override
  String get chooseNodeBody =>
      'Wähle den Mostro-Node, dessen Betreiber deinen Schlüssel als Solver registriert hat. Du kannst den Node später in den Einstellungen wechseln.';

  @override
  String get chooseNodeAppBar => 'Node';

  @override
  String get nodeChipTrusted => 'Vertrauenswürdig';

  @override
  String get nodeChipCustom => 'Von dir hinzugefügt';

  @override
  String get nodeChipActive => 'Aktiv';

  @override
  String get nodeAddOwn => 'Eigenen Node hinzufügen';

  @override
  String get nodeInfoTooltip => 'Node-Infos';

  @override
  String nodeSwitched(String name) {
    return 'Jetzt auf $name';
  }

  @override
  String get nodeSelectFailed =>
      'Der Wechsel zu diesem Node ist fehlgeschlagen. Versuche es erneut.';

  @override
  String get nodeListFailed =>
      'Die Node-Liste konnte nicht geladen werden. Starte die App neu, um es erneut zu versuchen.';

  @override
  String get addNodeTitle => 'Node hinzufügen';

  @override
  String get addNodeBody =>
      'Füge den öffentlichen Schlüssel des Nodes ein (npub oder hex). Sein Betreiber kann ihn dir geben.';

  @override
  String get addNodePubkeyLabel => 'Öffentlicher Schlüssel';

  @override
  String get addNodeNameLabel => 'Name (optional)';

  @override
  String get addNodeAnswer => 'Node hinzufügen';

  @override
  String get nodeErrorInvalidPubkey =>
      'Gib einen gültigen öffentlichen Schlüssel ein (npub oder 64 Hex-Zeichen).';

  @override
  String get nodeErrorPrivateKey =>
      'Das ist ein geheimer Schlüssel — teile ihn niemals. Gib den öffentlichen Schlüssel des Nodes ein.';

  @override
  String get nodeErrorAlreadyExists => 'Dieser Node ist bereits in der Liste.';

  @override
  String get nodeErrorActive =>
      'Das ist dein aktiver Node. Wechsle zu einem anderen Node, bevor du ihn entfernst.';

  @override
  String get nodeErrorStorage =>
      'Deine Nodes konnten auf diesem Gerät nicht gespeichert werden.';

  @override
  String get nodeErrorGeneric =>
      'Etwas ist schiefgelaufen. Versuche es erneut.';

  @override
  String get removeNodeAction => 'Node entfernen';

  @override
  String get removeNodeTitle => 'Diesen Node entfernen?';

  @override
  String get removeNodeBody =>
      'Er verschwindet aus deiner Liste. Du kannst ihn mit seinem öffentlichen Schlüssel wieder hinzufügen.';

  @override
  String get removeNodeAnswer => 'Node entfernen';

  @override
  String get nodeRemoved => 'Node entfernt';

  @override
  String get nodeInfoTitle => 'Node-Infos';

  @override
  String get nodeInfoUse => 'Diesen Node verwenden';

  @override
  String get nodeInfoGroupNode => 'Node';

  @override
  String get nodeInfoPubkey => 'Öffentlicher Schlüssel';

  @override
  String get nodeInfoRegion => 'Region';

  @override
  String get nodeInfoWebsite => 'Website';

  @override
  String get nodeInfoAbout => 'Beschreibung';

  @override
  String get nodeInfoEmptyTitle => 'Noch keine Instanz-Infos';

  @override
  String get nodeInfoEmptyBody =>
      'Dieser Node hat seine Instanz-Infos nicht auf deinen Relays veröffentlicht, oder sie haben noch nicht geantwortet. Sie werden bei jedem Öffnen dieses Bildschirms erneut angefragt.';

  @override
  String get nodeInfoRefreshFailed =>
      'Die Relays haben nicht geantwortet. Das sind die zuletzt gesehenen Infos.';

  @override
  String get nodeInfoStale =>
      'Diese Infos sind älter als 7 Tage und eventuell veraltet.';

  @override
  String nodeInfoUnsupported(int version) {
    return 'Dieser Node spricht Protokoll v$version. Bosstro spricht nur v2 und kann dort daher keine Streitfälle lösen.';
  }

  @override
  String get nodeInfoUpdatedNow => 'Gerade aktualisiert';

  @override
  String nodeInfoUpdatedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Minuten aktualisiert',
      one: 'Vor 1 Minute aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Stunden aktualisiert',
      one: 'Vor 1 Stunde aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen aktualisiert',
      one: 'Vor 1 Tag aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String get nodeInfoGroupProtocol => 'Protokoll';

  @override
  String get nodeInfoProtocolVersion => 'Protokollversion';

  @override
  String get nodeInfoTransport => 'Transport';

  @override
  String get nodeInfoGroupDaemon => 'Mostro-Daemon';

  @override
  String get nodeInfoVersion => 'Version';

  @override
  String get nodeInfoCommit => 'Commit';

  @override
  String get nodeInfoMaxOrder => 'Max. Orderbetrag';

  @override
  String get nodeInfoMinOrder => 'Min. Orderbetrag';

  @override
  String get nodeInfoExpirationHours => 'Ablauf von Orders';

  @override
  String get nodeInfoExpirationSeconds => 'Ablauf angenommener Orders';

  @override
  String get nodeInfoHoldWindow => 'Ablauf der Sperr-Rechnung';

  @override
  String get nodeInfoHoldCltv => 'CLTV-Delta der Sperr-Rechnung';

  @override
  String get nodeInfoInvoiceWindow => 'Rechnungsablauffenster';

  @override
  String get nodeInfoMaxOrders => 'Max. Orders/Antwort';

  @override
  String get nodeInfoFee => 'Gebühr';

  @override
  String get nodeInfoPow => 'Erforderlicher PoW';

  @override
  String get nodeInfoPowFirst => 'PoW beim Erstkontakt';

  @override
  String get nodeInfoBonds => 'Sicherheitseinlagen';

  @override
  String get nodeInfoGroupLightning => 'Lightning-Node';

  @override
  String get nodeInfoAlias => 'Alias';

  @override
  String get nodeInfoLnPubkey => 'Node-Pubkey';

  @override
  String get nodeInfoLndVersion => 'LND-Version';

  @override
  String get nodeInfoChains => 'Chains';

  @override
  String get nodeInfoNetworks => 'Netzwerke';

  @override
  String get nodeInfoUri => 'URI';

  @override
  String get nodeInfoGroupFiat => 'Fiat-Währungen';

  @override
  String get nodeInfoFiatAll => 'Alle Währungen werden akzeptiert.';

  @override
  String get nodeInfoUnknown => 'Unbekannt';

  @override
  String get nodeInfoEnabled => 'Aktiviert';

  @override
  String get nodeInfoDisabled => 'Deaktiviert';

  @override
  String unitSats(String amount) {
    return '$amount Sats';
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
      other: '$count Blöcke',
      one: '1 Block',
    );
    return '$_temp0';
  }

  @override
  String unitBits(int count) {
    return '$count Bit';
  }

  @override
  String unitPercent(String value) {
    return '$value %';
  }

  @override
  String get relaysTitle => 'Relays';

  @override
  String get relaysBody =>
      'Bosstro spricht über diese Relays mit deinem Node. Die Relays, die dein Node ankündigt, werden automatisch hinzugefügt.';

  @override
  String get relayStatusConnected => 'Verbunden';

  @override
  String get relayStatusConnecting => 'Wird verbunden';

  @override
  String get relayStatusDisconnected => 'Getrennt';

  @override
  String get relayStatusError => 'Abgelehnt';

  @override
  String get relaySourceDefault => 'Standard';

  @override
  String get relaySourceNode => 'Von deinem Node';

  @override
  String get relaySourceUser => 'Von dir hinzugefügt';

  @override
  String get relayAdd => 'Relay hinzufügen';

  @override
  String get addRelayTitle => 'Relay hinzufügen';

  @override
  String get addRelayLabel => 'Relay-Adresse';

  @override
  String get addRelayAnswer => 'Relay hinzufügen';

  @override
  String get relayRemoveTooltip => 'Relay entfernen';

  @override
  String get removeRelayTitle => 'Dieses Relay entfernen?';

  @override
  String get removeRelayBody =>
      'Bosstro nutzt es nicht mehr. Ein Relay, das dein Node angekündigt hat, kommt nur zurück, wenn du es selbst hinzufügst.';

  @override
  String get removeRelayAnswer => 'Relay entfernen';

  @override
  String get relayErrorInvalidUrl =>
      'Gib eine Relay-Adresse ein, die mit wss:// beginnt.';

  @override
  String get relayErrorExists => 'Dieses Relay ist bereits in der Liste.';

  @override
  String get relayErrorLast =>
      'Das ist dein letztes Relay. Füge ein weiteres hinzu, bevor du es entfernst.';

  @override
  String get relaysNotRunningTitle => 'Die Relays sind nicht gestartet';

  @override
  String get relaysNotRunningBody =>
      'Bosstro konnte keine Verbindung zu den Relays aufbauen. Starte die App neu, um es erneut zu versuchen.';

  @override
  String get settingsGroupNode => 'Node';

  @override
  String get settingsNode => 'Node';

  @override
  String get settingsNodeNone => 'Wählen';

  @override
  String get settingsNodeInfo => 'Node-Infos';

  @override
  String get settingsRelays => 'Relays';

  @override
  String settingsRelaysValue(int connected, int total) {
    return '$connected/$total';
  }

  @override
  String get pendingNoNodeTitle => 'Wähle zuerst deinen Node';

  @override
  String get pendingNoNodeBody =>
      'Streitfälle werden von jeweils einem Mostro-Node gelesen. Wähle den Node, auf dem du Solver bist.';

  @override
  String get pendingNoNodeAction => 'Node wählen';

  @override
  String get loadingNodes => 'Nodes werden geladen';

  @override
  String get loadingNodeInfo => 'Node-Infos werden geladen';

  @override
  String get loadingRelays => 'Relays werden geladen';

  @override
  String get loadingDisputes => 'Streitfälle werden geladen';

  @override
  String get pendingLoadErrorTitle =>
      'Streitfälle konnten nicht gelesen werden';

  @override
  String get pendingLoadErrorBody =>
      'Beim Lesen der Streitfälle dieses Nodes auf diesem Telefon ist etwas schiefgelaufen. Schließe Bosstro und öffne es erneut, um es noch einmal zu versuchen.';

  @override
  String get disputeStatusInitiated => 'Wartet auf Solver';

  @override
  String get disputeStatusInProgress => 'In Bearbeitung';

  @override
  String get disputeStatusSettled => 'An Käufer ausgezahlt';

  @override
  String get disputeStatusSellerRefunded => 'An Verkäufer erstattet';

  @override
  String get disputeStatusReleased => 'Vom Verkäufer freigegeben';

  @override
  String get disputeStatusCooperativelyCanceled => 'Gemeinsam storniert';

  @override
  String get disputeOpenedByBuyer => 'Vom Käufer eröffnet';

  @override
  String get disputeOpenedBySeller => 'Vom Verkäufer eröffnet';

  @override
  String get disputeOpenedByUnknown => 'Eröffnende Partei unbekannt';

  @override
  String get disputeOpenedJustNow => 'Gerade eröffnet';

  @override
  String disputeOpenedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Minuten eröffnet',
      one: 'Vor 1 Minute eröffnet',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Stunden eröffnet',
      one: 'Vor 1 Stunde eröffnet',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen eröffnet',
      one: 'Vor 1 Tag eröffnet',
    );
    return '$_temp0';
  }

  @override
  String get disputeOpenedUnknown => 'Eröffnungszeit unbekannt';

  @override
  String disputeRowLabel(String id) {
    return 'Streitfall $id';
  }

  @override
  String get close => 'Schließen';

  @override
  String get takeDisputeHint => 'Streitfall übernehmen';

  @override
  String get takeDisputeTitle => 'Diesen Streitfall übernehmen?';

  @override
  String get takeDisputeBody =>
      'Du wirst sein Solver: Der Node benachrichtigt Käufer und Verkäufer, und der Streitfall wandert zu „Deine Streitfälle“. Übernimm nur einen Streitfall, den du bis zum Ende betreuen kannst.';

  @override
  String get takeDisputeAnswer => 'Streitfall übernehmen';

  @override
  String get takeTakenSnack =>
      'Streitfall übernommen. Du findest ihn unter „Deine Streitfälle“.';

  @override
  String get recoverAction => 'Zurückholen';

  @override
  String get recoverTitle => 'Streitfall zurückholen';

  @override
  String get recoverNote =>
      'Der Node veröffentlicht nicht, wer einen Streitfall betreut. Deshalb zeigt diese Liste jeden Streitfall in Bearbeitung auf diesem Node, der auf diesem Telefon nicht unter „Deine Streitfälle“ steht: deine, deren Antwort verloren ging, und die anderer Solver. Hol sie einzeln zurück.';

  @override
  String get recoverEmptyTitle => 'Nichts zurückzuholen';

  @override
  String get recoverEmptyBody =>
      'Unter „Deine Streitfälle“ fehlt kein Streitfall dieses Nodes, der in Bearbeitung ist.';

  @override
  String get recoverDisputeHint => 'Streitfall zurückholen';

  @override
  String get recoverDisputeTitle => 'Diesen Streitfall zurückholen?';

  @override
  String get recoverDisputeBody =>
      'Bosstro fordert diesen Streitfall erneut beim Node an. Ist er deiner, sendet der Node seine Daten zurück. Betreut ihn ein anderer Solver, lehnt der Node ab – außer dieser Solver hat nur Leserecht (wie Serbero) und dein Schlüssel kann den Käufer bezahlen und dem Verkäufer erstatten: Dann wird der Streitfall deiner (eine Übernahme).';

  @override
  String get recoverDisputeAnswer => 'Streitfall zurückholen';

  @override
  String get recoverTakenSnack =>
      'Streitfall zurückgeholt. Du findest ihn unter „Deine Streitfälle“.';

  @override
  String get notSolverTitle => 'Du bist auf diesem Node kein Solver';

  @override
  String get notSolverBody =>
      'Wechsle zu deinem Node, um Streitfälle zu lösen. Wenn das dein Node ist, sende deinen npub an seinen Betreiber.';

  @override
  String get switchNodeAction => 'Node wechseln';

  @override
  String get cannotTakeOverTitle =>
      'Ein anderer Solver betreut diesen Streitfall';

  @override
  String get cannotTakeOverBody =>
      'Übernehmen lässt sich nur ein Streitfall, den ein Solver mit reinem Leserecht (wie Serbero) betreut, und nur von einem Solver, der den Käufer bezahlen und dem Verkäufer erstatten kann.';

  @override
  String get takeRefusedTitle =>
      'Der Node hat dir diesen Streitfall nicht gegeben';

  @override
  String get takeRefusedBody =>
      'Er hat die Anfrage abgelehnt. Versuche es später erneut oder frag den Betreiber des Nodes.';

  @override
  String get takeRefusedNotFoundBody =>
      'Der Node hat die Order dieses Streitfalls nicht mehr.';

  @override
  String get noAnswerTitle => 'Der Node hat nicht geantwortet';

  @override
  String get noAnswerBody =>
      'Deine Anfrage hat ihn vielleicht trotzdem erreicht, daher hat Bosstro sie nicht erneut gesendet. Sieh gleich unter „Deine Streitfälle“ nach oder fordere den Streitfall über „Streitfall zurückholen“ erneut an.';

  @override
  String get takeFailedTitle => 'Die Anfrage wurde nicht gesendet';

  @override
  String get takeFailedBody =>
      'Kein Relay hat sie angenommen. Prüfe deine Verbindung und die Relays und versuche es dann erneut.';

  @override
  String get takeAlreadyTakingBody =>
      'Eine Anfrage für diesen Streitfall wartet bereits auf die Antwort des Nodes.';

  @override
  String get takeClosedBody =>
      'Dieser Streitfall ist geschlossen: Es gibt nichts zu übernehmen.';

  @override
  String get takeUnknownBody =>
      'Dieser Streitfall ist auf diesem Telefon nicht unter den Streitfällen dieses Nodes.';

  @override
  String get takeProtocolBody =>
      'Dieser Node kündigt eine andere Protokollversion an. Bosstro spricht nur mit Nodes mit Protokoll 2.';

  @override
  String get takeNodeInfoBody =>
      'Bosstro konnte die Einstellungen dieses Nodes nicht lesen und kennt daher den Proof of Work nicht, den der Node verlangt. Prüfe die Relays und versuche es erneut.';

  @override
  String get disputeTakenJustNow => 'Gerade übernommen';

  @override
  String disputeTakenMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Minuten übernommen',
      one: 'Vor 1 Minute übernommen',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Stunden übernommen',
      one: 'Vor 1 Stunde übernommen',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen übernommen',
      one: 'Vor 1 Tag übernommen',
    );
    return '$_temp0';
  }

  @override
  String disputeAmountSats(String amount) {
    return '$amount Sats';
  }

  @override
  String disputeAmountFiat(String amount, String code) {
    return '$amount $code';
  }

  @override
  String get disputeAmountUnknown => 'Betrag unbekannt';

  @override
  String get settingsSolverStatus => 'Solver auf diesem Node';

  @override
  String get settingsSolverYes => 'Ja';

  @override
  String get settingsSolverNo => 'Nein';

  @override
  String get settingsPermission => 'Berechtigung';

  @override
  String get permissionRead => 'Nur vermitteln';

  @override
  String get permissionReadWrite => 'Vermitteln, bezahlen und erstatten';

  @override
  String get disputeDetailTitle => 'Streitfall';

  @override
  String get detailSegmentInfo => 'Info';

  @override
  String get detailSegmentBuyer => 'Käufer';

  @override
  String get detailSegmentSeller => 'Verkäufer';

  @override
  String get detailSegmentsLabel => 'Bereiche des Streitfalls';

  @override
  String get detailDisputeId => 'Streitfall-ID';

  @override
  String get detailOrderId => 'Order-ID';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailOpenedBy => 'Eröffnet von';

  @override
  String get detailOpenedAt => 'Eröffnet';

  @override
  String get detailTakenAt => 'Übernommen';

  @override
  String get detailAmount => 'Betrag';

  @override
  String get detailCurrency => 'Währung';

  @override
  String get detailFactsTitle => 'Streitfall und Order';

  @override
  String get detailFiatAmount => 'Fiat-Betrag';

  @override
  String get detailPaymentMethod => 'Zahlungsmethode';

  @override
  String get detailPremium => 'Aufschlag';

  @override
  String get detailFee => 'Node-Gebühr';

  @override
  String get detailOrderKind => 'Order-Typ';

  @override
  String get detailBuyerKey => 'Trade-Schlüssel des Käufers';

  @override
  String get detailSellerKey => 'Trade-Schlüssel des Verkäufers';

  @override
  String get detailPartyBuyer => 'Käufer';

  @override
  String get detailPartySeller => 'Verkäufer';

  @override
  String get detailPartyUnknown => 'Unbekannt';

  @override
  String get detailOrderKindBuy => 'Kauforder';

  @override
  String get detailOrderKindSell => 'Verkaufsorder';

  @override
  String detailPremiumValue(String value) {
    return '$value %';
  }

  @override
  String get detailNotYoursTitle => 'Dieser Streitfall gehört dir nicht mehr';

  @override
  String get detailNotYoursBody =>
      'Der Node hat ihn wieder geöffnet, oder er gehört zu einem anderen Schlüssel. Er ist nicht mehr unter „Deine Streitfälle“.';

  @override
  String get chatSenderYou => 'Du';

  @override
  String get chatSenderBuyer => 'Käufer';

  @override
  String get chatSenderSeller => 'Verkäufer';

  @override
  String get chatEmptyBuyerTitle => 'Keine Nachrichten mit dem Käufer';

  @override
  String get chatEmptySellerTitle => 'Keine Nachrichten mit dem Verkäufer';

  @override
  String get chatEmptyBody =>
      'Nur du und diese Partei könnt diese Unterhaltung lesen. Die andere Partei sieht sie nicht.';

  @override
  String get chatNoPartyKeyTitle => 'Kein Chat mit dieser Partei';

  @override
  String get chatNoPartyKeyBody =>
      'Die Antwort des Nodes auf die Übernahme enthielt den Schlüssel dieser Partei nicht, daher kann Bosstro sie nicht erreichen.';

  @override
  String get chatClosedNote =>
      'Dieser Streitfall ist geschlossen. Der Chat kann nur noch gelesen werden.';

  @override
  String get chatComposerBuyerHint => 'Schreib dem Käufer';

  @override
  String get chatComposerSellerHint => 'Schreib dem Verkäufer';

  @override
  String get chatSend => 'Senden';

  @override
  String get chatSending => 'Wird gesendet…';

  @override
  String get chatNotSent => 'Nicht gesendet';

  @override
  String get chatRetry => 'Erneut versuchen';

  @override
  String get chatErrorTooLong =>
      'Die Nachricht ist zu lang. Teile sie in zwei auf.';

  @override
  String get chatErrorClosed =>
      'Dieser Streitfall ist geschlossen. Der Chat kann nur noch gelesen werden.';

  @override
  String get chatErrorNoRelays =>
      'Mit keinem Relay verbunden. Prüfe deine Verbindung.';

  @override
  String get chatErrorNotYours => 'Dieser Streitfall gehört dir nicht mehr.';

  @override
  String get chatErrorGeneric => 'Die Nachricht konnte nicht gesendet werden.';

  @override
  String get chatLoading => 'Nachrichten werden geladen';

  @override
  String chatMessageLabel(String sender, String time, String text) {
    return '$sender, $time: $text';
  }

  @override
  String get openDisputeHint => 'Streitfall öffnen';

  @override
  String get chatAttach => 'Datei anhängen';

  @override
  String get attachSheetTitle => 'Anhängen';

  @override
  String get attachSourcePhoto => 'Foto aus der Galerie';

  @override
  String get attachSourceCamera => 'Foto aufnehmen';

  @override
  String get attachSourcePdf => 'PDF-Dokument';

  @override
  String get attachSheetNote =>
      'Die Datei wird auf diesem Gerät verschlüsselt. Nur du und diese Partei könnt sie öffnen. JPEG, PNG oder PDF, bis 25 MB.';

  @override
  String get attachConfirmTitle => 'Diese Datei senden?';

  @override
  String attachConfirmBuyer(String name, String size) {
    return '$name ($size) geht verschlüsselt an den Käufer. Ein Foto wird ohne Standort- und Kameradaten gesendet.';
  }

  @override
  String attachConfirmSeller(String name, String size) {
    return '$name ($size) geht verschlüsselt an den Verkäufer. Ein Foto wird ohne Standort- und Kameradaten gesendet.';
  }

  @override
  String get attachmentTooLarge => 'Die Datei ist größer als 25 MB.';

  @override
  String get attachmentUnsupported =>
      'Nur JPEG- und PNG-Bilder sowie PDF-Dokumente können gesendet werden.';

  @override
  String get attachmentInvalidImage => 'Das Bild konnte nicht gelesen werden.';

  @override
  String get attachmentReadFailed => 'Die Datei konnte nicht gelesen werden.';

  @override
  String get attachmentUploadFailed =>
      'Die Datei konnte nicht hochgeladen werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get attachmentSendFailed => 'Die Datei konnte nicht gesendet werden.';

  @override
  String get attachmentUploading => 'Wird verschlüsselt und gesendet…';

  @override
  String get attachmentDiscard => 'Verwerfen';

  @override
  String get attachmentLoading => 'Datei wird entschlüsselt';

  @override
  String get attachmentNotVerified =>
      'Die Datei konnte nicht überprüft werden.';

  @override
  String get attachmentDownloadFailed =>
      'Die Datei konnte nicht heruntergeladen werden.';

  @override
  String get attachmentUnsupportedReceived =>
      'Dieser Dateityp kann hier nicht geöffnet werden.';

  @override
  String get attachmentOpenFailed => 'Die Datei konnte nicht geöffnet werden.';

  @override
  String attachmentImageLabel(String name) {
    return 'Bild $name';
  }

  @override
  String get attachmentOpenImage => 'Bild öffnen';

  @override
  String get attachmentSave => 'Speichern';

  @override
  String get attachmentSaveHint => 'Datei speichern';

  @override
  String get attachmentSaved => 'Gespeichert';

  @override
  String get attachmentSaveFailed =>
      'Die Datei konnte nicht gespeichert werden.';

  @override
  String attachmentFileLabel(String name, String details) {
    return '$name, $details';
  }

  @override
  String get attachmentViewerZoomHint => 'Mit zwei Fingern zoomen';

  @override
  String get observerTitle => 'Chat zwischen den Parteien';

  @override
  String observerSharedByBuyer(String date) {
    return 'Der Käufer hat seinen Chat-Schlüssel am $date geteilt.';
  }

  @override
  String observerSharedBySeller(String date) {
    return 'Der Verkäufer hat seinen Chat-Schlüssel am $date geteilt.';
  }

  @override
  String get observerPastedKey =>
      'Du hast einen Chat-Schlüssel für diesen Streitfall eingefügt.';

  @override
  String get observerStoredOnly =>
      'Nachrichten aus einem früheren Abruf. Füge den Chat-Schlüssel erneut ein, um nach neuen zu suchen.';

  @override
  String get observerNoKey =>
      'Noch keine Partei hat ihren Chat-Schlüssel geteilt. Schickt eine Partei ihn dir auf anderem Weg, füge ihn hier ein.';

  @override
  String get observerReadAction => 'Chat zwischen den Parteien lesen';

  @override
  String get observerPasteAction => 'Chat-Schlüssel einfügen';

  @override
  String get observerRefresh => 'Aktualisieren';

  @override
  String get observerReadOnlyBuyer =>
      'Nur lesbar, mit dem Schlüssel, den der Käufer geteilt hat.';

  @override
  String get observerReadOnlySeller =>
      'Nur lesbar, mit dem Schlüssel, den der Verkäufer geteilt hat.';

  @override
  String get observerReadOnlyBoth =>
      'Nur lesbar, mit dem Schlüssel, den beide Parteien geteilt haben.';

  @override
  String get observerReadOnlyPasted =>
      'Nur lesbar, mit einem Schlüssel, den du eingefügt hast.';

  @override
  String get observerReadOnlyStored =>
      'Nur lesbar: Nachrichten aus einem früheren Abruf.';

  @override
  String get observerNoKeyTitle => 'Noch kein Chat-Schlüssel';

  @override
  String get observerOpensNothingTitle =>
      'Der Schlüssel öffnet keine Nachricht dieses Streitfalls';

  @override
  String observerOpensNothingBody(String date) {
    return 'Keine Nachricht von Käufer oder Verkäufer dieses Streitfalls seit dem $date lässt sich damit öffnen. Vielleicht ist es der Schlüssel eines anderen Trades, oder sie haben in dieser Zeit nicht geschrieben.';
  }

  @override
  String get observerReadFailedTitle =>
      'Die Relays konnten nicht abgefragt werden';

  @override
  String get observerReadFailedBody =>
      'Prüfe die Verbindung und versuche es erneut.';

  @override
  String get observerNoPartyKeysTitle => 'Die Parteien sind nicht bekannt';

  @override
  String get observerNoPartyKeysBody =>
      'Der Node hat die Trade-Schlüssel von Käufer und Verkäufer nicht genannt, daher kann keine Nachricht als ihre angezeigt werden.';

  @override
  String get observerPasteTitle => 'Chat-Schlüssel einfügen';

  @override
  String get observerPasteBody =>
      'Eine Partei kann dir den Schlüssel ihres Chats mit der anderen Partei schicken. Damit liest du diesen Chat; schreiben kannst du darin nie.';

  @override
  String get observerPasteHint => '64 Hexadezimalzeichen';

  @override
  String get observerPasteConfirm => 'Chat lesen';

  @override
  String get observerInvalidKey =>
      'Das ist kein Chat-Schlüssel: Er besteht aus 64 Hexadezimalzeichen, allein oder nach „Shared key: “.';

  @override
  String observerOpensNothingShort(String date) {
    return 'Der Schlüssel öffnet seit dem $date keine Nachricht dieses Streitfalls.';
  }

  @override
  String get observerNotYours =>
      'Dieser Streitfall gehört dir auf diesem Node nicht mehr.';

  @override
  String get observerFileLocked =>
      'Mit einem Chat-Schlüssel lässt sich das nicht öffnen.';

  @override
  String get observerFileAdviceBuyer =>
      'Bitte den Käufer, dir die Datei in deinem Chat mit ihm zu schicken.';

  @override
  String get observerFileAdviceSeller =>
      'Bitte den Verkäufer, dir die Datei in deinem Chat mit ihm zu schicken.';

  @override
  String get observerFileImage => 'Bild';

  @override
  String get observerFileOther => 'Datei';

  @override
  String get resolveCardTitle => 'Streitfall lösen';

  @override
  String get resolveCardBody =>
      'Wenn du beide Parteien angehört hast, entscheide, wohin die Sats gehen. Das kann nicht rückgängig gemacht werden.';

  @override
  String get payBuyerAction => 'Käufer bezahlen';

  @override
  String get refundSellerAction => 'Dem Verkäufer erstatten';

  @override
  String get payBuyerAnswer => 'Käufer bezahlen';

  @override
  String get refundSellerAnswer => 'Dem Verkäufer erstatten';

  @override
  String get resolveReadOnlyNote =>
      'Dein Solver-Schlüssel kann auf diesem Node vermitteln, aber nicht bezahlen oder erstatten. Bitte den Betreiber um Lese- und Schreibrechte.';

  @override
  String get resolveUnansweredPayNote =>
      'Deine Anfrage, den Käufer zu bezahlen, blieb unbeantwortet. Der Node hat vielleicht trotzdem bezahlt: Prüfe den Status des Streitfalls, bevor du es erneut versuchst.';

  @override
  String get resolveUnansweredRefundNote =>
      'Deine Anfrage, dem Verkäufer zu erstatten, blieb unbeantwortet. Der Node hat vielleicht trotzdem erstattet: Prüfe den Status des Streitfalls, bevor du es erneut versuchst.';

  @override
  String get payBuyerTitle => 'Käufer bezahlen?';

  @override
  String get refundSellerTitle => 'Dem Verkäufer erstatten?';

  @override
  String get payBuyerRecipient => 'Der Käufer erhält';

  @override
  String get refundSellerRecipient => 'Der Verkäufer erhält zurück';

  @override
  String payBuyerBreakdown(String amount, String fee) {
    return 'Die $amount der Order abzüglich der Node-Gebühr von $fee.';
  }

  @override
  String refundSellerBreakdown(String amount, String fee) {
    return 'Die $amount der Order zuzüglich der Node-Gebühr von $fee, so wie der Verkäufer sie gesperrt hat.';
  }

  @override
  String resolveTradeFiat(String fiat) {
    return 'Trade: $fiat';
  }

  @override
  String get payBuyerOtherSide =>
      'Die Sperr-Rechnung des Verkäufers wird eingelöst: Der Verkäufer bekommt diese Sats nicht zurück.';

  @override
  String get refundSellerOtherSide =>
      'Die Sperr-Rechnung des Verkäufers wird storniert: Der Käufer erhält nichts aus diesem Trade.';

  @override
  String get resolveBondsUnknown =>
      'Bosstro weiß nicht, ob dieser Node Einlagen nutzt: Seine Infos konnten nicht gelesen werden oder sagen es nicht. Falls es welche gibt, wird keine eingezogen.';

  @override
  String get resolveIrreversible =>
      'Das kann nicht rückgängig gemacht werden. Ist die Anfrage gesendet, wiederholt Bosstro sie nie von selbst.';

  @override
  String get resolveWaiting =>
      'Warten auf die Antwort des Nodes. Lass Bosstro geöffnet.';

  @override
  String get resolvedPaidTitle => 'Gelöst: Du hast den Käufer bezahlt';

  @override
  String get resolvedPaidBody =>
      'Der Node hat die Sperr-Rechnung des Verkäufers eingelöst und bezahlt den Käufer. Der Streitfall ist geschlossen.';

  @override
  String get resolvedRefundedTitle => 'Gelöst: Du hast dem Verkäufer erstattet';

  @override
  String get resolvedRefundedBody =>
      'Der Node hat die Sperr-Rechnung des Verkäufers storniert: Die Sats gehen an den Verkäufer zurück. Der Streitfall ist geschlossen.';

  @override
  String get resolvedCoopTitle => 'Die Parteien hatten bereits storniert';

  @override
  String get resolvedCoopBody =>
      'Käufer und Verkäufer haben den Trade vor deiner Anfrage untereinander storniert, daher hast du nichts bezahlt oder erstattet. Der Streitfall ist geschlossen.';

  @override
  String get readOnlySolverTitle =>
      'Du kannst auf diesem Node nicht bezahlen oder erstatten';

  @override
  String get takenOverTitle =>
      'Jetzt betreut ein anderer Solver diesen Streitfall';

  @override
  String get takenOverBody =>
      'Der Node hat ihn einem anderen Solver gegeben, daher wurde nichts bezahlt oder erstattet. Er ist nicht mehr unter „Deine Streitfälle“.';

  @override
  String get notInDisputeTitle =>
      'Für diese Order besteht kein Streitfall mehr';

  @override
  String get notInDisputeBody =>
      'Sie wurde bereits bezahlt, erstattet oder freigegeben, vielleicht durch eine frühere Anfrage, deren Antwort verloren ging. Der Status des Streitfalls zeigt, wie er endete.';

  @override
  String get resolveRefusedTitle => 'Der Node hat die Anfrage abgelehnt';

  @override
  String get resolveRefusedBody =>
      'Es wurde nichts bezahlt oder erstattet. Versuche es später erneut oder frag den Betreiber des Nodes.';

  @override
  String get resolveNoAnswerBody =>
      'Er hat vielleicht trotzdem gehandelt: Die Sats könnten bewegt worden sein. Bosstro hat die Anfrage nicht erneut gesendet. Prüfe den Status des Streitfalls, bevor du es erneut versuchst; er ändert sich, sobald der Node ihn veröffentlicht.';

  @override
  String get resolveClosedBody =>
      'Dieser Streitfall ist geschlossen: Es gibt nichts zu lösen.';

  @override
  String get resolveNoOrderBody =>
      'Bosstro kennt die Order dieses Streitfalls nicht, und die Anfrage braucht sie. Hol den Streitfall zurück, um sie erneut zu lesen.';

  @override
  String get resolveBackToDispute => 'Zurück zum Streitfall';

  @override
  String get resolveGoToDisputes => 'Deine Streitfälle öffnen';

  @override
  String get inProgressClosedHeading => 'Geschlossen';

  @override
  String get inProgressNoneOpen => 'Du betreust gerade keinen Streitfall.';

  @override
  String get closedPaidBuyer => 'Du hast den Käufer bezahlt';

  @override
  String get closedRefundedSeller => 'Du hast dem Verkäufer erstattet';

  @override
  String get closedCooperatively =>
      'Die Parteien haben vor deiner Entscheidung storniert';

  @override
  String get detailResult => 'Ergebnis';

  @override
  String get bondsTitle => 'Einlagen';

  @override
  String get bondsPickerHint =>
      'Dieser Node nutzt Sicherheitseinlagen. Wähle, ob und wessen Einlage eingezogen wird. Die Wahl wird mit derselben Anfrage gesendet.';

  @override
  String get bondNoSlash => 'Keine einziehen';

  @override
  String get bondNoSlashDetail =>
      'Jede Einlage geht an ihren Eigentümer zurück.';

  @override
  String get bondSlashBuyer => 'Einlage des Käufers einziehen';

  @override
  String get bondSlashBuyerDetail =>
      'Der Käufer verliert seine Einlage; der Verkäufer kann seinen Anteil einfordern.';

  @override
  String get bondSlashSeller => 'Einlage des Verkäufers einziehen';

  @override
  String get bondSlashSellerDetail =>
      'Der Verkäufer verliert seine Einlage; der Käufer kann seinen Anteil einfordern.';

  @override
  String get bondSlashBoth => 'Beide Einlagen einziehen';

  @override
  String get bondSlashBothDetail => 'Beide verlieren ihre Einlage.';

  @override
  String get bondNotPostedTitle => 'Diese Partei hat keine Einlage hinterlegt';

  @override
  String get bondNotPostedBody =>
      'Der Node hat keine Einlage der Partei, deren Einlage du einziehen wolltest, daher wurde nichts bezahlt oder erstattet. Wähle eine andere Einlage-Option.';

  @override
  String get bondChooseAgain => 'Andere Option wählen';

  @override
  String get resolvedSlashedBuyer =>
      'Die Einlage des Käufers wurde eingezogen.';

  @override
  String get resolvedSlashedSeller =>
      'Die Einlage des Verkäufers wurde eingezogen.';

  @override
  String get resolvedSlashedBoth => 'Beide Einlagen wurden eingezogen.';

  @override
  String get detailBonds => 'Einlagen';

  @override
  String get detailPreviousStatus => 'Status vor dem Streitfall';

  @override
  String get orderStatusActive => 'Aktiv';

  @override
  String get orderStatusFiatSent => 'Fiat gesendet';
}
