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
  String get pendingEmptyTitle => 'No hay disputas por resolver';

  @override
  String get pendingEmptyBody =>
      'Cuando una operación de este nodo abra una disputa, aparecerá aquí para que la tomes.';

  @override
  String get inProgressTitle => 'Tus disputas';

  @override
  String get inProgressEmptyTitle => 'No hay disputas en curso';

  @override
  String get inProgressEmptyBody =>
      'Las disputas que tomes aparecen aquí, con un chat para el comprador y otro para el vendedor.';

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
      'No se pudo leer la clave guardada en este teléfono. Vuelve a iniciar sesión con tu clave secreta.';

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
  String get createDone => 'Ir a las disputas';

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
}
