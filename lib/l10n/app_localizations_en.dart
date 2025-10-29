// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get btnCerrar => 'Close';

  @override
  String get contactarWhatsapp => 'Contact via WhatsApp';

  @override
  String get borrarHistorial => 'Clear Conversation History';

  @override
  String get deseaBorrar => 'Do you want to clear the history?';

  @override
  String get btnVolver => 'No, Go Back';

  @override
  String get btnEliminar => 'Yes, Delete';

  @override
  String get loadConversation => 'Loading conversation...';

  @override
  String get conectandoFirestore => 'Connecting to Firestore...';

  @override
  String get titleAsistente => 'Assistant';

  @override
  String get fontSmall => 'Small';

  @override
  String get fontMedium => 'Medium';

  @override
  String get fontLarge => 'Large';

  @override
  String get cambiarIdioma => 'Change Language';

  @override
  String get cambiarEs => 'Spanish';

  @override
  String get cambiarEn => 'English';

  @override
  String get cambiarPt => 'Portuguese';

  @override
  String get necesitaAyuda => 'Need Help?';

  @override
  String get menuNav => 'Menu Navigation';

  @override
  String get chatbotWhatsapp => 'WhatsApp Chatbot';

  @override
  String get chatbotApp => 'App Chatbot';

  @override
  String get appPrincipal => 'Main App';

  @override
  String get bienvenido => 'Welcome';

  @override
  String get abrirChat => 'Open Chat';

  @override
  String get cerrarSesion => 'Sign Out';

  @override
  String get sinConexion => 'No Connection. Offline Mode';

  @override
  String get conectado => 'Connected to the Internet';

  @override
  String get emergencias => 'Emergencies';

  @override
  String get emergenciasMsg => 'Use chat to activate emergency mode';

  @override
  String get sinContactos => 'No emergency contacts';

  @override
  String get llamar => 'Call';

  @override
  String get temaClaro => 'Light Theme';

  @override
  String get temaOscuro => 'Dark Theme';

  @override
  String get escribeMensaje => 'Type a message';
}
