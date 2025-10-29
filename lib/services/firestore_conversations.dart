import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Clase para manejar la conexión con Firestore
class FirestoreConnection {
  /// Borra todas las conversaciones y subcolecciones (messages) del usuario autenticado
  Future<void> deleteAllUserConversations() async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      final conversationQuery = _firestore
          .collection('conversations')
          .where('user_id', isEqualTo: userId);
      final conversationSnapshot = await conversationQuery.get();

      for (final doc in conversationSnapshot.docs) {
        await deleteConversationsByID(doc.id);
      }
      print(
          '✅ Todas las conversaciones del usuario $userId han sido eliminadas.');
    } catch (e) {
      try {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: 'deleteAllUserConversations');
      } catch (_) {}
      print("❌ Error al borrar conversaciones: $e");
    }
  }

  //Borra mensajes de conversacion por lotes y luego la conversacion
  Future<void> deleteConversationsByID(String conversationId) async {
    try {
      final messagesCol = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');
      //Borrar mensajes por lotes de 500(máximo por batch)
      const int batchSize = 500;
      while (true) {
        final snapshot = await messagesCol.limit(batchSize).get();
        if (snapshot.docs.isEmpty) break; // No hay más documentos que borrar

        final batch = firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      //Finalmente borrar la conversación
      await _firestore.collection('conversations').doc(conversationId).delete();
      print(
          '✅ Conversación $conversationId y sus mensajes han sido eliminados.');
    } on FirebaseException catch (e) {
      try {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: 'deleteConversationsByID_firebaseException');
      } catch (_) {}
      print(
          '❌ FirebaseException al borrar conversación $conversationId: code=${e.code}, message=${e.message}');
      rethrow;
    } catch (e) {
      try {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: 'deleteConversationsByID');
      } catch (_) {}
      print('❌ Error al borrar conversación $conversationId: $e');
      rethrow;
    }
  }

  static final FirestoreConnection _instance = FirestoreConnection._internal();
  factory FirestoreConnection() => _instance;
  FirestoreConnection._internal();

  // Instancias de Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters para acceder a las instancias
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  // Usuario actual
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isUserAuthenticated => _auth.currentUser != null;

  // ============================================================================
  // MÉTODOS PARA GUARDAR CONVERSACIONES Y MENSAJES
  // ============================================================================

  /// Crea una nueva conversación
  Future<String> createConversation({
    required String userId,
    required String language,
  }) async {
    try {
      print(
          '🔎 createConversation called - userId=$userId, firestoreApp=${_firestore.app.name}');
      final conversationData = {
        'user_id': userId,
        'session_start': FieldValue.serverTimestamp(),
        'session_end': FieldValue.serverTimestamp(),
        'language': language,
        'messages': [], // Array vacío inicialmente
      };

      final docRef =
          await _firestore.collection('conversations').add(conversationData);
      print('✅ Conversación creada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      try {
        FirebaseCrashlytics.instance
            .recordError(e, StackTrace.current, reason: 'createConversation');
      } catch (_) {}
      if (e is FirebaseException) {
        print(
            '❌ FirebaseException en createConversation: code=${e.code}, message=${e.message}');
      } else {
        print('❌ Error al crear conversación: $e');
      }
      rethrow;
    }
  }

  /// Agrega un mensaje a una conversación existente
  Future<String> addMessageToConversation({
    required String conversationId,
    required String text,
    required String sender, // 'user' o 'bot'
    String? type,
    bool? isFaq,
    String? faqSource,
  }) async {
    try {
      print(
          '🔎 addMessageToConversation called - conversationId=$conversationId, sender=$sender, currentUserId=${_auth.currentUser?.uid}');
      // 1. Crear el mensaje individual
      final messageData = {
        'text': text,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
        'is_faq': isFaq ?? false,
        'faq_source': faqSource, // referencia si viene de FAQ
        'rating': null, // Se agregará después con el feedback
      };
      if (type != null) {
        messageData['type'] = type;
      }

      final messageRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);

      // 2. Actualizar el array de mensajes en la conversación
      await _firestore.collection('conversations').doc(conversationId).update({
        'messages': FieldValue.arrayUnion([messageRef]),
        'session_end':
            FieldValue.serverTimestamp(), // Actualizar última actividad
      });

      print('✅ Mensaje agregado: ${messageRef.id}');
      return messageRef.id;
    } on FirebaseException catch (e) {
      try {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: 'addMessageToConversation_firebaseException');
      } catch (_) {}
      print(
          '❌ FirebaseException en addMessageToConversation: code=${e.code}, message=${e.message}');
      // Si la conversación no existe (not-found), intentar crearla y reintentar
      if (e.code == 'not-found') {
        final uid = _auth.currentUser?.uid;
        if (uid == null) {
          print(
              '⚠️ Usuario no autenticado: no se puede crear conversación remota tras not-found.');
          rethrow;
        }

        try {
          print(
              '🔁 Conversación $conversationId no encontrada. Creando nueva conversación remota para el usuario $uid...');
          // Usamos un idioma por defecto 'es' si no hay contexto de idioma aquí
          final newConversationId =
              await createConversation(userId: uid, language: 'es');
          print(
              '🔗 Conversación creada automáticamente: $newConversationId. Reintentando subida del mensaje...');

          // Reintentar añadir el mensaje a la nueva conversación
          final retryMessageRef = await _firestore
              .collection('conversations')
              .doc(newConversationId)
              .collection('messages')
              .add({
            ...{
              'text': text,
              'sender': sender,
              'timestamp': FieldValue.serverTimestamp(),
              'is_faq': isFaq ?? false,
              'faq_source': faqSource,
              'rating': null,
            },
            if (type != null) 'type': type,
          });

          await _firestore
              .collection('conversations')
              .doc(newConversationId)
              .update({
            'messages': FieldValue.arrayUnion([retryMessageRef]),
            'session_end': FieldValue.serverTimestamp(),
          });

          print(
              '✅ Mensaje agregado tras crear conversación: ${retryMessageRef.id}');
          return retryMessageRef.id;
        } catch (e2) {
          try {
            FirebaseCrashlytics.instance.recordError(e2, StackTrace.current,
                reason: 'addMessageToConversation_retry');
          } catch (_) {}
          print('❌ Error creando conversación y reintentando mensaje: $e2');
          rethrow;
        }
      }
      rethrow;
    } catch (e) {
      try {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: 'addMessageToConversation');
      } catch (_) {}
      print('❌ Error al agregar mensaje: $e');
      rethrow;
    }
  }

  /// Guarda el rating/feedback de un mensaje
  Future<void> saveMessageRating({
    required String conversationId,
    required String messageId,
    required bool helpful,
    String? feedback,
  }) async {
    try {
      // Crear el rating
      final ratingData = {
        'helpful': helpful,
        'feedback': feedback,
      };

      // Actualizar el mensaje con el rating
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'rating': ratingData,
      });

      print('✅ Rating guardado para mensaje: $messageId');
    } catch (e) {
      try {
        FirebaseCrashlytics.instance
            .recordError(e, StackTrace.current, reason: 'saveMessageRating');
      } catch (_) {}
      print('❌ Error al guardar rating: $e');
      rethrow;
    }
  }

  /// Obtiene una conversación completa con sus mensajes
  Future<Map<String, dynamic>?> getCompleteConversation(
      String conversationId) async {
    try {
      // Obtener la conversación
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) return null;

      final conversationData =
          Map<String, dynamic>.from(conversationDoc.data() ?? {});
      conversationData['id'] = conversationDoc.id;

      //Convertir timestamps a ISO strings legibles
      if (conversationData['session_start'] is Timestamp) {
        conversationData['session_start'] =
            (conversationData['session_start'] as Timestamp)
                .toDate()
                .toIso8601String();
      }
      if (conversationData['session_end'] is Timestamp) {
        conversationData['session_end'] =
            (conversationData['session_end'] as Timestamp)
                .toDate()
                .toIso8601String();
      }

      // Obtener todos los mensajes de la conversación
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      final messages = messagesSnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        final rawTimestamp = data['timestamp'];
        
        // Log para diagnóstico
        print('📥 Mensaje ${doc.id}: timestamp raw = $rawTimestamp (tipo: ${rawTimestamp.runtimeType})');
        
        // Convertir timestamp a ISO string legible para evitar encoding
        if (rawTimestamp is Timestamp) {
          data['timestamp'] = rawTimestamp.toDate().toIso8601String();
          print('✅ Mensaje ${doc.id}: timestamp convertido a ${data['timestamp']}');
        } else if (rawTimestamp == null) {
          print('⚠️ Mensaje ${doc.id}: timestamp es NULL - Firebase puede estar procesando serverTimestamp()');
        } else {
          print('⚠️ Mensaje ${doc.id}: timestamp tipo inesperado: ${rawTimestamp.runtimeType}');
        }
        
        data['id'] = doc.id;
        return data;
      }).toList();

      conversationData['messageDetails'] = messages;

      return conversationData;
    } catch (e) {
      try {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: 'getCompleteConversation');
      } catch (_) {}
      print('❌ Error al obtener conversación: $e');
      rethrow;
    }
  }
}
