import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:consultoria_chat_bot/model/route_model.dart';

class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {"name": name, "phone": phone};
  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(name: json["name"] ?? "", phone: json["phone"] ?? "");
}

class LocalStorage {
  static const String _emergencyKey = 'emergency_contacts';
  static const String _lastRouteKey = 'last_route_name';
  static const String _lastRouteDataKey = 'last_route_data';

  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_emergencyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw) as List;
      return list
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setEmergencyContacts(List<EmergencyContact> contacts) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(contacts.map((e) => e.toJson()).toList());
    await sp.setString(_emergencyKey, raw);
  }

  static Future<void> addEmergencyContact(EmergencyContact contact) async {
    final current = await getEmergencyContacts();
    current.add(contact);
    await setEmergencyContacts(current);
  }

  static Future<void> removeEmergencyContact(int index) async {
    final current = await getEmergencyContacts();
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
      await setEmergencyContacts(current);
    }
  }

  static Future<void> setLastRouteName(String name) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_lastRouteKey, name);
  }

  static Future<String?> getLastRouteName() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_lastRouteKey);
  }

  static Future<void> setLastRouteWithPois(MapRoute route) async {
    final sp = await SharedPreferences.getInstance();
    final data = {
      'name': route.name,
      'initialLatitude': route.initialLatitude,
      'initialLongitude': route.initialLongitude,
      'finalLatitude': route.finalLatitude,
      'finalLongitude': route.finalLongitude,
      'pois': route.pois
          .map((p) => {
                'id': p.id,
                'nombre': p.nombre,
                'descripcion': p.descripcion,
                'imagen': p.imagen,
                'latitud': p.latitud,
                'longitud': p.longitud,
                'categorias': p.categorias,
                'actividades': p.actividades,
                'vistas360': p.vistas360,
              })
          .toList(),
    };
    await sp.setString(_lastRouteDataKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getLastRouteWithPois() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_lastRouteDataKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
