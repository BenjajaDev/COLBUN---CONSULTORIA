// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// ===========================================================================
// MODELO DE USUARIO
// ===========================================================================
/// Representa los datos de un usuario en la aplicacion
/// Incluye informacion basica de perfil y sincronizacion con Firebase
class UserModel {
  // ===========================================================================
  // PROPIEDADES
  // ===========================================================================
  final String uid;          // ID unico del usuario en Firebase
  final String email;        // Correo electronico del usuario
  final String name;         // Nombre completo del usuario
  final String? photoUrl;    // URL de la foto de perfil (opcional)

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================
  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  // ===========================================================================
  // CONVERSION A MAP
  // ===========================================================================
  /// Convierte el modelo a un mapa (util para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  // ===========================================================================
  // FACTORY: DESDE MAP
  // ===========================================================================
  /// Crea un UserModel desde un mapa (util para obtener datos de Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  // ===========================================================================
  // FACTORY: DESDE FIREBASE AUTH
  // ===========================================================================
  /// Crea un UserModel desde un objeto User de Firebase Authentication
  factory UserModel.fromFirebase(firebase_auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      photoUrl: user.photoURL,
    );
  }
}