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
}
