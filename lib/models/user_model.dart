import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  // Convertir a un mapa (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  // Crear un UserModel desde un mapa (útil para obtener datos de Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  // Crear un UserModel desde un objeto User de Firebase Auth
  factory UserModel.fromFirebase(firebase_auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      photoUrl: user.photoURL,
    );
  }
}