// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Bosstro';

  @override
  String get navPending => 'In attesa';

  @override
  String get navInProgress => 'Le mie dispute';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get noNodeSelected => 'Nessun nodo selezionato';

  @override
  String get pendingTitle => 'Dispute in attesa';

  @override
  String get pendingEmptyTitle => 'Nessuna disputa in attesa';

  @override
  String get pendingEmptyBody =>
      'Nessuna disputa di questo nodo è in attesa di un solver. Quando un\'operazione ne apre una, compare qui perché tu la prenda in carico.';

  @override
  String get inProgressTitle => 'Le tue dispute';

  @override
  String get inProgressEmptyTitle => 'Nessuna disputa in corso';

  @override
  String get inProgressEmptyBody =>
      'Le dispute che prendi in carico compaiono qui. Se una presa in carico non ha avuto risposta, recupera la disputa.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsGroupApp => 'Applicazione';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get languageSheetTitle => 'Scegli una lingua';

  @override
  String get languageSystem => 'Lingua di sistema';

  @override
  String languageSystemDetail(String language) {
    return 'Come il tuo dispositivo: $language';
  }

  @override
  String get aboutTitle => 'Informazioni';

  @override
  String get aboutTagline => 'L\'app dei solver delle dispute di Mostro';

  @override
  String get aboutLicense => 'Licenza';

  @override
  String get aboutLicenseName => 'AGPLv3+';

  @override
  String get aboutLicenseDialogTitle =>
      'Licenza Pubblica Generica Affero GNU v3';

  @override
  String get aboutSourceCode => 'Codice sorgente';

  @override
  String get aboutOpenSourceLicenses => 'Licenze open source';

  @override
  String get aboutLinkCopied => 'Impossibile aprire il browser: link copiato';

  @override
  String get copied => 'Copiato';

  @override
  String get chatKeyCopied =>
      'Chiave della chat copiata. Verrà cancellata dagli appunti tra 60 secondi.';

  @override
  String get chatCopyHint => 'Copia il messaggio';

  @override
  String get idLabel => 'ID';

  @override
  String get copyIdHint => 'Copia ID';

  @override
  String get easterEggWhitepaper =>
      '31 ottobre 2008: nove pagine, senza il permesso di nessuno. Buon Halloween.';

  @override
  String get easterEggGenesis =>
      'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks';

  @override
  String get easterEggPizzaDay =>
      '22 maggio 2010: 10.000 BTC per due pizze. Speriamo fossero buone.';

  @override
  String get welcomeTitle => 'Risolvi le dispute di Mostro';

  @override
  String get welcomeBody =>
      'Prendi in carico le dispute di un nodo, parla con l\'acquirente e il venditore e chiudile, dal tuo telefono.';

  @override
  String get welcomeLogIn => 'Accedi';

  @override
  String get welcomeCreateAccount => 'Crea nuovo account';

  @override
  String get welcomeKeyUnreadable =>
      'Impossibile leggere la chiave salvata su questo telefono. Accedi di nuovo con la tua chiave segreta. Se accedi con un\'altra chiave, questa sostituisce quella salvata.';

  @override
  String get traderKeyWarning =>
      'Non usare mai la chiave con cui fai trading. Una chiave di solver che è anche una chiave di trading collega pubblicamente i due ruoli.';

  @override
  String get loginTitle => 'Accedi';

  @override
  String get loginHeading => 'La tua chiave segreta di solver';

  @override
  String get loginBody =>
      'Incolla o scansiona la chiave segreta (nsec) il cui npub l\'operatore del tuo nodo ha registrato come solver.';

  @override
  String get loginBodyPaste =>
      'Incolla la chiave segreta (nsec) il cui npub l\'operatore del tuo nodo ha registrato come solver.';

  @override
  String get secretKeyHint => 'nsec1…';

  @override
  String get showSecretKey => 'Mostra chiave';

  @override
  String get hideSecretKey => 'Nascondi chiave';

  @override
  String get pasteAction => 'Incolla';

  @override
  String get scanQrAction => 'Scansiona QR';

  @override
  String get clipboardEmpty => 'Gli appunti sono vuoti.';

  @override
  String get loginContinue => 'Continua';

  @override
  String get keyErrorEmpty => 'Inserisci la tua chiave segreta.';

  @override
  String get keyErrorPublicKey =>
      'Questa è una chiave pubblica (npub). Per accedere serve la chiave segreta (nsec).';

  @override
  String get keyErrorInvalid =>
      'Questa non è una chiave segreta valida. Inserisci una chiave nsec1… o la sua forma hex di 64 caratteri.';

  @override
  String get loginConfirmHeading => 'È questo l\'npub registrato come solver?';

  @override
  String get loginConfirmBody =>
      'Confrontalo con l\'npub aggiunto dall\'operatore del tuo nodo. Se non è lo stesso, questa chiave non può risolvere dispute su quel nodo.';

  @override
  String get loginConfirmAnswer => 'Sì, accedi';

  @override
  String get loginConfirmBack => 'No, usa un\'altra chiave';

  @override
  String get keySaveFailed =>
      'Impossibile salvare la chiave su questo telefono. Riprova.';

  @override
  String get npubLabel => 'npub';

  @override
  String get secretKeyLabel => 'Chiave segreta (nsec)';

  @override
  String get copyNpub => 'Copia npub';

  @override
  String get copySecretKey => 'Copia chiave segreta';

  @override
  String get shareNpub => 'Condividi npub';

  @override
  String get npubQrLabel => 'Codice QR del tuo npub';

  @override
  String get scanTitle => 'Scansiona QR';

  @override
  String get scanHint => 'Inquadra il codice QR della tua chiave segreta.';

  @override
  String get scanUnavailable =>
      'La fotocamera non è disponibile. Torna indietro e incolla la chiave.';

  @override
  String get createTitle => 'Crea nuovo account';

  @override
  String get createKeyHeading => 'La tua nuova chiave segreta';

  @override
  String get createKeyBody =>
      'È l\'unico modo per accedere a questo account. Annotala in un posto sicuro e privato: chiunque la possieda può risolvere dispute a tuo nome.';

  @override
  String get createBackupConfirm =>
      'Ho salvato la mia chiave segreta in un posto sicuro';

  @override
  String get createContinue => 'Continua';

  @override
  String get createNpubHeading => 'Il tuo npub';

  @override
  String get createNpubBody =>
      'Invia questo npub all\'operatore del tuo nodo perché ti registri come solver. Fino ad allora puoi vedere le dispute, ma non prenderle in carico.';

  @override
  String get createDone => 'Scegli il tuo nodo';

  @override
  String get settingsGroupKey => 'Chiave di solver';

  @override
  String get settingsNpub => 'Il tuo npub';

  @override
  String get settingsBackup => 'Backup della chiave segreta';

  @override
  String get settingsLogOut => 'Esci dall\'account';

  @override
  String get backupWarnTitle => 'Mostrare la tua chiave segreta?';

  @override
  String get backupWarnBody =>
      'Chiunque la veda può risolvere dispute a tuo nome. Assicurati che nessuno stia guardando il tuo schermo.';

  @override
  String get backupWarnAnswer => 'Mostra chiave segreta';

  @override
  String get cancel => 'Annulla';

  @override
  String get backupTitle => 'Backup della chiave segreta';

  @override
  String get backupBody =>
      'Conservala in un posto sicuro e privato. È l\'unico modo per accedere a questo account su un altro telefono.';

  @override
  String get backupUnavailable =>
      'Impossibile leggere la chiave segreta su questo telefono.';

  @override
  String get logOutTitle => 'Uscire dall\'account?';

  @override
  String get logOutBody =>
      'La tua chiave segreta verrà rimossa da questo telefono. Senza un backup non potrai più accedere a questo account.';

  @override
  String get logOutAnswer => 'Esci dall\'account';

  @override
  String get logOutFailed => 'Impossibile uscire dall\'account. Riprova.';

  @override
  String get secretKeyCopied =>
      'Chiave segreta copiata. Verrà cancellata dagli appunti tra 60 secondi.';

  @override
  String linkOnline(int connected, int total) {
    return 'Online · $connected/$total relay';
  }

  @override
  String get linkConnecting => 'Connessione ai relay…';

  @override
  String get linkOffline => 'Offline · nessun relay risponde';

  @override
  String get chooseNodeTitle => 'Scegli il tuo nodo';

  @override
  String get chooseNodeBody =>
      'Scegli il nodo Mostro il cui operatore ha registrato la tua chiave come solver. Puoi cambiare nodo più tardi nelle Impostazioni.';

  @override
  String get chooseNodeAppBar => 'Nodo';

  @override
  String get nodeChipTrusted => 'Di fiducia';

  @override
  String get nodeChipCustom => 'Aggiunto da te';

  @override
  String get nodeChipActive => 'Attivo';

  @override
  String get nodeAddOwn => 'Aggiungi il tuo nodo';

  @override
  String get nodeInfoTooltip => 'Informazioni del nodo';

  @override
  String nodeSwitched(String name) {
    return 'Ora stai usando $name';
  }

  @override
  String get nodeSelectFailed => 'Impossibile passare a questo nodo. Riprova.';

  @override
  String get nodeListFailed =>
      'Impossibile caricare la lista dei nodi. Riavvia l\'app per riprovare.';

  @override
  String get addNodeTitle => 'Aggiungi un nodo';

  @override
  String get addNodeBody =>
      'Incolla la chiave pubblica del nodo (npub o hex). Te la può dare il suo operatore.';

  @override
  String get addNodePubkeyLabel => 'Chiave pubblica';

  @override
  String get addNodeNameLabel => 'Nome (facoltativo)';

  @override
  String get addNodeAnswer => 'Aggiungi nodo';

  @override
  String get nodeErrorInvalidPubkey =>
      'Inserisci una chiave pubblica valida (npub o 64 caratteri hex).';

  @override
  String get nodeErrorPrivateKey =>
      'Questa è una chiave segreta — non condividerla mai. Inserisci la chiave pubblica del nodo.';

  @override
  String get nodeErrorAlreadyExists => 'Questo nodo è già nella lista.';

  @override
  String get nodeErrorActive =>
      'Questo è il tuo nodo attivo. Passa a un altro nodo prima di rimuoverlo.';

  @override
  String get nodeErrorStorage =>
      'Impossibile salvare i tuoi nodi su questo dispositivo.';

  @override
  String get nodeErrorGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get removeNodeAction => 'Rimuovi nodo';

  @override
  String get removeNodeTitle => 'Rimuovere questo nodo?';

  @override
  String get removeNodeBody =>
      'Verrà tolto dalla tua lista. Puoi aggiungerlo di nuovo con la sua chiave pubblica.';

  @override
  String get removeNodeAnswer => 'Rimuovi nodo';

  @override
  String get nodeRemoved => 'Nodo rimosso';

  @override
  String get nodeInfoTitle => 'Informazioni del nodo';

  @override
  String get nodeInfoUse => 'Usa questo nodo';

  @override
  String get nodeInfoGroupNode => 'Nodo';

  @override
  String get nodeInfoPubkey => 'Chiave pubblica';

  @override
  String get nodeInfoRegion => 'Regione';

  @override
  String get nodeInfoWebsite => 'Sito web';

  @override
  String get nodeInfoAbout => 'Descrizione';

  @override
  String get nodeInfoEmptyTitle => 'Ancora nessuna informazione dell\'istanza';

  @override
  String get nodeInfoEmptyBody =>
      'Questo nodo non ha pubblicato le informazioni della sua istanza sui tuoi relay, oppure questi non hanno ancora risposto. Vengono richieste di nuovo ogni volta che apri questa schermata.';

  @override
  String get nodeInfoRefreshFailed =>
      'I relay non hanno risposto. Queste sono le ultime informazioni viste.';

  @override
  String get nodeInfoStale =>
      'Queste informazioni hanno più di 7 giorni e potrebbero non essere aggiornate.';

  @override
  String nodeInfoUnsupported(int version) {
    return 'Questo nodo usa il protocollo v$version. Bosstro usa solo la v2, quindi lì non può risolvere dispute.';
  }

  @override
  String get nodeInfoUpdatedNow => 'Aggiornate poco fa';

  @override
  String nodeInfoUpdatedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiornate $count minuti fa',
      one: 'Aggiornate 1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiornate $count ore fa',
      one: 'Aggiornate 1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiornate $count giorni fa',
      one: 'Aggiornate 1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get nodeInfoGroupProtocol => 'Protocollo';

  @override
  String get nodeInfoProtocolVersion => 'Versione del protocollo';

  @override
  String get nodeInfoTransport => 'Trasporto';

  @override
  String get nodeInfoGroupDaemon => 'Daemon di Mostro';

  @override
  String get nodeInfoVersion => 'Versione';

  @override
  String get nodeInfoCommit => 'Commit';

  @override
  String get nodeInfoMaxOrder => 'Ordine massimo';

  @override
  String get nodeInfoMinOrder => 'Ordine minimo';

  @override
  String get nodeInfoExpirationHours => 'Scadenza degli ordini';

  @override
  String get nodeInfoExpirationSeconds => 'Scadenza degli ordini presi';

  @override
  String get nodeInfoHoldWindow => 'Finestra fattura di trattenuta';

  @override
  String get nodeInfoHoldCltv => 'Delta CLTV fattura di trattenuta';

  @override
  String get nodeInfoInvoiceWindow => 'Finestra della fattura';

  @override
  String get nodeInfoMaxOrders => 'Ordini massimi per risposta';

  @override
  String get nodeInfoFee => 'Commissione';

  @override
  String get nodeInfoPow => 'PoW richiesto';

  @override
  String get nodeInfoPowFirst => 'PoW al primo contatto';

  @override
  String get nodeInfoBonds => 'Depositi anti-abuso';

  @override
  String get nodeInfoGroupLightning => 'Nodo Lightning';

  @override
  String get nodeInfoAlias => 'Alias';

  @override
  String get nodeInfoLnPubkey => 'Chiave pubblica del nodo';

  @override
  String get nodeInfoLndVersion => 'Versione LND';

  @override
  String get nodeInfoChains => 'Catene';

  @override
  String get nodeInfoNetworks => 'Reti';

  @override
  String get nodeInfoUri => 'URI';

  @override
  String get nodeInfoGroupFiat => 'Valute fiat';

  @override
  String get nodeInfoFiatAll => 'Sono accettate tutte le valute.';

  @override
  String get nodeInfoUnknown => 'Non disponibile';

  @override
  String get nodeInfoEnabled => 'Attivati';

  @override
  String get nodeInfoDisabled => 'Disattivati';

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
      other: '$count blocchi',
      one: '1 blocco',
    );
    return '$_temp0';
  }

  @override
  String unitBits(int count) {
    return '$count bit';
  }

  @override
  String unitPercent(String value) {
    return '$value %';
  }

  @override
  String get relaysTitle => 'Relay';

  @override
  String get relaysBody =>
      'Bosstro comunica con il tuo nodo tramite questi relay. I relay annunciati dal tuo nodo vengono aggiunti automaticamente.';

  @override
  String get relayStatusConnected => 'Connesso';

  @override
  String get relayStatusConnecting => 'In connessione';

  @override
  String get relayStatusDisconnected => 'Disconnesso';

  @override
  String get relayStatusError => 'Rifiutato';

  @override
  String get relaySourceDefault => 'Predefinito';

  @override
  String get relaySourceNode => 'Dal tuo nodo';

  @override
  String get relaySourceUser => 'Aggiunto da te';

  @override
  String get relayAdd => 'Aggiungi relay';

  @override
  String get addRelayTitle => 'Aggiungi un relay';

  @override
  String get addRelayLabel => 'Indirizzo del relay';

  @override
  String get addRelayAnswer => 'Aggiungi relay';

  @override
  String get relayRemoveTooltip => 'Rimuovi relay';

  @override
  String get removeRelayTitle => 'Rimuovere questo relay?';

  @override
  String get removeRelayBody =>
      'Bosstro smette di usarlo. Un relay annunciato dal tuo nodo torna solo se lo aggiungi tu.';

  @override
  String get removeRelayAnswer => 'Rimuovi relay';

  @override
  String get relayErrorInvalidUrl =>
      'Inserisci un indirizzo di relay che inizi con wss://.';

  @override
  String get relayErrorExists => 'Questo relay è già nella lista.';

  @override
  String get relayErrorLast =>
      'Questo è il tuo ultimo relay. Aggiungine un altro prima di rimuoverlo.';

  @override
  String get relaysNotRunningTitle => 'I relay non si sono avviati';

  @override
  String get relaysNotRunningBody =>
      'Bosstro non è riuscito ad aprire la connessione con i relay. Riavvia l\'app per riprovare.';

  @override
  String get settingsGroupNode => 'Nodo';

  @override
  String get settingsNode => 'Nodo';

  @override
  String get settingsNodeNone => 'Scegli';

  @override
  String get settingsNodeInfo => 'Informazioni del nodo';

  @override
  String get settingsRelays => 'Relay';

  @override
  String settingsRelaysValue(int connected, int total) {
    return '$connected/$total';
  }

  @override
  String get pendingNoNodeTitle => 'Prima scegli il tuo nodo';

  @override
  String get pendingNoNodeBody =>
      'Le dispute vengono lette da un nodo Mostro alla volta. Scegli il nodo in cui sei solver.';

  @override
  String get pendingNoNodeAction => 'Scegli nodo';

  @override
  String get loadingNodes => 'Caricamento dei nodi';

  @override
  String get loadingNodeInfo => 'Caricamento delle informazioni del nodo';

  @override
  String get loadingRelays => 'Caricamento dei relay';

  @override
  String get loadingDisputes => 'Caricamento delle dispute';

  @override
  String get pendingLoadErrorTitle => 'Impossibile leggere le dispute';

  @override
  String get pendingLoadErrorBody =>
      'Qualcosa è andato storto leggendo su questo telefono le dispute di questo nodo. Chiudi e riapri Bosstro per riprovare.';

  @override
  String get disputeStatusInitiated => 'In attesa di un solver';

  @override
  String get disputeStatusInProgress => 'In corso';

  @override
  String get disputeStatusSettled => 'Acquirente pagato';

  @override
  String get disputeStatusSellerRefunded => 'Venditore rimborsato';

  @override
  String get disputeStatusReleased => 'Rilasciata dal venditore';

  @override
  String get disputeStatusCooperativelyCanceled => 'Annullata dalle parti';

  @override
  String get disputeOpenedByBuyer => 'Aperta dall\'acquirente';

  @override
  String get disputeOpenedBySeller => 'Aperta dal venditore';

  @override
  String get disputeOpenedByUnknown => 'Non si sa chi l\'ha aperta';

  @override
  String get disputeOpenedJustNow => 'Aperta poco fa';

  @override
  String disputeOpenedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aperta $count minuti fa',
      one: 'Aperta 1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aperta $count ore fa',
      one: 'Aperta 1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aperta $count giorni fa',
      one: 'Aperta 1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get disputeOpenedUnknown => 'Ora di apertura sconosciuta';

  @override
  String disputeRowLabel(String id) {
    return 'Disputa $id';
  }

  @override
  String get close => 'Chiudi';

  @override
  String get takeDisputeHint => 'Prendi in carico la disputa';

  @override
  String get takeDisputeTitle => 'Prendere in carico questa disputa?';

  @override
  String get takeDisputeBody =>
      'Diventi il suo solver: il nodo avvisa l\'acquirente e il venditore, e la disputa passa in «Le tue dispute». Prendi in carico solo una disputa che puoi seguire fino alla fine.';

  @override
  String get takeDisputeAnswer => 'Prendi in carico';

  @override
  String get takeTakenSnack =>
      'Disputa presa in carico. È in «Le tue dispute».';

  @override
  String get recoverAction => 'Recupera';

  @override
  String get recoverTitle => 'Recupera una disputa';

  @override
  String get recoverNote =>
      'Il nodo non pubblica chi ha in carico una disputa. Per questo la lista mostra tutte le dispute in corso su questo nodo che non sono in «Le tue dispute» su questo telefono: le tue la cui risposta è andata persa e quelle di altri solver. Recuperale una alla volta.';

  @override
  String get recoverEmptyTitle => 'Niente da recuperare';

  @override
  String get recoverEmptyBody =>
      'Nessuna disputa in corso su questo nodo manca da «Le tue dispute».';

  @override
  String get recoverDisputeHint => 'Recupera la disputa';

  @override
  String get recoverDisputeTitle => 'Recuperare questa disputa?';

  @override
  String get recoverDisputeBody =>
      'Bosstro chiede di nuovo questa disputa al nodo. Se è tua, il nodo ti rimanda i suoi dati. Se ce l\'ha in carico un altro solver, il nodo dice di no, a meno che quel solver non sia di sola lettura, come Serbero, e la tua chiave possa pagare l\'acquirente e rimborsare il venditore: allora la disputa diventa tua (un subentro).';

  @override
  String get recoverDisputeAnswer => 'Recupera la disputa';

  @override
  String get recoverTakenSnack => 'Disputa recuperata. È in «Le tue dispute».';

  @override
  String get notSolverTitle => 'Non sei solver su questo nodo';

  @override
  String get notSolverBody =>
      'Passa al tuo nodo per risolvere dispute. Se questo è il tuo nodo, invia il tuo npub al suo operatore.';

  @override
  String get switchNodeAction => 'Cambia nodo';

  @override
  String get cannotTakeOverTitle =>
      'Un altro solver ha in carico questa disputa';

  @override
  String get cannotTakeOverBody =>
      'Si può subentrare solo in una disputa in carico a un solver di sola lettura, come Serbero, e può farlo solo un solver che può pagare l\'acquirente e rimborsare il venditore.';

  @override
  String get takeRefusedTitle => 'Il nodo non ti ha dato questa disputa';

  @override
  String get takeRefusedBody =>
      'Ha rifiutato la richiesta. Riprova più tardi o chiedi all\'operatore del nodo.';

  @override
  String get takeRefusedNotFoundBody =>
      'Il nodo non ha più l\'ordine di questa disputa.';

  @override
  String get noAnswerTitle => 'Il nodo non ha risposto';

  @override
  String get noAnswerBody =>
      'La tua richiesta potrebbe essergli arrivata comunque, quindi Bosstro non l\'ha inviata di nuovo. Tra un momento guarda in «Le tue dispute», o richiedila da «Recupera una disputa».';

  @override
  String get takeFailedTitle => 'La richiesta non è stata inviata';

  @override
  String get takeFailedBody =>
      'Nessun relay l\'ha accettata. Controlla la connessione e i relay, poi riprova.';

  @override
  String get takeAlreadyTakingBody =>
      'Una richiesta per questa disputa è già in attesa della risposta del nodo.';

  @override
  String get takeClosedBody =>
      'Questa disputa è chiusa: non c\'è nulla da prendere in carico.';

  @override
  String get takeUnknownBody =>
      'Questa disputa non è tra le dispute di questo nodo su questo telefono.';

  @override
  String get takeProtocolBody =>
      'Questo nodo annuncia un\'altra versione del protocollo. Bosstro comunica solo con nodi del protocollo 2.';

  @override
  String get takeNodeInfoBody =>
      'Bosstro non è riuscito a leggere le impostazioni di questo nodo, quindi non conosce la proof of work che il nodo richiede. Controlla i relay e riprova.';

  @override
  String get disputeTakenJustNow => 'Presa in carico poco fa';

  @override
  String disputeTakenMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Presa in carico $count minuti fa',
      one: 'Presa in carico 1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Presa in carico $count ore fa',
      one: 'Presa in carico 1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Presa in carico $count giorni fa',
      one: 'Presa in carico 1 giorno fa',
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
  String get disputeAmountUnknown => 'Importo sconosciuto';

  @override
  String get settingsSolverStatus => 'Solver su questo nodo';

  @override
  String get settingsSolverYes => 'Sì';

  @override
  String get settingsSolverNo => 'No';

  @override
  String get settingsPermission => 'Permesso';

  @override
  String get permissionRead => 'Solo mediazione';

  @override
  String get permissionReadWrite => 'Mediazione, pagamenti e rimborsi';

  @override
  String get disputeDetailTitle => 'Disputa';

  @override
  String get detailSegmentInfo => 'Info';

  @override
  String get detailSegmentBuyer => 'Acquirente';

  @override
  String get detailSegmentSeller => 'Venditore';

  @override
  String get detailSegmentsLabel => 'Sezioni della disputa';

  @override
  String get detailDisputeId => 'ID della disputa';

  @override
  String get detailOrderId => 'ID dell\'ordine';

  @override
  String get detailStatus => 'Stato';

  @override
  String get detailOpenedBy => 'Aperta da';

  @override
  String get detailOpenedAt => 'Aperta';

  @override
  String get detailTakenAt => 'Presa in carico';

  @override
  String get detailAmount => 'Importo';

  @override
  String get detailCurrency => 'Valuta';

  @override
  String get detailFactsTitle => 'Informazioni sulla disputa';

  @override
  String get detailFiatAmount => 'Importo fiat';

  @override
  String get detailPaymentMethod => 'Metodo di pagamento';

  @override
  String get detailPremium => 'Premio';

  @override
  String get detailFee => 'Commissione del nodo';

  @override
  String get detailOrderKind => 'Tipo di ordine';

  @override
  String get detailBuyerKey => 'Chiave di operazione dell\'acquirente';

  @override
  String get detailSellerKey => 'Chiave di operazione del venditore';

  @override
  String get detailPartyBuyer => 'Acquirente';

  @override
  String get detailPartySeller => 'Venditore';

  @override
  String get detailPartyUnknown => 'Non disponibile';

  @override
  String get detailOrderKindBuy => 'Ordine di acquisto';

  @override
  String get detailOrderKindSell => 'Ordine di vendita';

  @override
  String detailPremiumValue(String value) {
    return '$value %';
  }

  @override
  String get detailNotYoursTitle => 'Questa disputa ora non è tua';

  @override
  String get detailNotYoursBody =>
      'Il nodo l\'ha riaperta, oppure appartiene a un\'altra chiave. Non è più in «Le tue dispute».';

  @override
  String get chatSenderYou => 'Tu';

  @override
  String get chatSenderBuyer => 'Acquirente';

  @override
  String get chatSenderSeller => 'Venditore';

  @override
  String get chatEmptyBuyerTitle => 'Nessun messaggio con l\'acquirente';

  @override
  String get chatEmptySellerTitle => 'Nessun messaggio con il venditore';

  @override
  String get chatEmptyBody =>
      'Solo tu e questa parte potete leggere questa conversazione. L\'altra parte non la vede.';

  @override
  String get chatNoPartyKeyTitle => 'Nessuna chat con questa parte';

  @override
  String get chatNoPartyKeyBody =>
      'La risposta del nodo alla presa in carico non includeva la chiave di questa parte, quindi Bosstro non può contattarla.';

  @override
  String get chatClosedNote =>
      'Questa disputa è chiusa. La chat è di sola lettura.';

  @override
  String get chatComposerBuyerHint => 'Scrivi all\'acquirente';

  @override
  String get chatComposerSellerHint => 'Scrivi al venditore';

  @override
  String get chatSend => 'Invia';

  @override
  String get chatSending => 'Invio…';

  @override
  String get chatNotSent => 'Non inviato';

  @override
  String get chatRetry => 'Riprova';

  @override
  String get chatErrorTooLong =>
      'Il messaggio è troppo lungo. Dividilo in due.';

  @override
  String get chatErrorClosed =>
      'Questa disputa è chiusa. La chat è di sola lettura.';

  @override
  String get chatErrorNoRelays =>
      'Non sei connesso a nessun relay. Controlla la connessione.';

  @override
  String get chatErrorNotYours => 'Questa disputa non è più tua.';

  @override
  String get chatErrorGeneric => 'Impossibile inviare il messaggio.';

  @override
  String get chatLoading => 'Caricamento dei messaggi';

  @override
  String chatMessageLabel(String sender, String time, String text) {
    return '$sender, $time: $text';
  }

  @override
  String get openDisputeHint => 'Apri la disputa';

  @override
  String get chatAttach => 'Allega un file';

  @override
  String get attachSheetTitle => 'Allega';

  @override
  String get attachSourcePhoto => 'Foto dalla galleria';

  @override
  String get attachSourceCamera => 'Scatta una foto';

  @override
  String get attachSourcePdf => 'Documento PDF';

  @override
  String get attachSheetNote =>
      'Il file viene cifrato su questo dispositivo. Solo tu e questa parte potete aprirlo. JPEG, PNG o PDF, fino a 25 MB.';

  @override
  String get attachConfirmTitle => 'Inviare questo file?';

  @override
  String attachConfirmBuyer(String name, String size) {
    return '$name ($size) va all\'acquirente, cifrato. Una foto viene inviata senza la sua posizione né i dati della fotocamera.';
  }

  @override
  String attachConfirmSeller(String name, String size) {
    return '$name ($size) va al venditore, cifrato. Una foto viene inviata senza la sua posizione né i dati della fotocamera.';
  }

  @override
  String get attachmentTooLarge => 'Il file supera i 25 MB.';

  @override
  String get attachmentUnsupported =>
      'Si possono inviare solo immagini JPEG e PNG e documenti PDF.';

  @override
  String get attachmentInvalidImage => 'Impossibile leggere l\'immagine.';

  @override
  String get attachmentReadFailed => 'Impossibile leggere il file.';

  @override
  String get attachmentUploadFailed =>
      'Impossibile caricare il file. Controlla la connessione e riprova.';

  @override
  String get attachmentSendFailed => 'Impossibile inviare il file.';

  @override
  String get attachmentUploading => 'Cifratura e invio…';

  @override
  String get attachmentDiscard => 'Scarta';

  @override
  String get attachmentLoading => 'Decifratura del file';

  @override
  String get attachmentNotVerified => 'Impossibile verificare il file.';

  @override
  String get attachmentDownloadFailed => 'Impossibile scaricare il file.';

  @override
  String get attachmentUnsupportedReceived =>
      'Questo tipo di file non si può aprire qui.';

  @override
  String get attachmentOpenFailed => 'Impossibile aprire il file.';

  @override
  String attachmentImageLabel(String name) {
    return 'Immagine $name';
  }

  @override
  String get attachmentOpenImage => 'Apri l\'immagine';

  @override
  String get attachmentSave => 'Salva';

  @override
  String get attachmentSaveHint => 'Salva il file';

  @override
  String get attachmentSaved => 'Salvato';

  @override
  String get attachmentSaveFailed => 'Impossibile salvare il file.';

  @override
  String attachmentFileLabel(String name, String details) {
    return '$name, $details';
  }

  @override
  String get attachmentViewerZoomHint => 'Pizzica per ingrandire';

  @override
  String get observerTitle => 'Chat tra le parti';

  @override
  String observerSharedByBuyer(String date) {
    return 'L\'acquirente ha condiviso la sua chiave della chat il $date.';
  }

  @override
  String observerSharedBySeller(String date) {
    return 'Il venditore ha condiviso la sua chiave della chat il $date.';
  }

  @override
  String get observerPastedKey =>
      'Hai incollato una chiave della chat per questa disputa.';

  @override
  String get observerStoredOnly =>
      'Messaggi conservati da una lettura precedente. Incolla ancora la chiave della chat per cercare messaggi nuovi.';

  @override
  String get observerNoKey =>
      'Nessuna delle parti ha ancora condiviso la sua chiave della chat. Se una delle due te la invia in un altro modo, incollala qui.';

  @override
  String get observerReadAction => 'Leggi la chat tra le parti';

  @override
  String get observerPasteAction => 'Incolla una chiave della chat';

  @override
  String get observerRefresh => 'Aggiorna';

  @override
  String get observerReadOnlyBuyer =>
      'Sola lettura, con la chiave condivisa dall\'acquirente.';

  @override
  String get observerReadOnlySeller =>
      'Sola lettura, con la chiave condivisa dal venditore.';

  @override
  String get observerReadOnlyBoth =>
      'Sola lettura, con la chiave condivisa da entrambe le parti.';

  @override
  String get observerReadOnlyPasted =>
      'Sola lettura, con una chiave che hai incollato.';

  @override
  String get observerReadOnlyStored =>
      'Sola lettura: messaggi di una lettura precedente.';

  @override
  String get observerNoKeyTitle => 'Ancora nessuna chiave della chat';

  @override
  String get observerOpensNothingTitle =>
      'La chiave non apre nessun messaggio di questa disputa';

  @override
  String observerOpensNothingBody(String date) {
    return 'Nessun messaggio dell\'acquirente o del venditore di questa disputa dal $date si apre con questa chiave. Potrebbe essere la chiave di un\'altra operazione, oppure in quel periodo non hanno scritto.';
  }

  @override
  String get observerReadFailedTitle => 'Impossibile interrogare i relay';

  @override
  String get observerReadFailedBody => 'Controlla la connessione e riprova.';

  @override
  String get observerNoPartyKeysTitle => 'Le parti non sono note';

  @override
  String get observerNoPartyKeysBody =>
      'Il nodo non ha indicato le chiavi di operazione dell\'acquirente e del venditore, quindi nessun messaggio può essere mostrato come loro.';

  @override
  String get observerPasteTitle => 'Incolla una chiave della chat';

  @override
  String get observerPasteBody =>
      'Una parte può inviarti la chiave della sua chat con l\'altra parte. Con questa puoi leggere quella chat, ma non scriverci mai.';

  @override
  String get observerPasteHint => '64 caratteri esadecimali';

  @override
  String get observerPasteConfirm => 'Leggi la chat';

  @override
  String get observerInvalidKey =>
      'Questa non è una chiave della chat: una chiave della chat ha 64 caratteri esadecimali, da soli o dopo «Shared key: ».';

  @override
  String observerOpensNothingShort(String date) {
    return 'La chiave non apre nessun messaggio di questa disputa dal $date.';
  }

  @override
  String get observerNotYours => 'Questa disputa non è più tua su questo nodo.';

  @override
  String get observerFileLocked =>
      'Non si può aprire con una chiave della chat.';

  @override
  String get observerFileAdviceBuyer =>
      'Chiedi all\'acquirente di inviartelo nella sua chat con te.';

  @override
  String get observerFileAdviceSeller =>
      'Chiedi al venditore di inviartelo nella sua chat con te.';

  @override
  String get observerFileImage => 'Immagine';

  @override
  String get observerFileOther => 'File';

  @override
  String get resolveCardTitle => 'Risolvi la disputa';

  @override
  String get resolveCardBody =>
      'Dopo aver ascoltato entrambe le parti, decidi dove vanno i sats. Non si può tornare indietro.';

  @override
  String get payBuyerAction => 'Paga l\'acquirente';

  @override
  String get refundSellerAction => 'Rimborsa il venditore';

  @override
  String get payBuyerAnswer => 'Paga l\'acquirente';

  @override
  String get refundSellerAnswer => 'Rimborsa il venditore';

  @override
  String get resolveReadOnlyNote =>
      'La tua chiave di solver può mediare su questo nodo, ma non pagare né rimborsare. Chiedi all\'operatore il permesso di lettura e scrittura.';

  @override
  String get resolveUnansweredPayNote =>
      'La tua richiesta di pagare l\'acquirente non ha avuto risposta. Il nodo potrebbe aver pagato comunque: controlla lo stato della disputa prima di riprovare.';

  @override
  String get resolveUnansweredRefundNote =>
      'La tua richiesta di rimborsare il venditore non ha avuto risposta. Il nodo potrebbe aver rimborsato comunque: controlla lo stato della disputa prima di riprovare.';

  @override
  String get payBuyerTitle => 'Pagare l\'acquirente?';

  @override
  String get refundSellerTitle => 'Rimborsare il venditore?';

  @override
  String get payBuyerRecipient => 'L\'acquirente riceve';

  @override
  String get refundSellerRecipient => 'Al venditore tornano';

  @override
  String payBuyerBreakdown(String amount, String fee) {
    return 'I $amount dell\'ordine meno la commissione del nodo di $fee.';
  }

  @override
  String refundSellerBreakdown(String amount, String fee) {
    return 'I $amount dell\'ordine più la commissione del nodo di $fee, come li ha bloccati il venditore.';
  }

  @override
  String resolveTradeFiat(String fiat) {
    return 'Operazione: $fiat';
  }

  @override
  String get payBuyerOtherSide =>
      'La fattura di trattenuta del venditore viene liquidata: il venditore non riavrà questi sats.';

  @override
  String get refundSellerOtherSide =>
      'La fattura di trattenuta del venditore viene annullata: l\'acquirente non riceve nulla da questa operazione.';

  @override
  String get resolveBondsUnknown =>
      'Bosstro non sa se questo nodo usa depositi: le sue informazioni non si sono potute leggere o non lo dicono. Se ce ne sono, nessuno viene confiscato.';

  @override
  String get resolveIrreversible =>
      'Non si può tornare indietro. Una volta inviata la richiesta, Bosstro non la reinvia mai da solo.';

  @override
  String get resolveWaiting =>
      'In attesa della risposta del nodo. Tieni Bosstro aperto.';

  @override
  String get resolvedPaidTitle => 'Risolta: hai pagato l\'acquirente';

  @override
  String get resolvedPaidBody =>
      'Il nodo ha liquidato la fattura di trattenuta del venditore e paga l\'acquirente. La disputa è chiusa.';

  @override
  String get resolvedRefundedTitle => 'Risolta: hai rimborsato il venditore';

  @override
  String get resolvedRefundedBody =>
      'Il nodo ha annullato la fattura di trattenuta del venditore: i sats tornano al venditore. La disputa è chiusa.';

  @override
  String get resolvedCoopTitle => 'Le parti avevano già annullato';

  @override
  String get resolvedCoopBody =>
      'Acquirente e venditore hanno annullato l\'operazione tra loro prima della tua richiesta, quindi non hai pagato né rimborsato nulla. La disputa è chiusa.';

  @override
  String get readOnlySolverTitle =>
      'Non puoi pagare né rimborsare su questo nodo';

  @override
  String get takenOverTitle =>
      'Ora un altro solver ha in carico questa disputa';

  @override
  String get takenOverBody =>
      'Il nodo l\'ha data a un altro solver, quindi non è stato pagato né rimborsato nulla. È uscita da «Le tue dispute».';

  @override
  String get notInDisputeTitle => 'Questo ordine non è più in disputa';

  @override
  String get notInDisputeBody =>
      'È già stato pagato, rimborsato o rilasciato, forse da una richiesta precedente la cui risposta è andata persa. Lo stato della disputa dirà come è finita.';

  @override
  String get resolveRefusedTitle => 'Il nodo ha rifiutato la richiesta';

  @override
  String get resolveRefusedBody =>
      'Non è stato pagato né rimborsato nulla. Riprova più tardi o chiedi all\'operatore del nodo.';

  @override
  String get resolveNoAnswerBody =>
      'Potrebbe aver agito comunque: i sats potrebbero essersi spostati. Bosstro non ha inviato di nuovo la richiesta. Controlla lo stato della disputa prima di riprovare; cambia appena il nodo lo pubblica.';

  @override
  String get resolveClosedBody =>
      'Questa disputa è chiusa: non c\'è nulla da risolvere.';

  @override
  String get resolveNoOrderBody =>
      'Bosstro non conosce l\'ordine di questa disputa, e la richiesta ne ha bisogno. Recupera la disputa per leggerlo di nuovo.';

  @override
  String get resolveBackToDispute => 'Torna alla disputa';

  @override
  String get resolveGoToDisputes => 'Vai a «Le tue dispute»';

  @override
  String get closedPaidBuyer => 'Hai pagato l\'acquirente';

  @override
  String get closedRefundedSeller => 'Hai rimborsato il venditore';

  @override
  String get closedCooperatively =>
      'Le parti l\'hanno annullata prima della tua decisione';

  @override
  String get detailResult => 'Esito';

  @override
  String get bondsTitle => 'Depositi';

  @override
  String get bondsPickerHint =>
      'Questo nodo usa depositi anti-abuso. Scegli a chi confiscare il deposito, se a qualcuno. La scelta va nella stessa richiesta.';

  @override
  String get bondNoSlash => 'Non confiscare';

  @override
  String get bondNoSlashDetail => 'Ogni deposito torna al suo proprietario.';

  @override
  String get bondSlashBuyer => 'Confisca all\'acquirente';

  @override
  String get bondSlashBuyerDetail =>
      'L\'acquirente perde il suo deposito; il venditore può reclamare la sua quota.';

  @override
  String get bondSlashSeller => 'Confisca al venditore';

  @override
  String get bondSlashSellerDetail =>
      'Il venditore perde il suo deposito; l\'acquirente può reclamare la sua quota.';

  @override
  String get bondSlashBoth => 'Confisca a entrambi';

  @override
  String get bondSlashBothDetail => 'Entrambi perdono il loro deposito.';

  @override
  String get bondNotPostedTitle => 'Quella parte non ha versato alcun deposito';

  @override
  String get bondNotPostedBody =>
      'Il nodo non ha alcun deposito della parte che hai scelto per la confisca, quindi non è stato pagato né rimborsato nulla. Scegli un\'altra opzione per i depositi.';

  @override
  String get bondChooseAgain => 'Scegli un\'altra opzione';

  @override
  String get resolvedSlashedBuyer =>
      'Il deposito dell\'acquirente è stato confiscato.';

  @override
  String get resolvedSlashedSeller =>
      'Il deposito del venditore è stato confiscato.';

  @override
  String get resolvedSlashedBoth =>
      'Entrambi i depositi sono stati confiscati.';

  @override
  String get detailBonds => 'Depositi';

  @override
  String get detailPreviousStatus => 'Stato prima della disputa';

  @override
  String get orderStatusActive => 'Attivo';

  @override
  String get orderStatusFiatSent => 'Fiat inviato';

  @override
  String get myDisputesOpenSegment => 'In corso';

  @override
  String get myDisputesClosedSegment => 'Chiuse';

  @override
  String get myDisputesSegmentsLabel => 'Dispute aperte o chiuse';

  @override
  String get closedEmptyTitle => 'Nessuna disputa chiusa per ora';

  @override
  String get closedEmptyBody =>
      'Le dispute che prendi in carico compaiono qui quando si chiudono, che le abbia risolte tu o che le parti abbiano concluso lo scambio da sole.';

  @override
  String get disputeClosedJustNow => 'Chiusa poco fa';

  @override
  String disputeClosedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chiusa $count minuti fa',
      one: 'Chiusa 1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String disputeClosedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chiusa $count ore fa',
      one: 'Chiusa 1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String disputeClosedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chiusa $count giorni fa',
      one: 'Chiusa 1 giorno fa',
    );
    return '$_temp0';
  }
}
