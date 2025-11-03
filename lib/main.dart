import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/blocs/poi_bloc.dart';
import 'package:consultoria_chat_bot/blocs/favorites_cubit.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/screens/map_page.dart';
import 'package:consultoria_chat_bot/services/firestore_service.dart';
import 'package:consultoria_chat_bot/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:consultoria_chat_bot/theme.dart';
import 'firebase_options.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/model/hive_adapters.dart';
import 'package:consultoria_chat_bot/services/network_service.dart';
import 'package:consultoria_chat_bot/services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //  --- CONFIGURACIÓN DE HIVE ---
  // 1. Inicializa Hive en el directorio de la app
  await Hive.initFlutter();
  
  // 2. Registra los "traductores" (Adaptadores) que creamos
  Hive.registerAdapter(MapRouteAdapter()); // El generado para MapRoute (typeId: 0)
  Hive.registerAdapter(POIAdapter());      // El generado para POI (typeId: 1)
  Hive.registerAdapter(LatLngAdapter());    // El que hicimos a mano (typeId: 100)
  // --- FIN CONFIGURACIÓN HIVE ---


  // Lock app to portrait by default; specific screens may override temporarily.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  try {
    final contacts = await FireStoreService().fetchEmergencyContacts();
    if (contacts.isNotEmpty) {
      await LocalStorage.setEmergencyContacts(contacts);
    }
  } catch (_) {}
  // Debug helper: print whether compile-time defines are present.
  // We avoid printing the full keys to not leak secrets in logs.
 
 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override 
  Widget build(BuildContext context) {

    final firestoreService = FireStoreService();
    final networkService = NetworkService();
    final localStorageService = LocalStorageService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MapBloc(
            firestoreService,
            networkService,
            localStorageService,
          ),
        ),
        
        // (El código antiguo que daba error era este:)
        // BlocProvider(create: (context) => MapBloc(FireStoreService())),

        BlocProvider(create: (context) => PoiBloc()),
        BlocProvider(create: (context) => FavoritesCubit()),
      ],
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            final ThemeData lightTheme = ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: ThemeProvider.lightPrimary,
                brightness: Brightness.light,
                surface: ThemeProvider.lightBackground,
              ),
              scaffoldBackgroundColor: ThemeProvider.lightBackground,
              primaryColor: ThemeProvider.lightPrimary,
              appBarTheme: const AppBarTheme(
                backgroundColor: ThemeProvider.lightBackground,
                foregroundColor: ThemeProvider.lightText,
                elevation: 0,
              ),
            );

            final ThemeData darkTheme = ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: ThemeProvider.darkPrimary,
                brightness: Brightness.dark,
                surface: ThemeProvider.darkBackground,
              ),
              scaffoldBackgroundColor: ThemeProvider.darkBackground,
              primaryColor: ThemeProvider.darkPrimary,
              appBarTheme: const AppBarTheme(
                backgroundColor: ThemeProvider.darkSurface,
                foregroundColor: ThemeProvider.darkText,
                elevation: 0,
              ),
            );

            return MaterialApp(
              title: 'Consultoría',
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              home: const MapPage(),
            );
          },
        ),
      ),
    );
  }
}
