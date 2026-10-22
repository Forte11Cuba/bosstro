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
      'Cuando una operación de este nodo abra una disputa, aparecerá aquí para que un solver la tome.';

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
}
