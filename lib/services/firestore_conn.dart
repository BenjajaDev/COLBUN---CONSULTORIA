// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para manejar conexión con Firestore y persistencia de conversaciones
class FirestoreConnection {
  static final FirestoreConnection _instance = FirestoreConnection._internal();
  factory FirestoreConnection() => _instance;
  FirestoreConnection._internal();

  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // GESTIÓN DE CONVERSACIONES
  // ============================================================================

  /// Obtiene o crea una conversación para el usuario actual
  Future<String> getOrCreateConversation() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // Usuario anónimo - usar ID temporal
        return 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
      }

      final userId = user.uid;
      print('🔍 Buscando conversación para usuario: $userId');

      // Buscar conversación activa del usuario
      final conversationsQuery = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (conversationsQuery.docs.isNotEmpty) {
        final conversationId = conversationsQuery.docs.first.id;
        print('✅ Conversación existente encontrada: $conversationId');
        return conversationId;
      }

      // No existe conversación activa, crear una nueva
      final conversationRef = await _firestore.collection('conversations').add({
        'userId': userId,
        'userEmail': user.email ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'messageCount': 0,
        'metadata': {
          'platform': 'flutter',
          'version': '1.0.0',
        }
      });

      print('✅ Nueva conversación creada: ${conversationRef.id}');
      return conversationRef.id;

    } catch (e) {
      print('❌ Error al obtener/crear conversación: $e');
      // Fallback: conversación temporal
      return 'temp_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Carga los mensajes de una conversación existente
  Future<List<Map<String, dynamic>>> loadConversationMessages(String conversationId) async {
    try {
      print('📥 Cargando mensajes de conversación: $conversationId');

      final messagesQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      final messages = messagesQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'sender': data['sender'] ?? 'bot',
          'text': data['text'] ?? '',
          'type': data['type'] ?? 'text',
          'timestamp': data['timestamp'],
          'visible': true,
          'feedback': data['feedback'],
        };
      }).toList();

      print('✅ Cargados ${messages.length} mensajes');
      return messages;

    } catch (e) {
      print('❌ Error al cargar mensajes: $e');
      return [];
    }
  }

  /// Guarda un mensaje en la conversación
  Future<String?> saveMessage({
    required String conversationId,
    required String sender,
    required String text,
    String type = 'text',
    String? messageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('💾 Guardando mensaje: $sender -> $text');

      final messageData = {
        'sender': sender,
        'text': text,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'conversationId': conversationId,
        if (metadata != null) 'metadata': metadata,
      };

      DocumentReference messageRef;
      
      if (messageId != null) {
        // Usar ID específico si se proporciona
        messageRef = _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(messageId);
        await messageRef.set(messageData);
      } else {
        // Generar ID automáticamente
        messageRef = await _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .add(messageData);
      }

      // Actualizar contador de mensajes y timestamp de conversación
      await _firestore.collection('conversations').doc(conversationId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      });

      print('✅ Mensaje guardado con ID: ${messageRef.id}');
      return messageRef.id;

    } catch (e) {
      print('❌ Error al guardar mensaje: $e');
      return null;
    }
  }

  /// Guarda feedback de un mensaje
  Future<bool> saveFeedback({
    required String conversationId,
    required String messageId,
    required bool wasUseful,
    String? additionalComments,
  }) async {
    try {
      print('👍👎 Guardando feedback: $messageId -> $wasUseful');

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'feedback': {
          'wasUseful': wasUseful,
          'timestamp': FieldValue.serverTimestamp(),
          'additionalComments': additionalComments,
        }
      });

      print('✅ Feedback guardado');
      return true;

    } catch (e) {
      print('❌ Error al guardar feedback: $e');
      return false;
    }
  }

  /// Marca una conversación como inactiva (cerrada)
  Future<bool> closeConversation(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'isActive': false,
        'closedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Conversación cerrada: $conversationId');
      return true;

    } catch (e) {
      print('❌ Error al cerrar conversación: $e');
      return false;
    }
  }

  // ============================================================================
  // MÉTODOS DE UTILIDAD
  // ============================================================================

  /// Obtiene estadísticas de uso del usuario
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final conversationsQuery = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: user.uid)
          .get();

      int totalMessages = 0;
      for (var doc in conversationsQuery.docs) {
        final data = doc.data();
        totalMessages += (data['messageCount'] as int? ?? 0);
      }

      return {
        'totalConversations': conversationsQuery.docs.length,
        'totalMessages': totalMessages,
        'userId': user.uid,
        'userEmail': user.email,
      };

    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {};
    }
  }

  /// Obtiene el estado de conexión con Firestore
  bool isConnected() {
    try {
      return _firestore.app.isAutomaticDataCollectionEnabled;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene información del usuario actual
  Map<String, dynamic> getCurrentUserInfo() {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'isLoggedIn': false,
        'isAnonymous': true,
        'userId': null,
        'email': null,
      };
    }

    return {
      'isLoggedIn': true,
      'isAnonymous': user.isAnonymous,
      'userId': user.uid,
      'email': user.email,
      'displayName': user.displayName,
    };
  }

  /// Formatea mensajes para historial de OpenAI
  List<Map<String, String>> formatMessagesForOpenAI(List<Map<String, dynamic>> messages) {
    return messages
        .where((msg) => msg['type'] == 'text' && msg['text'] != null)
        .map((msg) {
      return {
        'role': msg['sender'] == 'user' ? 'user' : 'assistant',
        'content': msg['text'] as String,
      };
    }).toList();
  }
}

// ============================================================================
// CLASE AUXILIAR PARA MANEJO DE ERRORES
// ============================================================================

class FirestoreError {
  final String code;
  final String message;
  final String? details;

  FirestoreError({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() {
    return 'FirestoreError($code): $message${details != null ? ' - $details' : ''}';
  }
}