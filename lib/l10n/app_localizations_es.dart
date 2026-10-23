// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Bosstro';

  @override
  String get navPending => 'Pendientes';

  @override
  String get navInProgress => 'En curso';

  @override
  String get navSettings => 'Configuración';

  @override
  String get noNodeSelected => 'Ningún nodo seleccionado';

  @override
  String get pendingTitle => 'Disputas pendientes';

  @override
  String get pendingEmptyTitle => 'No hay disputas esperando';

  @override
  String get pendingEmptyBody =>
      'Ninguna disputa de este nodo está esperando solver. Cuando una operación abra una, aparecerá aquí para que la tomes.';

  @override
  String get inProgressTitle => 'Tus disputas';

  @override
  String get inProgressEmptyTitle => 'No hay disputas en curso';

  @override
  String get inProgressEmptyBody =>
      'Las disputas que tomes aparecen aquí. Si una toma no recibió respuesta, recupérala.';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsGroupAbout => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get copied => 'Copiado';

  @override
  String get idLabel => 'ID';

  @override
  String get copyIdHint => 'Copiar ID';

  @override
  String get easterEggWhitepaper =>
      '31 de octubre de 2008: nueve páginas, sin pedirle permiso a nadie. Feliz Halloween.';

  @override
  String get easterEggGenesis =>
      'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks';

  @override
  String get easterEggPizzaDay =>
      '22 de mayo de 2010: 10.000 BTC por dos pizzas. Ojalá estuvieran ricas.';

  @override
  String get welcomeTitle => 'Resuelve disputas de Mostro';

  @override
  String get welcomeBody =>
      'Toma las disputas de un nodo, habla con el comprador y el vendedor, y ciérralas desde tu teléfono.';

  @override
  String get welcomeLogIn => 'Iniciar sesión';

  @override
  String get welcomeCreateAccount => 'Crear cuenta nueva';

  @override
  String get welcomeKeyUnreadable =>
      'No se pudo leer la clave guardada en este teléfono. Vuelve a iniciar sesión con tu clave secreta. Si entras con otra clave, reemplaza la guardada.';

  @override
  String get traderKeyWarning =>
      'Nunca uses la clave con la que operas. Una clave de solver que también es de trading vincula públicamente ambos roles.';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginHeading => 'Tu clave secreta de solver';

  @override
  String get loginBody =>
      'Pega o escanea la clave secreta (nsec) cuyo npub tu operador de nodo registró como solver.';

  @override
  String get loginBodyPaste =>
      'Pega la clave secreta (nsec) cuyo npub tu operador de nodo registró como solver.';

  @override
  String get secretKeyHint => 'nsec1…';

  @override
  String get showSecretKey => 'Mostrar clave';

  @override
  String get hideSecretKey => 'Ocultar clave';

  @override
  String get pasteAction => 'Pegar';

  @override
  String get scanQrAction => 'Escanear QR';

  @override
  String get clipboardEmpty => 'El portapapeles está vacío.';

  @override
  String get loginContinue => 'Continuar';

  @override
  String get keyErrorEmpty => 'Ingresa tu clave secreta.';

  @override
  String get keyErrorPublicKey =>
      'Esa es una clave pública (npub). Para iniciar sesión hace falta la clave secreta (nsec).';

  @override
  String get keyErrorInvalid =>
      'Esta no es una clave secreta válida. Ingresa una clave nsec1… o su forma hex de 64 caracteres.';

  @override
  String get loginConfirmHeading => '¿Es este el npub registrado como solver?';

  @override
  String get loginConfirmBody =>
      'Compáralo con el npub que agregó tu operador de nodo. Si no es el mismo, esta clave no puede resolver disputas en ese nodo.';

  @override
  String get loginConfirmAnswer => 'Sí, iniciar sesión';

  @override
  String get loginConfirmBack => 'No, usar otra clave';

  @override
  String get keySaveFailed =>
      'No se pudo guardar la clave en este teléfono. Inténtalo de nuevo.';

  @override
  String get npubLabel => 'npub';

  @override
  String get secretKeyLabel => 'Clave secreta (nsec)';

  @override
  String get copyNpub => 'Copiar npub';

  @override
  String get copySecretKey => 'Copiar clave secreta';

  @override
  String get shareNpub => 'Compartir npub';

  @override
  String get npubQrLabel => 'Código QR de tu npub';

  @override
  String get scanTitle => 'Escanear QR';

  @override
  String get scanHint => 'Apunta la cámara al código QR de tu clave secreta.';

  @override
  String get scanUnavailable =>
      'La cámara no está disponible. Vuelve y pega la clave.';

  @override
  String get createTitle => 'Crear cuenta nueva';

  @override
  String get createKeyHeading => 'Tu nueva clave secreta';

  @override
  String get createKeyBody =>
      'Es la única forma de iniciar sesión en esta cuenta. Anótala en un lugar seguro y privado: cualquiera que la tenga puede resolver disputas en tu nombre.';

  @override
  String get createBackupConfirm =>
      'Guardé mi clave secreta en un lugar seguro';

  @override
  String get createContinue => 'Continuar';

  @override
  String get createNpubHeading => 'Tu npub';

  @override
  String get createNpubBody =>
      'Envía este npub a tu operador de nodo para que te registre como solver. Hasta entonces puedes ver las disputas, pero no tomarlas.';

  @override
  String get createDone => 'Elegir tu nodo';

  @override
  String get settingsGroupKey => 'Clave de solver';

  @override
  String get settingsNpub => 'Tu npub';

  @override
  String get settingsBackup => 'Respaldar clave secreta';

  @override
  String get settingsLogOut => 'Cerrar sesión';

  @override
  String get backupWarnTitle => '¿Mostrar tu clave secreta?';

  @override
  String get backupWarnBody =>
      'Cualquiera que la vea puede resolver disputas en tu nombre. Asegúrate de que nadie esté mirando tu pantalla.';

  @override
  String get backupWarnAnswer => 'Mostrar clave secreta';

  @override
  String get cancel => 'Cancelar';

  @override
  String get backupTitle => 'Respaldo de la clave secreta';

  @override
  String get backupBody =>
      'Guárdala en un lugar seguro y privado. Es la única forma de iniciar sesión en esta cuenta en otro teléfono.';

  @override
  String get backupUnavailable =>
      'No se pudo leer la clave secreta en este teléfono.';

  @override
  String get logOutTitle => '¿Cerrar sesión?';

  @override
  String get logOutBody =>
      'Tu clave secreta se borrará de este teléfono. Sin un respaldo no podrás volver a iniciar sesión en esta cuenta.';

  @override
  String get logOutAnswer => 'Cerrar sesión';

  @override
  String get logOutFailed => 'No se pudo cerrar la sesión. Inténtalo de nuevo.';

  @override
  String get secretKeyCopied =>
      'Clave secreta copiada. Se borra del portapapeles en 60 segundos.';

  @override
  String linkOnline(int connected, int total) {
    return 'En línea · $connected/$total relays';
  }

  @override
  String get linkConnecting => 'Conectando a los relays…';

  @override
  String get linkOffline => 'Sin conexión · ningún relay responde';

  @override
  String get chooseNodeTitle => 'Elige tu nodo';

  @override
  String get chooseNodeBody =>
      'Elige el nodo Mostro cuyo operador registró tu clave como solver. Puedes cambiar de nodo más tarde en Configuración.';

  @override
  String get chooseNodeAppBar => 'Nodo';

  @override
  String get nodeChipTrusted => 'De confianza';

  @override
  String get nodeChipCustom => 'Agregado por ti';

  @override
  String get nodeChipActive => 'Activo';

  @override
  String get nodeAddOwn => 'Agregar nodo propio';

  @override
  String get nodeInfoTooltip => 'Información del nodo';

  @override
  String nodeSwitched(String name) {
    return 'Ahora en $name';
  }

  @override
  String get nodeSelectFailed =>
      'No se pudo cambiar a este nodo. Inténtalo de nuevo.';

  @override
  String get nodeListFailed =>
      'No se pudo cargar la lista de nodos. Reinicia la app para intentarlo de nuevo.';

  @override
  String get addNodeTitle => 'Agregar un nodo';

  @override
  String get addNodeBody =>
      'Pega la clave pública del nodo (npub o hex). Su operador te la puede dar.';

  @override
  String get addNodePubkeyLabel => 'Clave pública';

  @override
  String get addNodeNameLabel => 'Nombre (opcional)';

  @override
  String get addNodeAnswer => 'Agregar nodo';

  @override
  String get nodeErrorInvalidPubkey =>
      'Ingresa una clave pública válida (npub o 64 caracteres hex).';

  @override
  String get nodeErrorPrivateKey =>
      'Eso es una clave secreta — nunca la compartas. Ingresa la clave pública del nodo.';

  @override
  String get nodeErrorAlreadyExists => 'Este nodo ya está en la lista.';

  @override
  String get nodeErrorActive =>
      'Este es tu nodo activo. Cambia a otro nodo antes de eliminarlo.';

  @override
  String get nodeErrorStorage =>
      'Tus nodos no se pudieron guardar en este dispositivo.';

  @override
  String get nodeErrorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get removeNodeAction => 'Eliminar nodo';

  @override
  String get removeNodeTitle => '¿Eliminar este nodo?';

  @override
  String get removeNodeBody =>
      'Sale de tu lista. Puedes volver a agregarlo con su clave pública.';

  @override
  String get removeNodeAnswer => 'Eliminar nodo';

  @override
  String get nodeRemoved => 'Nodo eliminado';

  @override
  String get nodeInfoTitle => 'Información del nodo';

  @override
  String get nodeInfoUse => 'Usar este nodo';

  @override
  String get nodeInfoGroupNode => 'Nodo';

  @override
  String get nodeInfoPubkey => 'Clave pública';

  @override
  String get nodeInfoRegion => 'Región';

  @override
  String get nodeInfoWebsite => 'Sitio web';

  @override
  String get nodeInfoAbout => 'Descripción';

  @override
  String get nodeInfoEmptyTitle => 'Aún no hay información de la instancia';

  @override
  String get nodeInfoEmptyBody =>
      'Este nodo no ha publicado su información de instancia en tus relays, o aún no han respondido. Se vuelve a pedir cada vez que abres esta pantalla.';

  @override
  String get nodeInfoRefreshFailed =>
      'Los relays no respondieron. Esta es la última información vista.';

  @override
  String get nodeInfoStale =>
      'Esta información tiene más de 7 días y puede estar desactualizada.';

  @override
  String nodeInfoUnsupported(int version) {
    return 'Este nodo usa el protocolo v$version. Bosstro solo usa v2, así que no puede resolver disputas ahí.';
  }

  @override
  String get nodeInfoUpdatedNow => 'Actualizado hace un momento';

  @override
  String nodeInfoUpdatedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Actualizado hace $count minutos',
      one: 'Actualizado hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Actualizado hace $count horas',
      one: 'Actualizado hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Actualizado hace $count días',
      one: 'Actualizado hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get nodeInfoGroupProtocol => 'Protocolo';

  @override
  String get nodeInfoProtocolVersion => 'Versión del protocolo';

  @override
  String get nodeInfoTransport => 'Transporte';

  @override
  String get nodeInfoGroupDaemon => 'Daemon de Mostro';

  @override
  String get nodeInfoVersion => 'Versión';

  @override
  String get nodeInfoCommit => 'Commit';

  @override
  String get nodeInfoMaxOrder => 'Orden máxima';

  @override
  String get nodeInfoMinOrder => 'Orden mínima';

  @override
  String get nodeInfoExpirationHours => 'Expiración de órdenes';

  @override
  String get nodeInfoExpirationSeconds => 'Expiración de órdenes tomadas';

  @override
  String get nodeInfoHoldWindow => 'Ventana de hold invoice';

  @override
  String get nodeInfoHoldCltv => 'CLTV delta de hold invoice';

  @override
  String get nodeInfoInvoiceWindow => 'Ventana de factura';

  @override
  String get nodeInfoMaxOrders => 'Órdenes máximas por respuesta';

  @override
  String get nodeInfoFee => 'Comisión';

  @override
  String get nodeInfoPow => 'PoW requerido';

  @override
  String get nodeInfoPowFirst => 'PoW en el primer contacto';

  @override
  String get nodeInfoBonds => 'Fianzas antiabuso';

  @override
  String get nodeInfoGroupLightning => 'Nodo Lightning';

  @override
  String get nodeInfoAlias => 'Alias';

  @override
  String get nodeInfoLnPubkey => 'Pubkey del nodo';

  @override
  String get nodeInfoLndVersion => 'Versión de LND';

  @override
  String get nodeInfoChains => 'Cadenas';

  @override
  String get nodeInfoNetworks => 'Redes';

  @override
  String get nodeInfoUri => 'URI';

  @override
  String get nodeInfoGroupFiat => 'Monedas fiat';

  @override
  String get nodeInfoFiatAll => 'Se aceptan todas las monedas.';

  @override
  String get nodeInfoUnknown => 'Desconocido';

  @override
  String get nodeInfoEnabled => 'Activadas';

  @override
  String get nodeInfoDisabled => 'Desactivadas';

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
      other: '$count bloques',
      one: '1 bloque',
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
      'Bosstro habla con tu nodo a través de estos relays. Los relays que anuncia tu nodo se agregan solos.';

  @override
  String get relayStatusConnected => 'Conectado';

  @override
  String get relayStatusConnecting => 'Conectando';

  @override
  String get relayStatusDisconnected => 'Desconectado';

  @override
  String get relayStatusError => 'Rechazado';

  @override
  String get relaySourceDefault => 'Por defecto';

  @override
  String get relaySourceNode => 'De tu nodo';

  @override
  String get relaySourceUser => 'Agregado por ti';

  @override
  String get relayAdd => 'Agregar relay';

  @override
  String get addRelayTitle => 'Agregar un relay';

  @override
  String get addRelayLabel => 'Dirección del relay';

  @override
  String get addRelayAnswer => 'Agregar relay';

  @override
  String get relayRemoveTooltip => 'Eliminar relay';

  @override
  String get removeRelayTitle => '¿Eliminar este relay?';

  @override
  String get removeRelayBody =>
      'Bosstro deja de usarlo. Un relay que anunció tu nodo solo vuelve si lo agregas tú.';

  @override
  String get removeRelayAnswer => 'Eliminar relay';

  @override
  String get relayErrorInvalidUrl =>
      'Ingresa una dirección de relay que empiece por wss://.';

  @override
  String get relayErrorExists => 'Este relay ya está en la lista.';

  @override
  String get relayErrorLast =>
      'Este es tu último relay. Agrega otro antes de eliminarlo.';

  @override
  String get relaysNotRunningTitle => 'Los relays no arrancaron';

  @override
  String get relaysNotRunningBody =>
      'Bosstro no pudo abrir su conexión con los relays. Reinicia la app para intentarlo de nuevo.';

  @override
  String get settingsGroupNode => 'Nodo';

  @override
  String get settingsNode => 'Nodo';

  @override
  String get settingsNodeNone => 'Elegir';

  @override
  String get settingsNodeInfo => 'Información del nodo';

  @override
  String get settingsRelays => 'Relays';

  @override
  String settingsRelaysValue(int connected, int total) {
    return '$connected/$total';
  }

  @override
  String get pendingNoNodeTitle => 'Primero elige tu nodo';

  @override
  String get pendingNoNodeBody =>
      'Las disputas se leen de un nodo Mostro a la vez. Elige el nodo donde eres solver.';

  @override
  String get pendingNoNodeAction => 'Elegir nodo';

  @override
  String get loadingNodes => 'Cargando nodos';

  @override
  String get loadingNodeInfo => 'Cargando la información del nodo';

  @override
  String get loadingRelays => 'Cargando relays';

  @override
  String get loadingDisputes => 'Cargando disputas';

  @override
  String get pendingLoadErrorTitle => 'No se pudieron leer las disputas';

  @override
  String get pendingLoadErrorBody =>
      'Algo falló al leer en este teléfono las disputas de este nodo. Cierra y vuelve a abrir Bosstro para intentarlo de nuevo.';

  @override
  String get disputeStatusInitiated => 'Esperando solver';

  @override
  String get disputeStatusInProgress => 'En curso';

  @override
  String get disputeStatusSettled => 'Pagado al comprador';

  @override
  String get disputeStatusSellerRefunded => 'Devuelto al vendedor';

  @override
  String get disputeStatusReleased => 'Liberado por el vendedor';

  @override
  String get disputeStatusCooperativelyCanceled => 'Cancelada por ambas partes';

  @override
  String get disputeOpenedByBuyer => 'Abierta por el comprador';

  @override
  String get disputeOpenedBySeller => 'Abierta por el vendedor';

  @override
  String get disputeOpenedByUnknown => 'No se sabe quién la abrió';

  @override
  String get disputeOpenedJustNow => 'Abierta hace un momento';

  @override
  String disputeOpenedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Abierta hace $count minutos',
      one: 'Abierta hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Abierta hace $count horas',
      one: 'Abierta hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Abierta hace $count días',
      one: 'Abierta hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get disputeOpenedUnknown => 'Hora de apertura desconocida';

  @override
  String disputeRowLabel(String id) {
    return 'Disputa $id';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get takeDisputeHint => 'Tomar la disputa';

  @override
  String get takeDisputeTitle => '¿Tomar esta disputa?';

  @override
  String get takeDisputeBody =>
      'Pasas a ser su solver: el nodo avisa al comprador y al vendedor, y la disputa pasa a Tus disputas. Toma solo una disputa que puedas atender hasta el final.';

  @override
  String get takeDisputeAnswer => 'Tomar la disputa';

  @override
  String get takeTakenSnack => 'Disputa tomada. Está en Tus disputas.';

  @override
  String get recoverAction => 'Recuperar';

  @override
  String get recoverTitle => 'Recuperar una disputa';

  @override
  String get recoverNote =>
      'El nodo no publica quién tiene una disputa. Por eso esta lista muestra todas las disputas en curso de este nodo que no están en Tus disputas en este teléfono: las tuyas cuya respuesta se perdió y las de otros solvers. Recupéralas de una en una.';

  @override
  String get recoverEmptyTitle => 'Nada que recuperar';

  @override
  String get recoverEmptyBody =>
      'No falta en Tus disputas ninguna disputa en curso de este nodo.';

  @override
  String get recoverDisputeHint => 'Recuperar la disputa';

  @override
  String get recoverDisputeTitle => '¿Recuperar esta disputa?';

  @override
  String get recoverDisputeBody =>
      'Bosstro vuelve a pedir esta disputa al nodo. Si es tuya, el nodo te devuelve sus datos. Si la tiene otro solver, el nodo dice que no, salvo que ese solver sea de solo lectura, como Serbero, y tu clave pueda pagar al comprador y devolver al vendedor: entonces la disputa pasa a ser tuya (una toma de control).';

  @override
  String get recoverDisputeAnswer => 'Recuperar la disputa';

  @override
  String get recoverTakenSnack => 'Disputa recuperada. Está en Tus disputas.';

  @override
  String get notSolverTitle => 'No eres solver en este nodo';

  @override
  String get notSolverBody =>
      'Cambia a tu nodo para resolver disputas. Si este es tu nodo, envía tu npub a su operador.';

  @override
  String get switchNodeAction => 'Cambiar de nodo';

  @override
  String get cannotTakeOverTitle => 'Otro solver tiene esta disputa';

  @override
  String get cannotTakeOverBody =>
      'Solo se puede tomar el control de una disputa que tiene un solver de solo lectura, como Serbero, y solo puede hacerlo un solver que pueda pagar al comprador y devolver al vendedor.';

  @override
  String get takeRefusedTitle => 'El nodo no te dio esta disputa';

  @override
  String get takeRefusedBody =>
      'Rechazó la petición. Inténtalo más tarde o consulta al operador del nodo.';

  @override
  String get takeRefusedNotFoundBody =>
      'El nodo ya no tiene la orden de esta disputa.';

  @override
  String get noAnswerTitle => 'El nodo no respondió';

  @override
  String get noAnswerBody =>
      'Puede que tu petición le llegara igualmente, así que Bosstro no la volvió a enviar. En un momento, mira en Tus disputas o vuelve a pedirla desde Recuperar una disputa.';

  @override
  String get takeFailedTitle => 'La petición no se envió';

  @override
  String get takeFailedBody =>
      'Ningún relay la aceptó. Revisa tu conexión y los relays, y vuelve a intentarlo.';

  @override
  String get takeAlreadyTakingBody =>
      'Ya hay una petición de esta disputa esperando la respuesta del nodo.';

  @override
  String get takeClosedBody =>
      'Esta disputa está cerrada: no hay nada que tomar.';

  @override
  String get takeUnknownBody =>
      'Esta disputa no está entre las disputas de este nodo en este teléfono.';

  @override
  String get takeProtocolBody =>
      'Este nodo anuncia otra versión del protocolo. Bosstro solo habla con nodos del protocolo 2.';

  @override
  String get takeNodeInfoBody =>
      'Bosstro no pudo leer la configuración del nodo, así que no sabe la prueba de trabajo que pide. Revisa los relays y vuelve a intentarlo.';

  @override
  String get disputeTakenJustNow => 'Tomada hace un momento';

  @override
  String disputeTakenMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tomada hace $count minutos',
      one: 'Tomada hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tomada hace $count horas',
      one: 'Tomada hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tomada hace $count días',
      one: 'Tomada hace 1 día',
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
  String get disputeAmountUnknown => 'Monto desconocido';

  @override
  String get settingsSolverStatus => 'Solver en este nodo';

  @override
  String get settingsSolverYes => 'Sí';

  @override
  String get settingsSolverNo => 'No';

  @override
  String get settingsPermission => 'Permiso';

  @override
  String get permissionRead => 'Solo mediar';

  @override
  String get permissionReadWrite => 'Mediar, pagar y devolver';

  @override
  String get disputeDetailTitle => 'Disputa';

  @override
  String get detailSegmentInfo => 'Info';

  @override
  String get detailSegmentBuyer => 'Comprador';

  @override
  String get detailSegmentSeller => 'Vendedor';

  @override
  String get detailSegmentsLabel => 'Secciones de la disputa';

  @override
  String get detailDisputeId => 'ID de la disputa';

  @override
  String get detailOrderId => 'ID de la orden';

  @override
  String get detailStatus => 'Estado';

  @override
  String get detailOpenedBy => 'Abierta por';

  @override
  String get detailOpenedAt => 'Abierta';

  @override
  String get detailTakenAt => 'Tomada';

  @override
  String get detailAmount => 'Monto';

  @override
  String get detailFiatAmount => 'Monto en fiat';

  @override
  String get detailPaymentMethod => 'Método de pago';

  @override
  String get detailPremium => 'Prima';

  @override
  String get detailFee => 'Comisión del nodo';

  @override
  String get detailOrderKind => 'Tipo de orden';

  @override
  String get detailBuyerKey => 'Clave de trade del comprador';

  @override
  String get detailSellerKey => 'Clave de trade del vendedor';

  @override
  String get detailPartyBuyer => 'Comprador';

  @override
  String get detailPartySeller => 'Vendedor';

  @override
  String get detailPartyUnknown => 'No se sabe';

  @override
  String get detailOrderKindBuy => 'Orden de compra';

  @override
  String get detailOrderKindSell => 'Orden de venta';

  @override
  String detailPremiumValue(String value) {
    return '$value %';
  }

  @override
  String get detailNotYoursTitle => 'Esta disputa ya no es tuya';

  @override
  String get detailNotYoursBody =>
      'El nodo la reabrió, o es de otra clave. Ya no está en Tus disputas.';

  @override
  String get detailSelectTitle => 'Elige una disputa';

  @override
  String get detailSelectBody =>
      'Aquí se ven sus datos y los chats con el comprador y el vendedor.';

  @override
  String get chatSenderYou => 'Tú';

  @override
  String get chatSenderBuyer => 'Comprador';

  @override
  String get chatSenderSeller => 'Vendedor';

  @override
  String get chatEmptyBuyerTitle => 'Sin mensajes con el comprador';

  @override
  String get chatEmptySellerTitle => 'Sin mensajes con el vendedor';

  @override
  String get chatEmptyBody =>
      'Solo tú y esta parte pueden leer esta conversación. La otra parte no la ve.';

  @override
  String get chatNoPartyKeyTitle => 'Sin chat con esta parte';

  @override
  String get chatNoPartyKeyBody =>
      'La respuesta del nodo a la toma no incluyó la clave de esta parte, así que Bosstro no puede escribirle.';

  @override
  String get chatClosedNote =>
      'Esta disputa está cerrada. El chat es solo de lectura.';

  @override
  String get chatComposerBuyerHint => 'Escribe al comprador';

  @override
  String get chatComposerSellerHint => 'Escribe al vendedor';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatSending => 'Enviando…';

  @override
  String get chatNotSent => 'No enviado';

  @override
  String get chatRetry => 'Reintentar';

  @override
  String get chatErrorTooLong =>
      'El mensaje es demasiado largo. Divídelo en dos.';

  @override
  String get chatErrorClosed =>
      'Esta disputa está cerrada. El chat es solo de lectura.';

  @override
  String get chatErrorNoRelays =>
      'Sin conexión a ningún relay. Revisa tu conexión.';

  @override
  String get chatErrorNotYours => 'Esta disputa ya no es tuya.';

  @override
  String get chatErrorGeneric => 'No se pudo enviar el mensaje.';

  @override
  String get chatLoading => 'Cargando los mensajes';

  @override
  String chatMessageLabel(String sender, String time, String text) {
    return '$sender, $time: $text';
  }

  @override
  String get openDisputeHint => 'Abrir la disputa';

  @override
  String get chatAttach => 'Adjuntar un archivo';

  @override
  String get attachSheetTitle => 'Adjuntar';

  @override
  String get attachSourcePhoto => 'Foto de la galería';

  @override
  String get attachSourceCamera => 'Hacer una foto';

  @override
  String get attachSourcePdf => 'Documento PDF';

  @override
  String get attachSheetNote =>
      'El archivo se cifra en este dispositivo. Solo tú y esta parte pueden abrirlo. JPEG, PNG o PDF, hasta 25 MB.';

  @override
  String get attachConfirmTitle => '¿Enviar este archivo?';

  @override
  String attachConfirmBuyer(String name, String size) {
    return '$name ($size) se envía cifrado al comprador. Una foto se envía sin su ubicación ni los datos de la cámara.';
  }

  @override
  String attachConfirmSeller(String name, String size) {
    return '$name ($size) se envía cifrado al vendedor. Una foto se envía sin su ubicación ni los datos de la cámara.';
  }

  @override
  String get attachmentTooLarge => 'El archivo pasa de 25 MB.';

  @override
  String get attachmentUnsupported =>
      'Solo se pueden enviar imágenes JPEG y PNG y documentos PDF.';

  @override
  String get attachmentInvalidImage => 'No se pudo leer la imagen.';

  @override
  String get attachmentReadFailed => 'No se pudo leer el archivo.';

  @override
  String get attachmentUploadFailed =>
      'No se pudo subir el archivo. Revisa tu conexión y vuelve a intentarlo.';

  @override
  String get attachmentSendFailed => 'No se pudo enviar el archivo.';

  @override
  String get attachmentUploading => 'Cifrando y enviando…';

  @override
  String get attachmentDiscard => 'Descartar';

  @override
  String get attachmentLoading => 'Descifrando el archivo';

  @override
  String get attachmentNotVerified => 'El archivo no se pudo verificar.';

  @override
  String get attachmentDownloadFailed => 'No se pudo descargar el archivo.';

  @override
  String get attachmentUnsupportedReceived =>
      'Este tipo de archivo no se puede abrir aquí.';

  @override
  String get attachmentOpenFailed => 'No se pudo abrir el archivo.';

  @override
  String attachmentImageLabel(String name) {
    return 'Imagen $name';
  }

  @override
  String get attachmentOpenImage => 'Abrir la imagen';

  @override
  String get attachmentSave => 'Guardar';

  @override
  String get attachmentSaveHint => 'Guardar el archivo';

  @override
  String get attachmentSaved => 'Guardado';

  @override
  String get attachmentSaveFailed => 'No se pudo guardar el archivo.';

  @override
  String attachmentFileLabel(String name, String details) {
    return '$name, $details';
  }

  @override
  String get attachmentViewerZoomHint => 'Pellizca para ampliar';

  @override
  String get observerTitle => 'Chat entre las partes';

  @override
  String observerSharedByBuyer(String date) {
    return 'El comprador compartió la clave del chat el $date.';
  }

  @override
  String observerSharedBySeller(String date) {
    return 'El vendedor compartió la clave del chat el $date.';
  }

  @override
  String get observerPastedKey =>
      'Pegaste una clave del chat para esta disputa.';

  @override
  String get observerStoredOnly =>
      'Mensajes guardados de una lectura anterior. Pega de nuevo la clave del chat para buscar nuevos.';

  @override
  String get observerNoKey =>
      'Ninguna de las partes ha compartido todavía la clave de su chat. Si una te la envía por otro medio, pégala aquí.';

  @override
  String get observerReadAction => 'Leer el chat entre las partes';

  @override
  String get observerPasteAction => 'Pegar una clave del chat';

  @override
  String get observerRefresh => 'Actualizar';

  @override
  String get observerReadOnlyBuyer =>
      'Solo lectura, con la clave que compartió el comprador.';

  @override
  String get observerReadOnlySeller =>
      'Solo lectura, con la clave que compartió el vendedor.';

  @override
  String get observerReadOnlyBoth =>
      'Solo lectura, con la clave que compartieron las partes.';

  @override
  String get observerReadOnlyPasted =>
      'Solo lectura, con una clave que pegaste.';

  @override
  String get observerReadOnlyStored =>
      'Solo lectura: mensajes de una lectura anterior.';

  @override
  String get observerNoKeyTitle => 'Todavía no hay clave del chat';

  @override
  String get observerOpensNothingTitle =>
      'La clave no abre ningún mensaje de esta disputa';

  @override
  String observerOpensNothingBody(String date) {
    return 'Ningún mensaje del comprador o del vendedor de esta disputa desde el $date se abre con ella. Puede ser la clave de otra operación, o que no escribieran en ese tiempo.';
  }

  @override
  String get observerReadFailedTitle => 'No se pudo consultar a los relays';

  @override
  String get observerReadFailedBody =>
      'Revisa la conexión e inténtalo de nuevo.';

  @override
  String get observerNoPartyKeysTitle => 'No se conoce a las partes';

  @override
  String get observerNoPartyKeysBody =>
      'El nodo no indicó las claves de operación del comprador y del vendedor, así que ningún mensaje puede mostrarse como suyo.';

  @override
  String get observerPasteTitle => 'Pegar una clave del chat';

  @override
  String get observerPasteBody =>
      'Una parte puede enviarte la clave de su chat con la otra parte. Con ella lees ese chat; nunca puedes escribir en él.';

  @override
  String get observerPasteHint => '64 caracteres hexadecimales';

  @override
  String get observerPasteConfirm => 'Leer el chat';

  @override
  String get observerInvalidKey =>
      'Eso no es una clave del chat: son 64 caracteres hexadecimales, solos o tras «Shared key: ».';

  @override
  String observerOpensNothingShort(String date) {
    return 'La clave no abre ningún mensaje de esta disputa desde el $date.';
  }

  @override
  String get observerNotYours => 'Esta disputa ya no es tuya en este nodo.';

  @override
  String get observerFileLocked => 'No se puede abrir con la clave del chat.';

  @override
  String get observerFileAdviceBuyer =>
      'Pide al comprador que te lo envíe en su chat contigo.';

  @override
  String get observerFileAdviceSeller =>
      'Pide al vendedor que te lo envíe en su chat contigo.';

  @override
  String get observerFileImage => 'Imagen';

  @override
  String get observerFileOther => 'Archivo';

  @override
  String get resolveCardTitle => 'Resolver la disputa';

  @override
  String get resolveCardBody =>
      'Cuando hayas escuchado a las dos partes, decide adónde van los sats. No se puede deshacer.';

  @override
  String get payBuyerAction => 'Pagar al comprador';

  @override
  String get refundSellerAction => 'Devolver al vendedor';

  @override
  String get payBuyerAnswer => 'Pagar al comprador';

  @override
  String get refundSellerAnswer => 'Devolver al vendedor';

  @override
  String get resolveReadOnlyNote =>
      'Tu clave de solver puede mediar en este nodo pero no pagar ni devolver. Pide al operador permiso de lectura y escritura.';

  @override
  String get resolveUnansweredPayNote =>
      'Tu petición de pagar al comprador no tuvo respuesta. Puede que el nodo pagara igualmente: consulta el estado de la disputa antes de volver a intentarlo.';

  @override
  String get resolveUnansweredRefundNote =>
      'Tu petición de devolver al vendedor no tuvo respuesta. Puede que el nodo devolviera igualmente: consulta el estado de la disputa antes de volver a intentarlo.';

  @override
  String get payBuyerTitle => '¿Pagar al comprador?';

  @override
  String get refundSellerTitle => '¿Devolver al vendedor?';

  @override
  String get payBuyerRecipient => 'El comprador recibe';

  @override
  String get refundSellerRecipient => 'El vendedor recupera';

  @override
  String payBuyerBreakdown(String amount, String fee) {
    return 'Los $amount de la orden menos la comisión del nodo, $fee.';
  }

  @override
  String refundSellerBreakdown(String amount, String fee) {
    return 'Los $amount de la orden más la comisión del nodo, $fee, tal como los bloqueó el vendedor.';
  }

  @override
  String resolveTradeFiat(String fiat) {
    return 'Intercambio: $fiat';
  }

  @override
  String get payBuyerOtherSide =>
      'Se liquida la factura retenida del vendedor: el vendedor no recupera estos sats.';

  @override
  String get refundSellerOtherSide =>
      'Se cancela la factura retenida del vendedor: el comprador no recibe nada de este intercambio.';

  @override
  String get resolveBondsNote =>
      'Las fianzas, si las hay, vuelven a las dos partes; no se penaliza ninguna.';

  @override
  String get resolveIrreversible =>
      'No se puede deshacer. Una vez enviada, Bosstro nunca la vuelve a enviar por su cuenta.';

  @override
  String get resolveWaiting =>
      'Esperando la respuesta del nodo. Mantén Bosstro abierto.';

  @override
  String get resolvedPaidTitle => 'Resuelta: pagaste al comprador';

  @override
  String get resolvedPaidBody =>
      'El nodo liquidó la factura retenida del vendedor y paga al comprador. La disputa está cerrada.';

  @override
  String get resolvedRefundedTitle => 'Resuelta: devolviste al vendedor';

  @override
  String get resolvedRefundedBody =>
      'El nodo canceló la factura retenida del vendedor: los sats vuelven al vendedor. La disputa está cerrada.';

  @override
  String get resolvedCoopTitle => 'Las partes ya la habían cancelado';

  @override
  String get resolvedCoopBody =>
      'El comprador y el vendedor cancelaron el intercambio entre ellos antes de tu petición, así que no pagaste ni devolviste nada. La disputa está cerrada.';

  @override
  String get readOnlySolverTitle => 'No puedes pagar ni devolver en este nodo';

  @override
  String get takenOverTitle => 'Ahora otro solver tiene esta disputa';

  @override
  String get takenOverBody =>
      'El nodo se la dio a otro solver, así que no se pagó ni se devolvió nada. Ha salido de Tus disputas.';

  @override
  String get notInDisputeTitle => 'Esta orden ya no está en disputa';

  @override
  String get notInDisputeBody =>
      'Ya se pagó, se devolvió o se liberó, quizá por una petición anterior cuya respuesta se perdió. El estado de la disputa dirá cómo terminó.';

  @override
  String get resolveRefusedTitle => 'El nodo rechazó la petición';

  @override
  String get resolveRefusedBody =>
      'No se pagó ni se devolvió nada. Inténtalo más tarde o pregunta al operador del nodo.';

  @override
  String get resolveNoAnswerBody =>
      'Puede que actuara igualmente: los sats pueden haberse movido. Bosstro no volvió a enviar la petición. Consulta el estado de la disputa antes de volver a intentarlo; cambia en cuanto el nodo lo publique.';

  @override
  String get resolveClosedBody =>
      'Esta disputa está cerrada: no hay nada que resolver.';

  @override
  String get resolveNoOrderBody =>
      'Bosstro no conoce la orden de esta disputa, y la petición la necesita. Recupera la disputa para volver a leerla.';

  @override
  String get resolveBackToDispute => 'Volver a la disputa';

  @override
  String get resolveGoToDisputes => 'Ir a Tus disputas';

  @override
  String get inProgressClosedHeading => 'Cerradas';

  @override
  String get inProgressNoneOpen => 'Ahora no tienes ninguna disputa.';

  @override
  String get closedPaidBuyer => 'Pagaste al comprador';

  @override
  String get closedRefundedSeller => 'Devolviste al vendedor';

  @override
  String get closedCooperatively =>
      'Las partes la cancelaron antes de tu decisión';

  @override
  String get detailResult => 'Resultado';
}
