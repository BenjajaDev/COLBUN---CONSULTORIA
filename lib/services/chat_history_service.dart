import 'dart:async';
import 'dart:convert';
import 'cache_service.dart';

// Modelo para guardar una conversación cacheada
class CachedConversation {
    const CachedConversation({
    required this.conversationId,
    required this.messages,
    this.lastLanguage,
    this.ownerId,
    });

    final String conversationId;
    final List<Map<String, dynamic>> messages;
    final String? lastLanguage;
    final String? ownerId;
}

// Servicio para manejar el historial de chat en caché local
class ChatHistoryService {
    // Prefijos y claves para guardar en shared_preferences
    static const _storagePrefix = 'chat_history_';
    static const _storageLanguageSuffix = '_language';
    static const lastConversationKey = 'chat_history_last_conversation';
    static const _fallbackConversationId = 'chat_history_local';
    static const int _maxCachedMessages = 100; // Límite de mensajes en caché

    // Servicio genérico para acceder a shared_preferences
    final CacheService _cacheService = CacheService();

    // Guarda el historial de mensajes y el idioma en caché local
    Future<void> saveHistory ({
        String? conversationId,
        required List<Map<String, dynamic>> messages,
        String? language,
        String? ownerId,
    }) async {
        // Usa el id de la conversación o uno por defecto
        final targetId =
            (conversationId != null && conversationId.isNotEmpty)
                ? conversationId
                : _fallbackConversationId;
    
    // Limitar a los últimos 100 mensajes para optimizar caché
    final cachedMessages = messages.length > _maxCachedMessages
        ? messages.sublist(messages.length - _maxCachedMessages)
        : messages;
    
    print('💾 Guardando caché: ${cachedMessages.length} mensajes (máx: $_maxCachedMessages)');
    
    // Serializa y guarda los mensajes
    final encoded = jsonEncode(cachedMessages);
    unawaited(_cacheService.setString(_conversationKey(targetId), encoded));

        // Guarda el idioma si está disponible
        if (language != null && language.isNotEmpty) {
            unawaited(_cacheService.setString(
                _languageKey(targetId),
                language
            ));
        }
            // Guarda el ownerId si está disponible
            if (ownerId != null && ownerId.isNotEmpty) {
                unawaited(_cacheService.setString(_ownerKey(targetId), ownerId));
            }
        // Guarda el id de la última conversación activa
        unawaited(_cacheService.setString(lastConversationKey, targetId));
    }

    // Recupera una conversación cacheada por id
    Future<CachedConversation?> loadConversation(String conversationId) async {
        // Lee los mensajes guardados y los deserializa
        final raw = await _cacheService.getString(_conversationKey(conversationId));
        if (raw == null) return null;

        final decoded = (jsonDecode(raw) as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        // Lee el idioma guardado
        final language = await _cacheService.getString(_languageKey(conversationId));
        // Lee el owner guardado (si existe)
        final owner = await _cacheService.getString(_ownerKey(conversationId));

        return CachedConversation(
            conversationId: conversationId,
            messages: decoded,
            lastLanguage: language,
            ownerId: owner,
        );
    }

    // Recupera la última conversación cacheada
    /// Recupera la última conversación cacheada.
    /// Si se proporciona [currentUserId], y la conversación cacheada pertenece a otro usuario,
    /// se devolverá null para evitar mezclar historiales entre usuarios.
    Future<CachedConversation?> loadLastConversation({String? currentUserId}) async {
        final lastId = await _cacheService.getString(lastConversationKey);
        if (lastId == null || lastId.isEmpty) return null;

        final cached = await loadConversation(lastId);
        if (cached == null) return null;

        if (currentUserId != null && cached.ownerId != null && cached.ownerId != currentUserId) {
            // El caché pertenece a otro usuario: no lo cargamos
            return null;
        }

        return cached;
    }

    // Borra el historial local de una conversación
    Future<void> clearHistory({String? conversationId}) async {
        // Usa el id de la conversación o uno por defecto
        final targetId =
            (conversationId != null && conversationId.isNotEmpty)
                ? conversationId
                : _fallbackConversationId;
        // Borra mensajes y idioma
        unawaited(_cacheService.remove(_conversationKey(targetId)));
        unawaited(_cacheService.remove(_languageKey(targetId)));

        // Borra el id de la última conversación si corresponde
        final lastId = await _cacheService.getString(lastConversationKey);
        if (lastId == targetId) {
            unawaited(_cacheService.remove(lastConversationKey));
        }
        // Borra owner si existe
        unawaited(_cacheService.remove(_ownerKey(targetId)));
    }

    // Genera la clave para guardar mensajes
    String _conversationKey(String conversationId) =>
        '$_storagePrefix$conversationId';
    // Genera la clave para guardar idioma
    String _languageKey(String conversationId) =>
        '$_storagePrefix$conversationId$_storageLanguageSuffix';
    // Genera la clave para guardar ownerId
    String _ownerKey(String conversationId) =>
        '$_storagePrefix${conversationId}_owner';
}