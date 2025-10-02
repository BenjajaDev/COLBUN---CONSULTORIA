import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/blocs/poi_bloc.dart';
import 'package:consultoria_chat_bot/blocs/favorites_cubit.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/screens/map_page.dart';
import 'package:consultoria_chat_bot/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';

// Función principal para inicializar Firebase y arrancar la app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Widget raíz que configura proveedores de Bloc y la MaterialApp.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Proveedores de estado para MapBloc, PoiBloc y FavoritesCubit en todo el app.
      providers: [
        BlocProvider(create: (context) => MapBloc(FireStoreService())),
        BlocProvider(create: (context) => PoiBloc()),
        BlocProvider(create: (context) => FavoritesCubit()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        // Delegados para internacionalización y localizaciones soportadas.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Tema visual basado en colores deep purple con Material 3.
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // Pantalla inicial que muestra el mapa con rutas y POIs.
        home: MapPage(),
      ),
    );
  }
}
