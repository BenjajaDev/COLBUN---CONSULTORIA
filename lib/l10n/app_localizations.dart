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
    Locale('pt')
  ];

  /// No description provided for @btnCerrar.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get btnCerrar;

  /// No description provided for @contactarWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Contact via WhatsApp'**
  String get contactarWhatsapp;

  /// No description provided for @borrarHistorial.
  ///
  /// In en, this message translates to:
  /// **'Clear Conversation History'**
  String get borrarHistorial;

  /// No description provided for @deseaBorrar.
  ///
  /// In en, this message translates to:
  /// **'Do you want to clear the history?'**
  String get deseaBorrar;

  /// No description provided for @btnVolver.
  ///
  /// In en, this message translates to:
  /// **'No, Go Back'**
  String get btnVolver;

  /// No description provided for @btnEliminar.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get btnEliminar;

  /// No description provided for @loadConversation.
  ///
  /// In en, this message translates to:
  /// **'Loading conversation...'**
  String get loadConversation;

  /// No description provided for @conectandoFirestore.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Firestore...'**
  String get conectandoFirestore;

  /// No description provided for @titleAsistente.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get titleAsistente;

  /// No description provided for @fontSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSmall;

  /// No description provided for @fontMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontMedium;

  /// No description provided for @fontLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontLarge;

  /// No description provided for @cambiarIdioma.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get cambiarIdioma;

  /// No description provided for @cambiarEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get cambiarEs;

  /// No description provided for @cambiarEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get cambiarEn;

  /// No description provided for @cambiarPt.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get cambiarPt;

  /// No description provided for @necesitaAyuda.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get necesitaAyuda;

  /// No description provided for @menuNav.
  ///
  /// In en, this message translates to:
  /// **'Menu Navigation'**
  String get menuNav;

  /// No description provided for @chatbotWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Chatbot'**
  String get chatbotWhatsapp;

  /// No description provided for @chatbotApp.
  ///
  /// In en, this message translates to:
  /// **'App Chatbot'**
  String get chatbotApp;

  /// No description provided for @appPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Main App'**
  String get appPrincipal;

  /// No description provided for @bienvenido.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get bienvenido;

  /// No description provided for @abrirChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get abrirChat;

  /// No description provided for @cerrarSesion.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get cerrarSesion;

  /// No description provided for @sinConexion.
  ///
  /// In en, this message translates to:
  /// **'No Connection. Offline Mode'**
  String get sinConexion;

  /// No description provided for @conectado.
  ///
  /// In en, this message translates to:
  /// **'Connected to the Internet'**
  String get conectado;

  /// No description provided for @emergencias.
  ///
  /// In en, this message translates to:
  /// **'Emergencies'**
  String get emergencias;

  /// No description provided for @emergenciasMsg.
  ///
  /// In en, this message translates to:
  /// **'Use chat to activate emergency mode'**
  String get emergenciasMsg;

  /// No description provided for @sinContactos.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts'**
  String get sinContactos;

  /// No description provided for @llamar.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get llamar;

  /// No description provided for @temaClaro.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get temaClaro;

  /// No description provided for @temaOscuro.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get temaOscuro;

  /// No description provided for @escribeMensaje.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get escribeMensaje;
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
      'that was used.');
}
