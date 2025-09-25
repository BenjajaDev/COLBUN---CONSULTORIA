import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Clase para manejar la conexión con Firestore
class FirestoreConnection {
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
      final conversationData = {
        'user_id': userId,
        'session_start': FieldValue.serverTimestamp(),
        'session_end': FieldValue.serverTimestamp(),
        'language': language,
        'messages': [], // Array vacío inicialmente
      };

      final docRef = await _firestore.collection('conversations').add(conversationData);
      print('✅ Conversación creada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error al crear conversación: $e');
      rethrow;
    }
  }

  /// Agrega un mensaje a una conversación existente
  Future<String> addMessageToConversation({
    required String conversationId,
    required String text,
    required String sender, // 'user' o 'bot'
    bool? isFaq,
    String? faqSource,
  }) async {
    try {
      // 1. Crear el mensaje individual
      final messageData = {
        'text': text,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
        'is_faq': isFaq ?? false,
        'faq_source': faqSource, // referencia si viene de FAQ
        'rating': null, // Se agregará después con el feedback
      };

      final messageRef = await _firestore.collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);

      // 2. Actualizar el array de mensajes en la conversación
      await _firestore.collection('conversations').doc(conversationId).update({
        'messages': FieldValue.arrayUnion([messageRef]),
        'session_end': FieldValue.serverTimestamp(), // Actualizar última actividad
      });

      print('✅ Mensaje agregado: ${messageRef.id}');
      return messageRef.id;
    } catch (e) {
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
      print('❌ Error al guardar rating: $e');
      rethrow;
    }
  }

  /// Obtiene una conversación completa con sus mensajes
  Future<Map<String, dynamic>?> getCompleteConversation(String conversationId) async {
    try {
      // Obtener la conversación
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) return null;

      final conversationData = conversationDoc.data() as Map<String, dynamic>;
      conversationData['id'] = conversationDoc.id;

      // Obtener todos los mensajes de la conversación
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      final messages = messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      conversationData['messageDetails'] = messages;

      return conversationData;
    } catch (e) {
      print('❌ Error al obtener conversación: $e');
      rethrow;
    }
  }
}
