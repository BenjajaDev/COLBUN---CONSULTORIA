// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:consultoria_chat_bot/models/user_model.dart';

// ===========================================================================
// SERVICIO DE AUTENTICACION
// ===========================================================================
/// Maneja todas las operaciones de autenticacion con Firebase Authentication
/// y sincronizacion de datos de usuario con Firestore
class AuthService {
  // ===========================================================================
  // INSTANCIAS DE FIREBASE
  // ===========================================================================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // STREAMS Y PROPIEDADES
  // ===========================================================================
  /// Stream para escuchar cambios en el estado de autenticacion
  /// Emite el usuario actual o null cuando cierra sesion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Obtiene el usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  // ===========================================================================
  // REGISTRO DE USUARIOS
  // ===========================================================================
  /// Registra un nuevo usuario con email y password
  /// Tambien guarda informacion adicional en Firestore
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      // Crear el usuario en Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar informacion adicional del usuario en Firestore
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
      // Reportar error a Crashlytics para monitoreo
      try {
        FirebaseCrashlytics.instance
            .recordError(e, StackTrace.current, reason: 'AuthService.register');
      } catch (_) {}
      rethrow; // Re-lanzar el error para que el BLoC lo maneje
    }
  }

  // ===========================================================================
  // INICIO DE SESION
  // ===========================================================================
  /// Inicia sesion con email y password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Reportar error a Crashlytics
      try {
        FirebaseCrashlytics.instance
            .recordError(e, StackTrace.current, reason: 'AuthService.signIn');
      } catch (_) {}
      rethrow;
    }
  }

  // ===========================================================================
  // CIERRE DE SESION
  // ===========================================================================
  /// Cierra la sesion del usuario actual
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ===========================================================================
  // OBTENCION DE DATOS DEL USUARIO
  // ===========================================================================
  /// Obtiene los datos completos del usuario actual desde Firestore
  /// Si no hay datos en Firestore, crea un modelo basico con datos de Auth
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Intentar obtener datos desde Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        // Si no hay datos en Firestore, crea un modelo basico con los datos de Auth
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          photoUrl: user.photoURL,
        );
      }
    } catch (e) {
      // Reportar error a Crashlytics
      try {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: 'AuthService.getCurrentUserData');
      } catch (_) {}
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }
}
