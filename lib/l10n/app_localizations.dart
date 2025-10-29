import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('pt'),
  ];

  /// Texto de búsqueda
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// version de Otoño para vista 360
  ///
  /// In es, this message translates to:
  /// **'Otoño'**
  String get otono;

  /// version de Invierno para vista 360
  ///
  /// In es, this message translates to:
  /// **'Invierno'**
  String get invierno;

  /// version de Primavera para vista 360
  ///
  /// In es, this message translates to:
  /// **'Primavera'**
  String get primavera;

  /// version de Verano para vista 360
  ///
  /// In es, this message translates to:
  /// **'Verano'**
  String get verano;

  /// Texto para el botón de vista 360
  ///
  /// In es, this message translates to:
  /// **'Vista 360°'**
  String get vista360;

  /// Título para la sección de descripción
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get descripcion;

  /// Título para la sección de puntos de interés recomendados
  ///
  /// In es, this message translates to:
  /// **'Recomendados'**
  String get recomendados;

  /// Título para la sección de puntos de interés cercanos
  ///
  /// In es, this message translates to:
  /// **'Cerca de ti'**
  String get cercanos;

  /// prefijo para la ruta en mapa
  ///
  /// In es, this message translates to:
  /// **'Ruta'**
  String get ruta;

  /// Título para la sección de rutas disponibles
  ///
  /// In es, this message translates to:
  /// **'Rutas disponibles'**
  String get rutas_disponibles;

  /// Título para la sección de rutas cuando se escribe
  ///
  /// In es, this message translates to:
  /// **'Resultado de búsqueda'**
  String get resultado_busqueda;

  /// Texto que aparece cuando no hay resultados
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get sin_resultado;

  /// Tooltip text indicating 360 views were modified with AI
  ///
  /// In es, this message translates to:
  /// **'Incluye vistas modificadas con IA'**
  String get vistas_modificadas_ia;

  /// Message shown when the selected season has no 360 image
  ///
  /// In es, this message translates to:
  /// **'No hay imagen 360 para la temporada \"{season}\".'**
  String no_vista360_temporada(Object season);

  /// Message shown when there is no 360 image available at all
  ///
  /// In es, this message translates to:
  /// **'No hay imagen 360 disponible para la temporada seleccionada.'**
  String get no_vista360_disponible;

  /// Texto para el botón de ir a la ruta
  ///
  /// In es, this message translates to:
  /// **'Ir'**
  String get ir;

  /// Título del panel de navegación activa
  ///
  /// In es, this message translates to:
  /// **'Ruta en curso'**
  String get ruta_en_curso;

  /// Etiqueta de distancia con valor formateado
  ///
  /// In es, this message translates to:
  /// **'Distancia: {distance}'**
  String distancia_fmt(Object distance);

  /// Etiqueta de tiempo aproximado con valor
  ///
  /// In es, this message translates to:
  /// **'Tiempo aprox.: {duration}'**
  String tiempo_aprox_fmt(Object duration);

  /// Etiqueta de llegada aproximada con hora
  ///
  /// In es, this message translates to:
  /// **'Llegada aprox.: {eta}'**
  String llegada_aprox_fmt(Object eta);

  /// Texto para el botón de cancelar navegación
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// Título de la hoja de filtros
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get filtros_title;

  /// Etiqueta para el selector de categoría
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get categoria_label;

  /// Etiqueta para el selector de actividad
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get actividad_label;

  /// Etiqueta para el control de distancia en km
  ///
  /// In es, this message translates to:
  /// **'Distancia (km)'**
  String get distancia_km_label;

  /// Texto del botón para aplicar filtros
  ///
  /// In es, this message translates to:
  /// **'Aplicar filtros'**
  String get aplicar_filtros;

  /// Opción genérica 'todas' en filtros
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get todas;

  /// Banner text shown when the app is offline
  ///
  /// In es, this message translates to:
  /// **'Modo sin conexión'**
  String get modo_sin_conexion;

  /// Cabecera que muestra la temporada actual
  ///
  /// In es, this message translates to:
  /// **'Temporada actual: {season}'**
  String temporada_actual_fmt(Object season);

  /// No description provided for @recomendacion_temporada_otono.
  ///
  /// In es, this message translates to:
  /// **'Paisajes coloridos y temperaturas moderadas; ideal para fotografía y caminatas.'**
  String get recomendacion_temporada_otono;

  /// No description provided for @recomendacion_temporada_invierno.
  ///
  /// In es, this message translates to:
  /// **'Clima frío y con neblina; usa abrigo adecuado y precaución en senderos.'**
  String get recomendacion_temporada_invierno;

  /// No description provided for @recomendacion_temporada_primavera.
  ///
  /// In es, this message translates to:
  /// **'Clima templado y flora abundante; ideal para trekking y observación de flora.'**
  String get recomendacion_temporada_primavera;

  /// No description provided for @recomendacion_temporada_verano.
  ///
  /// In es, this message translates to:
  /// **'Días más calurosos; hidrátate y evita las horas de mayor radiación.'**
  String get recomendacion_temporada_verano;

  /// Título de la pantalla de emergencias
  ///
  /// In es, this message translates to:
  /// **'Emergencias'**
  String get emergencias_title;

  /// Sección de teléfonos de emergencia
  ///
  /// In es, this message translates to:
  /// **'Teléfonos de emergencia'**
  String get telefonos_emergencia_title;

  /// Nombre para Carabineros de Chile
  ///
  /// In es, this message translates to:
  /// **'Policía (Carabineros)'**
  String get emergency_police_chile;

  /// Nombre para Bomberos de Chile
  ///
  /// In es, this message translates to:
  /// **'Bomberos'**
  String get emergency_firefighters_chile;

  /// Nombre para Servicio de Ambulancias SAMU
  ///
  /// In es, this message translates to:
  /// **'Ambulancia (SAMU)'**
  String get emergency_ambulance_chile;

  /// Botón principal para iniciar la navegación de un POI
  ///
  /// In es, this message translates to:
  /// **'Iniciar ruta'**
  String get iniciar_ruta;

  /// Botón secundario para abrir el detalle de un POI
  ///
  /// In es, this message translates to:
  /// **'Ver detalles'**
  String get ver_detalles;

  /// Etiqueta del chip que indica la cantidad de rutas disponibles o coincidentes
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one {# ruta} other {# rutas}}'**
  String route_count_chip(int count);

  /// Etiqueta del chip que indica la cantidad de POI disponibles o coincidentes
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one {# POI} other {# POI}}'**
  String poi_count_chip(int count);
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
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

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
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
