import 'package:hive_flutter/hive_flutter.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';

// Nombres para nuestras "cajas" de almacenamiento
const String kRoutesBoxName = 'routes_box';
const String kCategoriesBoxName = 'categories_box';
const String kActivitiesBoxName = 'activities_box';

class LocalStorageService {
  
  // --- RUTAS y POIs ---
  // (Esta parte está perfecta, usa los TypeAdapters, no la toques)
  Future<void> saveAllRoutes(List<MapRoute> routes) async {
    final routesBox = await Hive.openBox<MapRoute>(kRoutesBoxName);
    await routesBox.clear(); 
    final Map<String, MapRoute> routeMap = {
      for (var route in routes) route.id: route
    };
    await routesBox.putAll(routeMap); 
  }

  Future<List<MapRoute>> getAllRoutes() async {
    final routesBox = await Hive.openBox<MapRoute>(kRoutesBoxName);
    return routesBox.values.toList(); 
  }

  // --- CATEGORÍAS (CORREGIDO OTRA VEZ) ---
  
  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    // 🔽 Abre la caja SIN tipo genérico.
    final categoriesBox = await Hive.openBox(kCategoriesBoxName);
    await categoriesBox.clear();
    await categoriesBox.addAll(categories); 
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    // 🔽 Abre la caja SIN tipo genérico.
    final categoriesBox = await Hive.openBox(kCategoriesBoxName);
    
    // 🔽 Mapea la lista (que es de tipo <dynamic>) y conviértela
    return categoriesBox.values
        .map((dynamic mapa) => Map<String, dynamic>.from(mapa as Map))
        .toList();
  }

  // --- ACTIVIDADES (CORREGIDO OTRA VEZ) ---

  Future<void> saveActivities(List<Map<String, dynamic>> activities) async {
    // 🔽 Abre la caja SIN tipo genérico.
    final activitiesBox = await Hive.openBox(kActivitiesBoxName);
    await activitiesBox.clear();
    await activitiesBox.addAll(activities);
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    // 🔽 Abre la caja SIN tipo genérico.
    final activitiesBox = await Hive.openBox(kActivitiesBoxName);

    // 🔽 Mapea la lista (que es de tipo <dynamic>) y conviértela
    return activitiesBox.values
        .map((dynamic mapa) => Map<String, dynamic>.from(mapa as Map))
        .toList();
  }
}