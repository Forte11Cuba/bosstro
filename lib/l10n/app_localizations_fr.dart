// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Bosstro';

  @override
  String get navPending => 'En attente';

  @override
  String get navInProgress => 'Mes litiges';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get noNodeSelected => 'Aucun nœud sélectionné';

  @override
  String get pendingTitle => 'Litiges en attente';

  @override
  String get pendingEmptyTitle => 'Aucun litige en attente';

  @override
  String get pendingEmptyBody =>
      'Aucun litige de ce nœud n\'attend de solver. Quand une transaction en ouvre un, il apparaît ici pour que vous le preniez en charge.';

  @override
  String get inProgressTitle => 'Vos litiges';

  @override
  String get inProgressEmptyTitle => 'Aucun litige en cours';

  @override
  String get inProgressEmptyBody =>
      'Les litiges que vous prenez en charge apparaissent ici. Si une prise en charge n\'a pas reçu de réponse, récupérez le litige.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsGroupApp => 'Application';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSheetTitle => 'Choisissez une langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String languageSystemDetail(String language) {
    return 'Celle de votre appareil : $language';
  }

  @override
  String get copied => 'Copié';

  @override
  String get chatKeyCopied =>
      'Clé du chat copiée. Elle sera effacée du presse-papiers dans 60 secondes.';

  @override
  String get chatCopyHint => 'Copier le message';

  @override
  String get idLabel => 'ID';

  @override
  String get copyIdHint => 'Copier l\'ID';

  @override
  String get easterEggWhitepaper =>
      '31 octobre 2008 : neuf pages, sans la permission de personne. Joyeux Halloween.';

  @override
  String get easterEggGenesis =>
      'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks';

  @override
  String get easterEggPizzaDay =>
      '22 mai 2010 : 10 000 BTC pour deux pizzas. Espérons qu\'elles étaient bonnes.';

  @override
  String get welcomeTitle => 'Résolvez les litiges Mostro';

  @override
  String get welcomeBody =>
      'Prenez en charge les litiges d\'un nœud, parlez avec l\'acheteur et le vendeur, et clôturez-les depuis votre téléphone.';

  @override
  String get welcomeLogIn => 'Se connecter';

  @override
  String get welcomeCreateAccount => 'Créer un compte';

  @override
  String get welcomeKeyUnreadable =>
      'La clé enregistrée n\'a pas pu être lue sur ce téléphone. Reconnectez-vous avec votre clé secrète. Se connecter avec une autre clé remplace celle enregistrée.';

  @override
  String get traderKeyWarning =>
      'N\'utilisez jamais la clé de vos transactions. Une clé de solver qui sert aussi pour vos transactions relie publiquement les deux rôles.';

  @override
  String get loginTitle => 'Se connecter';

  @override
  String get loginHeading => 'Votre clé secrète de solver';

  @override
  String get loginBody =>
      'Collez ou scannez la clé secrète (nsec) dont l\'opérateur de votre nœud a enregistré le npub comme solver.';

  @override
  String get loginBodyPaste =>
      'Collez la clé secrète (nsec) dont l\'opérateur de votre nœud a enregistré le npub comme solver.';

  @override
  String get secretKeyHint => 'nsec1…';

  @override
  String get showSecretKey => 'Afficher la clé';

  @override
  String get hideSecretKey => 'Masquer la clé';

  @override
  String get pasteAction => 'Coller';

  @override
  String get scanQrAction => 'Scanner le QR';

  @override
  String get clipboardEmpty => 'Le presse-papiers est vide.';

  @override
  String get loginContinue => 'Continuer';

  @override
  String get keyErrorEmpty => 'Saisissez votre clé secrète.';

  @override
  String get keyErrorPublicKey =>
      'C\'est une clé publique (npub). Pour vous connecter, il faut la clé secrète (nsec).';

  @override
  String get keyErrorInvalid =>
      'Ce n\'est pas une clé secrète valide. Saisissez une clé nsec1… ou sa forme hex de 64 caractères.';

  @override
  String get loginConfirmHeading => 'Est-ce le npub enregistré comme solver ?';

  @override
  String get loginConfirmBody =>
      'Comparez-le avec le npub ajouté par l\'opérateur de votre nœud. S\'il n\'est pas identique, cette clé ne peut pas résoudre de litiges sur ce nœud.';

  @override
  String get loginConfirmAnswer => 'Oui, se connecter';

  @override
  String get loginConfirmBack => 'Non, utiliser une autre clé';

  @override
  String get keySaveFailed =>
      'La clé n\'a pas pu être enregistrée sur ce téléphone. Réessayez.';

  @override
  String get npubLabel => 'npub';

  @override
  String get secretKeyLabel => 'Clé secrète (nsec)';

  @override
  String get copyNpub => 'Copier le npub';

  @override
  String get copySecretKey => 'Copier la clé secrète';

  @override
  String get shareNpub => 'Partager le npub';

  @override
  String get npubQrLabel => 'Code QR de votre npub';

  @override
  String get scanTitle => 'Scanner le QR';

  @override
  String get scanHint =>
      'Pointez la caméra vers le code QR de votre clé secrète.';

  @override
  String get scanUnavailable =>
      'La caméra n\'est pas disponible. Revenez en arrière et collez plutôt la clé.';

  @override
  String get createTitle => 'Créer un compte';

  @override
  String get createKeyHeading => 'Votre nouvelle clé secrète';

  @override
  String get createKeyBody =>
      'C\'est le seul moyen de vous connecter à ce compte. Notez-la dans un endroit sûr et privé : quiconque la possède peut résoudre des litiges en votre nom.';

  @override
  String get createBackupConfirm =>
      'J\'ai sauvegardé ma clé secrète dans un endroit sûr';

  @override
  String get createContinue => 'Continuer';

  @override
  String get createNpubHeading => 'Votre npub';

  @override
  String get createNpubBody =>
      'Envoyez ce npub à l\'opérateur de votre nœud pour qu\'il vous enregistre comme solver. D\'ici là, vous pouvez voir les litiges, mais pas les prendre en charge.';

  @override
  String get createDone => 'Choisir votre nœud';

  @override
  String get settingsGroupKey => 'Clé de solver';

  @override
  String get settingsNpub => 'Votre npub';

  @override
  String get settingsBackup => 'Sauvegarder la clé secrète';

  @override
  String get settingsLogOut => 'Se déconnecter';

  @override
  String get backupWarnTitle => 'Afficher votre clé secrète ?';

  @override
  String get backupWarnBody =>
      'Quiconque la voit peut résoudre des litiges en votre nom. Assurez-vous que personne ne regarde votre écran.';

  @override
  String get backupWarnAnswer => 'Afficher la clé secrète';

  @override
  String get cancel => 'Annuler';

  @override
  String get backupTitle => 'Sauvegarde de la clé secrète';

  @override
  String get backupBody =>
      'Conservez-la dans un endroit sûr et privé. C\'est le seul moyen de vous connecter à ce compte sur un autre téléphone.';

  @override
  String get backupUnavailable =>
      'La clé secrète n\'a pas pu être lue sur ce téléphone.';

  @override
  String get logOutTitle => 'Se déconnecter ?';

  @override
  String get logOutBody =>
      'Votre clé secrète sera supprimée de ce téléphone. Sans sauvegarde, vous ne pourrez plus vous connecter à ce compte.';

  @override
  String get logOutAnswer => 'Se déconnecter';

  @override
  String get logOutFailed => 'La déconnexion a échoué. Réessayez.';

  @override
  String get secretKeyCopied =>
      'Clé secrète copiée. Elle sera effacée du presse-papiers dans 60 secondes.';

  @override
  String linkOnline(int connected, int total) {
    return 'En ligne · $connected/$total relais';
  }

  @override
  String get linkConnecting => 'Connexion aux relais…';

  @override
  String get linkOffline => 'Hors ligne · aucun relais ne répond';

  @override
  String get chooseNodeTitle => 'Choisissez votre nœud';

  @override
  String get chooseNodeBody =>
      'Choisissez le nœud Mostro dont l\'opérateur a enregistré votre clé comme solver. Vous pourrez changer de nœud plus tard dans les Paramètres.';

  @override
  String get chooseNodeAppBar => 'Nœud';

  @override
  String get nodeChipTrusted => 'De confiance';

  @override
  String get nodeChipCustom => 'Ajouté par vous';

  @override
  String get nodeChipActive => 'Actif';

  @override
  String get nodeAddOwn => 'Ajouter votre propre nœud';

  @override
  String get nodeInfoTooltip => 'Informations du nœud';

  @override
  String nodeSwitched(String name) {
    return 'Désormais sur $name';
  }

  @override
  String get nodeSelectFailed => 'Impossible de passer à ce nœud. Réessayez.';

  @override
  String get nodeListFailed =>
      'La liste des nœuds n\'a pas pu être chargée. Redémarrez l\'application pour réessayer.';

  @override
  String get addNodeTitle => 'Ajouter un nœud';

  @override
  String get addNodeBody =>
      'Collez la clé publique du nœud (npub ou hex). Son opérateur peut vous la donner.';

  @override
  String get addNodePubkeyLabel => 'Clé publique';

  @override
  String get addNodeNameLabel => 'Nom (facultatif)';

  @override
  String get addNodeAnswer => 'Ajouter le nœud';

  @override
  String get nodeErrorInvalidPubkey =>
      'Saisissez une clé publique valide (npub ou 64 caractères hex).';

  @override
  String get nodeErrorPrivateKey =>
      'C\'est une clé secrète — ne la partagez jamais. Saisissez la clé publique du nœud.';

  @override
  String get nodeErrorAlreadyExists => 'Ce nœud est déjà dans la liste.';

  @override
  String get nodeErrorActive =>
      'C\'est votre nœud actif. Passez à un autre nœud avant de le supprimer.';

  @override
  String get nodeErrorStorage =>
      'Vos nœuds n\'ont pas pu être enregistrés sur cet appareil.';

  @override
  String get nodeErrorGeneric => 'Une erreur s\'est produite. Réessayez.';

  @override
  String get removeNodeAction => 'Supprimer le nœud';

  @override
  String get removeNodeTitle => 'Supprimer ce nœud ?';

  @override
  String get removeNodeBody =>
      'Il sera retiré de votre liste. Vous pourrez l\'ajouter à nouveau avec sa clé publique.';

  @override
  String get removeNodeAnswer => 'Supprimer le nœud';

  @override
  String get nodeRemoved => 'Nœud supprimé';

  @override
  String get nodeInfoTitle => 'Informations du nœud';

  @override
  String get nodeInfoUse => 'Utiliser ce nœud';

  @override
  String get nodeInfoGroupNode => 'Nœud';

  @override
  String get nodeInfoPubkey => 'Clé publique';

  @override
  String get nodeInfoRegion => 'Région';

  @override
  String get nodeInfoWebsite => 'Site web';

  @override
  String get nodeInfoAbout => 'Description';

  @override
  String get nodeInfoEmptyTitle => 'Pas encore d\'informations sur l\'instance';

  @override
  String get nodeInfoEmptyBody =>
      'Ce nœud n\'a pas publié les informations de son instance sur vos relais, ou ils n\'ont pas encore répondu. Elles sont redemandées chaque fois que vous ouvrez cet écran.';

  @override
  String get nodeInfoRefreshFailed =>
      'Les relais n\'ont pas répondu. Voici les dernières informations reçues.';

  @override
  String get nodeInfoStale =>
      'Ces informations datent de plus de 7 jours et peuvent être obsolètes.';

  @override
  String nodeInfoUnsupported(int version) {
    return 'Ce nœud utilise le protocole v$version. Bosstro n\'utilise que la v2 : il ne peut donc pas y résoudre de litiges.';
  }

  @override
  String get nodeInfoUpdatedNow => 'Mis à jour à l\'instant';

  @override
  String nodeInfoUpdatedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mis à jour il y a $count minutes',
      one: 'Mis à jour il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mis à jour il y a $count heures',
      one: 'Mis à jour il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mis à jour il y a $count jours',
      one: 'Mis à jour il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get nodeInfoGroupProtocol => 'Protocole';

  @override
  String get nodeInfoProtocolVersion => 'Version du protocole';

  @override
  String get nodeInfoTransport => 'Transport';

  @override
  String get nodeInfoGroupDaemon => 'Daemon Mostro';

  @override
  String get nodeInfoVersion => 'Version';

  @override
  String get nodeInfoCommit => 'Commit';

  @override
  String get nodeInfoMaxOrder => 'Montant max. d\'un ordre';

  @override
  String get nodeInfoMinOrder => 'Montant min. d\'un ordre';

  @override
  String get nodeInfoExpirationHours => 'Expiration des ordres';

  @override
  String get nodeInfoExpirationSeconds => 'Expiration des ordres pris';

  @override
  String get nodeInfoHoldWindow => 'Expiration de la facture de retenue';

  @override
  String get nodeInfoHoldCltv => 'Delta CLTV de la facture de retenue';

  @override
  String get nodeInfoInvoiceWindow => 'Fenêtre de facture';

  @override
  String get nodeInfoMaxOrders => 'Ordres maximum par réponse';

  @override
  String get nodeInfoFee => 'Frais';

  @override
  String get nodeInfoPow => 'PoW requise';

  @override
  String get nodeInfoPowFirst => 'PoW au premier contact';

  @override
  String get nodeInfoBonds => 'Dépôts de garantie';

  @override
  String get nodeInfoGroupLightning => 'Nœud Lightning';

  @override
  String get nodeInfoAlias => 'Alias';

  @override
  String get nodeInfoLnPubkey => 'Clé publique du nœud';

  @override
  String get nodeInfoLndVersion => 'Version de LND';

  @override
  String get nodeInfoChains => 'Chaînes';

  @override
  String get nodeInfoNetworks => 'Réseaux';

  @override
  String get nodeInfoUri => 'URI';

  @override
  String get nodeInfoGroupFiat => 'Devises fiat';

  @override
  String get nodeInfoFiatAll => 'Toutes les devises sont acceptées.';

  @override
  String get nodeInfoUnknown => 'Inconnu';

  @override
  String get nodeInfoEnabled => 'Activés';

  @override
  String get nodeInfoDisabled => 'Désactivés';

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
      other: '$count blocs',
      one: '1 bloc',
    );
    return '$_temp0';
  }

  @override
  String unitBits(int count) {
    return '$count bits';
  }

  @override
  String unitPercent(String value) {
    return '$value %';
  }

  @override
  String get relaysTitle => 'Relais';

  @override
  String get relaysBody =>
      'Bosstro communique avec votre nœud par ces relais. Les relais annoncés par votre nœud sont ajoutés pour vous.';

  @override
  String get relayStatusConnected => 'Connecté';

  @override
  String get relayStatusConnecting => 'Connexion en cours';

  @override
  String get relayStatusDisconnected => 'Déconnecté';

  @override
  String get relayStatusError => 'Refusé';

  @override
  String get relaySourceDefault => 'Par défaut';

  @override
  String get relaySourceNode => 'De votre nœud';

  @override
  String get relaySourceUser => 'Ajouté par vous';

  @override
  String get relayAdd => 'Ajouter un relais';

  @override
  String get addRelayTitle => 'Ajouter un relais';

  @override
  String get addRelayLabel => 'Adresse du relais';

  @override
  String get addRelayAnswer => 'Ajouter le relais';

  @override
  String get relayRemoveTooltip => 'Supprimer le relais';

  @override
  String get removeRelayTitle => 'Supprimer ce relais ?';

  @override
  String get removeRelayBody =>
      'Bosstro cesse de l\'utiliser. Un relais annoncé par votre nœud ne revient que si vous l\'ajoutez vous-même.';

  @override
  String get removeRelayAnswer => 'Supprimer le relais';

  @override
  String get relayErrorInvalidUrl =>
      'Saisissez une adresse de relais qui commence par wss://.';

  @override
  String get relayErrorExists => 'Ce relais est déjà dans la liste.';

  @override
  String get relayErrorLast =>
      'C\'est votre dernier relais. Ajoutez-en un autre avant de le supprimer.';

  @override
  String get relaysNotRunningTitle => 'Les relais n\'ont pas démarré';

  @override
  String get relaysNotRunningBody =>
      'Bosstro n\'a pas pu ouvrir sa connexion aux relais. Redémarrez l\'application pour réessayer.';

  @override
  String get settingsGroupNode => 'Nœud';

  @override
  String get settingsNode => 'Nœud';

  @override
  String get settingsNodeNone => 'Choisir';

  @override
  String get settingsNodeInfo => 'Informations du nœud';

  @override
  String get settingsRelays => 'Relais';

  @override
  String settingsRelaysValue(int connected, int total) {
    return '$connected/$total';
  }

  @override
  String get pendingNoNodeTitle => 'Choisissez d\'abord votre nœud';

  @override
  String get pendingNoNodeBody =>
      'Les litiges sont lus depuis un seul nœud Mostro à la fois. Choisissez le nœud où vous êtes solver.';

  @override
  String get pendingNoNodeAction => 'Choisir un nœud';

  @override
  String get loadingNodes => 'Chargement des nœuds';

  @override
  String get loadingNodeInfo => 'Chargement des informations du nœud';

  @override
  String get loadingRelays => 'Chargement des relais';

  @override
  String get loadingDisputes => 'Chargement des litiges';

  @override
  String get pendingLoadErrorTitle => 'Les litiges n\'ont pas pu être lus';

  @override
  String get pendingLoadErrorBody =>
      'Une erreur s\'est produite lors de la lecture des litiges de ce nœud sur ce téléphone. Fermez et rouvrez Bosstro pour réessayer.';

  @override
  String get disputeStatusInitiated => 'En attente d\'un solver';

  @override
  String get disputeStatusInProgress => 'En cours';

  @override
  String get disputeStatusSettled => 'Acheteur payé';

  @override
  String get disputeStatusSellerRefunded => 'Vendeur remboursé';

  @override
  String get disputeStatusReleased => 'Libéré par le vendeur';

  @override
  String get disputeStatusCooperativelyCanceled =>
      'Annulé par les deux parties';

  @override
  String get disputeOpenedByBuyer => 'Ouvert par l\'acheteur';

  @override
  String get disputeOpenedBySeller => 'Ouvert par le vendeur';

  @override
  String get disputeOpenedByUnknown => 'On ne sait pas qui l\'a ouvert';

  @override
  String get disputeOpenedJustNow => 'Ouvert à l\'instant';

  @override
  String disputeOpenedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ouvert il y a $count minutes',
      one: 'Ouvert il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ouvert il y a $count heures',
      one: 'Ouvert il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ouvert il y a $count jours',
      one: 'Ouvert il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get disputeOpenedUnknown => 'Heure d\'ouverture inconnue';

  @override
  String disputeRowLabel(String id) {
    return 'Litige $id';
  }

  @override
  String get close => 'Fermer';

  @override
  String get takeDisputeHint => 'Prendre en charge le litige';

  @override
  String get takeDisputeTitle => 'Prendre en charge ce litige ?';

  @override
  String get takeDisputeBody =>
      'Vous devenez son solver : le nœud prévient l\'acheteur et le vendeur, et le litige passe dans Vos litiges. Ne prenez en charge qu\'un litige que vous pouvez mener jusqu\'au bout.';

  @override
  String get takeDisputeAnswer => 'Prendre en charge';

  @override
  String get takeTakenSnack =>
      'Litige pris en charge. Il est dans Vos litiges.';

  @override
  String get recoverAction => 'Récupérer';

  @override
  String get recoverTitle => 'Récupérer un litige';

  @override
  String get recoverNote =>
      'Le nœud ne publie pas qui détient un litige. Cette liste montre donc tous les litiges en cours sur ce nœud qui ne sont pas dans Vos litiges sur ce téléphone : les vôtres dont la réponse s\'est perdue, et ceux d\'autres solvers. Récupérez-les un par un.';

  @override
  String get recoverEmptyTitle => 'Rien à récupérer';

  @override
  String get recoverEmptyBody =>
      'Aucun litige en cours sur ce nœud ne manque dans Vos litiges.';

  @override
  String get recoverDisputeHint => 'Récupérer le litige';

  @override
  String get recoverDisputeTitle => 'Récupérer ce litige ?';

  @override
  String get recoverDisputeBody =>
      'Bosstro redemande ce litige au nœud. S\'il est à vous, le nœud vous renvoie ses données. Si un autre solver le détient, le nœud refuse, sauf si ce solver est en lecture seule, comme Serbero, et que votre clé peut payer l\'acheteur et rembourser le vendeur : le litige devient alors le vôtre (une reprise).';

  @override
  String get recoverDisputeAnswer => 'Récupérer le litige';

  @override
  String get recoverTakenSnack => 'Litige récupéré. Il est dans Vos litiges.';

  @override
  String get notSolverTitle => 'Vous n\'êtes pas solver sur ce nœud';

  @override
  String get notSolverBody =>
      'Passez à votre nœud pour résoudre des litiges. Si c\'est votre nœud, envoyez votre npub à son opérateur.';

  @override
  String get switchNodeAction => 'Changer de nœud';

  @override
  String get cannotTakeOverTitle => 'Un autre solver détient ce litige';

  @override
  String get cannotTakeOverBody =>
      'Seul un litige détenu par un solver en lecture seule, comme Serbero, peut être repris, et seulement par un solver qui peut payer l\'acheteur et rembourser le vendeur.';

  @override
  String get takeRefusedTitle => 'Le nœud ne vous a pas donné ce litige';

  @override
  String get takeRefusedBody =>
      'Il a refusé la demande. Réessayez plus tard ou adressez-vous à l\'opérateur du nœud.';

  @override
  String get takeRefusedNotFoundBody =>
      'Le nœud n\'a plus l\'ordre de ce litige.';

  @override
  String get noAnswerTitle => 'Le nœud n\'a pas répondu';

  @override
  String get noAnswerBody =>
      'Votre demande lui est peut-être parvenue malgré tout : Bosstro ne l\'a donc pas renvoyée. Dans un moment, regardez dans Vos litiges, ou redemandez le litige depuis Récupérer un litige.';

  @override
  String get takeFailedTitle => 'La demande n\'a pas été envoyée';

  @override
  String get takeFailedBody =>
      'Aucun relais ne l\'a acceptée. Vérifiez votre connexion et les relais, puis réessayez.';

  @override
  String get takeAlreadyTakingBody =>
      'Une demande pour ce litige attend déjà la réponse du nœud.';

  @override
  String get takeClosedBody =>
      'Ce litige est clos : il n\'y a rien à prendre en charge.';

  @override
  String get takeUnknownBody =>
      'Ce litige ne fait pas partie des litiges de ce nœud sur ce téléphone.';

  @override
  String get takeProtocolBody =>
      'Ce nœud annonce une autre version du protocole. Bosstro ne communique qu\'avec les nœuds du protocole 2.';

  @override
  String get takeNodeInfoBody =>
      'Bosstro n\'a pas pu lire les paramètres de ce nœud : il ne connaît donc pas la preuve de travail que le nœud demande. Vérifiez les relais et réessayez.';

  @override
  String get disputeTakenJustNow => 'Pris en charge à l\'instant';

  @override
  String disputeTakenMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pris en charge il y a $count minutes',
      one: 'Pris en charge il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pris en charge il y a $count heures',
      one: 'Pris en charge il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pris en charge il y a $count jours',
      one: 'Pris en charge il y a 1 jour',
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
  String get disputeAmountUnknown => 'Montant inconnu';

  @override
  String get settingsSolverStatus => 'Solver sur ce nœud';

  @override
  String get settingsSolverYes => 'Oui';

  @override
  String get settingsSolverNo => 'Non';

  @override
  String get settingsPermission => 'Autorisation';

  @override
  String get permissionRead => 'Médiation uniquement';

  @override
  String get permissionReadWrite => 'Médiation, paiement et remboursement';

  @override
  String get disputeDetailTitle => 'Litige';

  @override
  String get detailSegmentInfo => 'Infos';

  @override
  String get detailSegmentBuyer => 'Acheteur';

  @override
  String get detailSegmentSeller => 'Vendeur';

  @override
  String get detailSegmentsLabel => 'Sections du litige';

  @override
  String get detailDisputeId => 'ID du litige';

  @override
  String get detailOrderId => 'ID de l\'ordre';

  @override
  String get detailStatus => 'Statut';

  @override
  String get detailOpenedBy => 'Ouvert par';

  @override
  String get detailOpenedAt => 'Ouverture';

  @override
  String get detailTakenAt => 'Prise en charge';

  @override
  String get detailAmount => 'Montant';

  @override
  String get detailCurrency => 'Devise';

  @override
  String get detailFactsTitle => 'Informations sur le litige';

  @override
  String get detailFiatAmount => 'Montant fiat';

  @override
  String get detailPaymentMethod => 'Moyen de paiement';

  @override
  String get detailPremium => 'Prime';

  @override
  String get detailFee => 'Frais du nœud';

  @override
  String get detailOrderKind => 'Type d\'ordre';

  @override
  String get detailBuyerKey => 'Clé de transaction de l\'acheteur';

  @override
  String get detailSellerKey => 'Clé de transaction du vendeur';

  @override
  String get detailPartyBuyer => 'Acheteur';

  @override
  String get detailPartySeller => 'Vendeur';

  @override
  String get detailPartyUnknown => 'Inconnu';

  @override
  String get detailOrderKindBuy => 'Ordre d\'achat';

  @override
  String get detailOrderKindSell => 'Ordre de vente';

  @override
  String detailPremiumValue(String value) {
    return '$value %';
  }

  @override
  String get detailNotYoursTitle => 'Ce litige n\'est plus le vôtre';

  @override
  String get detailNotYoursBody =>
      'Le nœud l\'a rouvert, ou il appartient à une autre clé. Il n\'est plus dans Vos litiges.';

  @override
  String get chatSenderYou => 'Vous';

  @override
  String get chatSenderBuyer => 'Acheteur';

  @override
  String get chatSenderSeller => 'Vendeur';

  @override
  String get chatEmptyBuyerTitle => 'Aucun message avec l\'acheteur';

  @override
  String get chatEmptySellerTitle => 'Aucun message avec le vendeur';

  @override
  String get chatEmptyBody =>
      'Seuls vous et cette partie pouvez lire cette conversation. L\'autre partie ne la voit pas.';

  @override
  String get chatNoPartyKeyTitle => 'Pas de chat avec cette partie';

  @override
  String get chatNoPartyKeyBody =>
      'La réponse du nœud à la prise en charge n\'incluait pas la clé de cette partie : Bosstro ne peut donc pas la joindre.';

  @override
  String get chatClosedNote =>
      'Ce litige est clos. Le chat est en lecture seule.';

  @override
  String get chatComposerBuyerHint => 'Écrire à l\'acheteur';

  @override
  String get chatComposerSellerHint => 'Écrire au vendeur';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get chatSending => 'Envoi…';

  @override
  String get chatNotSent => 'Non envoyé';

  @override
  String get chatRetry => 'Réessayer';

  @override
  String get chatErrorTooLong =>
      'Le message est trop long. Divisez-le en deux.';

  @override
  String get chatErrorClosed =>
      'Ce litige est clos. Le chat est en lecture seule.';

  @override
  String get chatErrorNoRelays =>
      'Aucun relais connecté. Vérifiez votre connexion.';

  @override
  String get chatErrorNotYours => 'Ce litige n\'est plus le vôtre.';

  @override
  String get chatErrorGeneric => 'Le message n\'a pas pu être envoyé.';

  @override
  String get chatLoading => 'Chargement des messages';

  @override
  String chatMessageLabel(String sender, String time, String text) {
    return '$sender, $time : $text';
  }

  @override
  String get openDisputeHint => 'Ouvrir le litige';

  @override
  String get chatAttach => 'Joindre un fichier';

  @override
  String get attachSheetTitle => 'Joindre';

  @override
  String get attachSourcePhoto => 'Photo de la galerie';

  @override
  String get attachSourceCamera => 'Prendre une photo';

  @override
  String get attachSourcePdf => 'Document PDF';

  @override
  String get attachSheetNote =>
      'Le fichier est chiffré sur cet appareil. Seuls vous et cette partie pouvez l\'ouvrir. JPEG, PNG ou PDF, jusqu\'à 25 Mo.';

  @override
  String get attachConfirmTitle => 'Envoyer ce fichier ?';

  @override
  String attachConfirmBuyer(String name, String size) {
    return '$name ($size) sera envoyé chiffré à l\'acheteur. Une photo est envoyée sans sa localisation ni les données de l\'appareil photo.';
  }

  @override
  String attachConfirmSeller(String name, String size) {
    return '$name ($size) sera envoyé chiffré au vendeur. Une photo est envoyée sans sa localisation ni les données de l\'appareil photo.';
  }

  @override
  String get attachmentTooLarge => 'Le fichier dépasse 25 Mo.';

  @override
  String get attachmentUnsupported =>
      'Seuls les images JPEG et PNG et les documents PDF peuvent être envoyés.';

  @override
  String get attachmentInvalidImage => 'L\'image n\'a pas pu être lue.';

  @override
  String get attachmentReadFailed => 'Le fichier n\'a pas pu être lu.';

  @override
  String get attachmentUploadFailed =>
      'Le fichier n\'a pas pu être téléversé. Vérifiez votre connexion et réessayez.';

  @override
  String get attachmentSendFailed => 'Le fichier n\'a pas pu être envoyé.';

  @override
  String get attachmentUploading => 'Chiffrement et envoi…';

  @override
  String get attachmentDiscard => 'Abandonner';

  @override
  String get attachmentLoading => 'Déchiffrement du fichier';

  @override
  String get attachmentNotVerified => 'Le fichier n\'a pas pu être vérifié.';

  @override
  String get attachmentDownloadFailed =>
      'Le fichier n\'a pas pu être téléchargé.';

  @override
  String get attachmentUnsupportedReceived =>
      'Ce type de fichier ne peut pas être ouvert ici.';

  @override
  String get attachmentOpenFailed => 'Le fichier n\'a pas pu être ouvert.';

  @override
  String attachmentImageLabel(String name) {
    return 'Image $name';
  }

  @override
  String get attachmentOpenImage => 'Ouvrir l\'image';

  @override
  String get attachmentSave => 'Enregistrer';

  @override
  String get attachmentSaveHint => 'Enregistrer le fichier';

  @override
  String get attachmentSaved => 'Enregistré';

  @override
  String get attachmentSaveFailed => 'Le fichier n\'a pas pu être enregistré.';

  @override
  String attachmentFileLabel(String name, String details) {
    return '$name, $details';
  }

  @override
  String get attachmentViewerZoomHint => 'Pincez pour zoomer';

  @override
  String get observerTitle => 'Chat entre les parties';

  @override
  String observerSharedByBuyer(String date) {
    return 'L\'acheteur a partagé sa clé du chat le $date.';
  }

  @override
  String observerSharedBySeller(String date) {
    return 'Le vendeur a partagé sa clé du chat le $date.';
  }

  @override
  String get observerPastedKey =>
      'Vous avez collé une clé du chat pour ce litige.';

  @override
  String get observerStoredOnly =>
      'Messages conservés d\'une lecture précédente. Collez à nouveau la clé du chat pour chercher les nouveaux.';

  @override
  String get observerNoKey =>
      'Aucune partie n\'a encore partagé sa clé du chat. Si l\'une d\'elles vous l\'envoie par un autre moyen, collez-la ici.';

  @override
  String get observerReadAction => 'Lire le chat entre les parties';

  @override
  String get observerPasteAction => 'Coller une clé du chat';

  @override
  String get observerRefresh => 'Actualiser';

  @override
  String get observerReadOnlyBuyer =>
      'Lecture seule, avec la clé partagée par l\'acheteur.';

  @override
  String get observerReadOnlySeller =>
      'Lecture seule, avec la clé partagée par le vendeur.';

  @override
  String get observerReadOnlyBoth =>
      'Lecture seule, avec la clé partagée par les deux parties.';

  @override
  String get observerReadOnlyPasted =>
      'Lecture seule, avec une clé que vous avez collée.';

  @override
  String get observerReadOnlyStored =>
      'Lecture seule : messages d\'une lecture précédente.';

  @override
  String get observerNoKeyTitle => 'Pas encore de clé du chat';

  @override
  String get observerOpensNothingTitle =>
      'La clé n\'ouvre aucun message de ce litige';

  @override
  String observerOpensNothingBody(String date) {
    return 'Aucun message de l\'acheteur ou du vendeur de ce litige depuis le $date ne s\'ouvre avec elle. C\'est peut-être la clé d\'une autre transaction, ou ils n\'ont rien écrit pendant cette période.';
  }

  @override
  String get observerReadFailedTitle =>
      'Les relais n\'ont pas pu être interrogés';

  @override
  String get observerReadFailedBody => 'Vérifiez la connexion et réessayez.';

  @override
  String get observerNoPartyKeysTitle => 'Les parties ne sont pas connues';

  @override
  String get observerNoPartyKeysBody =>
      'Le nœud n\'a pas indiqué les clés de transaction de l\'acheteur et du vendeur : aucun message ne peut donc être affiché comme le leur.';

  @override
  String get observerPasteTitle => 'Coller une clé du chat';

  @override
  String get observerPasteBody =>
      'Une partie peut vous envoyer la clé de son chat avec l\'autre partie. Elle vous permet de lire ce chat, mais jamais d\'y écrire.';

  @override
  String get observerPasteHint => '64 caractères hexadécimaux';

  @override
  String get observerPasteConfirm => 'Lire le chat';

  @override
  String get observerInvalidKey =>
      'Ce n\'est pas une clé du chat : elle fait 64 caractères hexadécimaux, seuls ou après « Shared key: ».';

  @override
  String observerOpensNothingShort(String date) {
    return 'La clé n\'ouvre aucun message de ce litige depuis le $date.';
  }

  @override
  String get observerNotYours => 'Ce litige n\'est plus le vôtre sur ce nœud.';

  @override
  String get observerFileLocked =>
      'Il ne peut pas être ouvert avec une clé du chat.';

  @override
  String get observerFileAdviceBuyer =>
      'Demandez à l\'acheteur de vous l\'envoyer dans votre chat avec lui.';

  @override
  String get observerFileAdviceSeller =>
      'Demandez au vendeur de vous l\'envoyer dans votre chat avec lui.';

  @override
  String get observerFileImage => 'Image';

  @override
  String get observerFileOther => 'Fichier';

  @override
  String get resolveCardTitle => 'Résoudre le litige';

  @override
  String get resolveCardBody =>
      'Une fois les deux parties entendues, décidez où vont les sats. C\'est irréversible.';

  @override
  String get payBuyerAction => 'Payer l\'acheteur';

  @override
  String get refundSellerAction => 'Rembourser le vendeur';

  @override
  String get payBuyerAnswer => 'Payer l\'acheteur';

  @override
  String get refundSellerAnswer => 'Rembourser le vendeur';

  @override
  String get resolveReadOnlyNote =>
      'Votre clé de solver peut faire de la médiation sur ce nœud, mais ni payer ni rembourser. Demandez à l\'opérateur l\'autorisation de lecture et écriture.';

  @override
  String get resolveUnansweredPayNote =>
      'Votre demande de payer l\'acheteur n\'a reçu aucune réponse. Le nœud a peut-être payé malgré tout : vérifiez le statut du litige avant de réessayer.';

  @override
  String get resolveUnansweredRefundNote =>
      'Votre demande de rembourser le vendeur n\'a reçu aucune réponse. Le nœud a peut-être remboursé malgré tout : vérifiez le statut du litige avant de réessayer.';

  @override
  String get payBuyerTitle => 'Payer l\'acheteur ?';

  @override
  String get refundSellerTitle => 'Rembourser le vendeur ?';

  @override
  String get payBuyerRecipient => 'L\'acheteur reçoit';

  @override
  String get refundSellerRecipient => 'Le vendeur récupère';

  @override
  String payBuyerBreakdown(String amount, String fee) {
    return 'Les $amount de l\'ordre, moins les frais du nœud de $fee.';
  }

  @override
  String refundSellerBreakdown(String amount, String fee) {
    return 'Les $amount de l\'ordre, plus les frais du nœud de $fee, tels que le vendeur les a bloqués.';
  }

  @override
  String resolveTradeFiat(String fiat) {
    return 'Transaction : $fiat';
  }

  @override
  String get payBuyerOtherSide =>
      'La facture de retenue du vendeur est réglée : le vendeur ne récupère pas ces sats.';

  @override
  String get refundSellerOtherSide =>
      'La facture de retenue du vendeur est annulée : l\'acheteur ne reçoit rien de cette transaction.';

  @override
  String get resolveBondsUnknown =>
      'Bosstro ne sait pas si ce nœud utilise des dépôts : ses informations n\'ont pas pu être lues ou ne le précisent pas. S\'il y en a, aucun n\'est confisqué.';

  @override
  String get resolveIrreversible =>
      'C\'est irréversible. Une fois la demande envoyée, Bosstro ne la renvoie jamais de lui-même.';

  @override
  String get resolveWaiting =>
      'En attente de la réponse du nœud. Gardez Bosstro ouvert.';

  @override
  String get resolvedPaidTitle => 'Résolu : vous avez payé l\'acheteur';

  @override
  String get resolvedPaidBody =>
      'Le nœud a réglé la facture de retenue du vendeur et paie l\'acheteur. Le litige est clos.';

  @override
  String get resolvedRefundedTitle => 'Résolu : vous avez remboursé le vendeur';

  @override
  String get resolvedRefundedBody =>
      'Le nœud a annulé la facture de retenue du vendeur : les sats retournent au vendeur. Le litige est clos.';

  @override
  String get resolvedCoopTitle => 'Les parties avaient déjà annulé';

  @override
  String get resolvedCoopBody =>
      'L\'acheteur et le vendeur ont annulé la transaction entre eux avant votre demande : vous n\'avez donc rien payé ni remboursé. Le litige est clos.';

  @override
  String get readOnlySolverTitle =>
      'Vous ne pouvez ni payer ni rembourser sur ce nœud';

  @override
  String get takenOverTitle => 'Un autre solver détient désormais ce litige';

  @override
  String get takenOverBody =>
      'Le nœud l\'a donné à un autre solver : rien n\'a donc été payé ni remboursé. Il a quitté Vos litiges.';

  @override
  String get notInDisputeTitle => 'Cet ordre n\'est plus en litige';

  @override
  String get notInDisputeBody =>
      'Il a déjà été payé, remboursé ou libéré, peut-être par une demande précédente dont la réponse s\'est perdue. Le statut du litige indiquera comment il s\'est terminé.';

  @override
  String get resolveRefusedTitle => 'Le nœud a refusé la demande';

  @override
  String get resolveRefusedBody =>
      'Rien n\'a été payé ni remboursé. Réessayez plus tard ou adressez-vous à l\'opérateur du nœud.';

  @override
  String get resolveNoAnswerBody =>
      'Il a peut-être agi malgré tout : les sats ont peut-être bougé. Bosstro n\'a pas renvoyé la demande. Vérifiez le statut du litige avant de réessayer ; il change dès que le nœud le publie.';

  @override
  String get resolveClosedBody =>
      'Ce litige est clos : il n\'y a rien à résoudre.';

  @override
  String get resolveNoOrderBody =>
      'Bosstro ne connaît pas l\'ordre de ce litige, et la demande en a besoin. Récupérez le litige pour obtenir à nouveau son ordre.';

  @override
  String get resolveBackToDispute => 'Retour au litige';

  @override
  String get resolveGoToDisputes => 'Aller à Vos litiges';

  @override
  String get closedPaidBuyer => 'Vous avez payé l\'acheteur';

  @override
  String get closedRefundedSeller => 'Vous avez remboursé le vendeur';

  @override
  String get closedCooperatively =>
      'Les parties l\'ont annulé avant votre décision';

  @override
  String get detailResult => 'Résultat';

  @override
  String get bondsTitle => 'Dépôts';

  @override
  String get bondsPickerHint =>
      'Ce nœud utilise des dépôts de garantie. Choisissez à qui le dépôt est confisqué, le cas échéant. Ce choix part dans la même demande.';

  @override
  String get bondNoSlash => 'Ne pas confisquer';

  @override
  String get bondNoSlashDetail => 'Chaque dépôt retourne à son propriétaire.';

  @override
  String get bondSlashBuyer => 'Confisquer à l\'acheteur';

  @override
  String get bondSlashBuyerDetail =>
      'L\'acheteur perd son dépôt ; le vendeur peut réclamer sa part.';

  @override
  String get bondSlashSeller => 'Confisquer au vendeur';

  @override
  String get bondSlashSellerDetail =>
      'Le vendeur perd son dépôt ; l\'acheteur peut réclamer sa part.';

  @override
  String get bondSlashBoth => 'Confisquer aux deux';

  @override
  String get bondSlashBothDetail => 'Les deux perdent leur dépôt.';

  @override
  String get bondNotPostedTitle => 'Cette partie n\'a versé aucun dépôt';

  @override
  String get bondNotPostedBody =>
      'Le nœud n\'a aucun dépôt de la partie à qui vous avez choisi de le confisquer : rien n\'a donc été payé ni remboursé. Choisissez une autre option de dépôt.';

  @override
  String get bondChooseAgain => 'Choisir une autre option';

  @override
  String get resolvedSlashedBuyer => 'Le dépôt de l\'acheteur a été confisqué.';

  @override
  String get resolvedSlashedSeller => 'Le dépôt du vendeur a été confisqué.';

  @override
  String get resolvedSlashedBoth => 'Les deux dépôts ont été confisqués.';

  @override
  String get detailBonds => 'Dépôts';

  @override
  String get detailPreviousStatus => 'Statut avant le litige';

  @override
  String get orderStatusActive => 'Actif';

  @override
  String get orderStatusFiatSent => 'Fiat envoyé';

  @override
  String get myDisputesOpenSegment => 'En cours';

  @override
  String get myDisputesClosedSegment => 'Clos';

  @override
  String get myDisputesSegmentsLabel => 'Litiges ouverts ou clos';

  @override
  String get closedEmptyTitle => 'Aucun litige clos pour l\'instant';

  @override
  String get closedEmptyBody =>
      'Les litiges que vous prenez en charge apparaissent ici une fois clos, que vous les ayez résolus ou que les parties aient terminé l\'échange elles-mêmes.';

  @override
  String get disputeClosedJustNow => 'Clos à l\'instant';

  @override
  String disputeClosedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clos il y a $count minutes',
      one: 'Clos il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String disputeClosedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clos il y a $count heures',
      one: 'Clos il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String disputeClosedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clos il y a $count jours',
      one: 'Clos il y a 1 jour',
    );
    return '$_temp0';
  }
}
