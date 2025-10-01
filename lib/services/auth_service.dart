import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultoria_chat_bot/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener el usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  // Registrar un usuario con email y contraseña
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      // Crear el usuario en Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar información adicional del usuario en Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'name': name,
          'createdAt': Timestamp.now(),
        });

        // Actualizar el displayName en el perfil del usuario
        await credential.user!.updateDisplayName(name);
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Iniciar sesión con email y contraseña
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener datos completos del usuario actual
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        // Si no hay datos en Firestore, crea un modelo básico con los datos de Auth
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          photoUrl: user.photoURL,
        );
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }
}