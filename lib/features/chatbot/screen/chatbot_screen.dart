import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/faq_bloc.dart';
import '../utils/app_colors.dart';
import '../components/chatbot_header.dart';
import '../components/chatbot_body.dart';
import '../components/chatbot_footer.dart';
import '../../../services/openai_service.dart';
import '../../../services/firestore_conversations.dart';
import '../../../services/firestore_faq_service.dart';
import '../../../services/language_service.dart';
import '../../../services/chat_history_service.dart';
import '../../../services/firestore_emergency.dart';
import '../../../services/response_cache_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_faq_cache_service.dart';
import '../../../shared_widgets/connectivity_indicator.dart';
import '../utils/chatbot_strings.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  // ===========================================================================
  // CONTROLADORES Y ANIMACIONES
  // ===========================================================================
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;
  Animation<double>? _typingAnimation;

  // ===========================================================================
  // ESTADO DE LA APLICACIÓN
  // ===========================================================================
  final List<Map<String, dynamic>> messages = [];
  bool _isTyping = false;
  bool _isLoadingConversation = false;
  bool _hasRestoredLocalHistory = false;

  // ===========================================================================
  // DATOS Y SERVICIOS
  // ===========================================================================
  List<Faq> _allLoadedFaqs = [];
  List<EmergencyContact> _currentEmergencyContacts = [];
  String? _currentConversationId;
  String _currentLanguage = 'es';
  final Map<String, String> _messageLanguages = {};

  // Servicios
  final FirestoreConnection _firestoreConnection = FirestoreConnection();
  final LanguageService _languageService = LanguageService();
  final EmergencyService _emergencyService = EmergencyService();
  late FaqService _faqService;
  late OpenAIService _openAIService;
  late final ChatHistoryService _chatHistoryService;
  late final ResponseCacheService _responseCacheService;
  late ConnectivityService _connectivityService;
  late OfflineFaqCacheService _offlineFaqCache;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;
  // Timer usado para agrupar persistencias locales y evitar IO frecuente
  Timer? _persistTimer;

  // ===========================================================================
  // CONSTANTES Y CONFIGURACIÓN
  // ===========================================================================
  final Set<String> _contextualTriggers = const {
    'por que',
    'porque',
    'porqué',
    'why',
    'explica mas',
    'dame mas detalles',
    'a que te refieres'
  };

  @override
  void initState() {
    super.initState();
    _faqService = context.read<FaqService>();
    _openAIService = context.read<OpenAIService>();
    _connectivityService = context.read<ConnectivityService>();
    _offlineFaqCache = context.read<OfflineFaqCacheService>();
    
    _log('🔧 ChatbotScreen initState - Servicios inicializados');
    _log('📊 FAQs en caché offline: ${_offlineFaqCache.cachedFaqs.length}');
    
    _chatHistoryService =
        ChatHistoryService(); // Inicializa el servicio de caché local
    _responseCacheService =
        ResponseCacheService(); // Inicializa caché de respuestas
    
    // Inicializar estado de conectividad
    _isOnline = _connectivityService.isOnline;
    _log('🌐 Estado de conectividad inicial: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivityService
        .onConnectivityChanged
        .listen(_handleConnectivityChange);
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..addListener(() {
        // NOTE: Removed per-frame setState here to avoid rebuilding the whole
        // ChatbotScreen on every animation tick. The typing indicator is
        // handled locally inside `ChatbotBody` through the passed
        // [typingAnimation] and an AnimatedBuilder.
      });
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
    _loadAllFaqs();
    _loadEmergencyContacts();

    _restoreCachedHistory().then((_) {
      _initializeConversation().then((_) {
        // Sincronizar con Firebase en segundo plano después de inicializar
        _syncWithFirestore();
      });
    });
  }

  void _log(Object? o) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(o);
    }
  }

  Future<void> _reportErrorToCrashlytics(Object error, StackTrace? stack,
      {Map<String, dynamic>? context}) async {
    try {
      final crash = FirebaseCrashlytics.instance;
      // Añadir información contextual si está disponible
      if (context != null) {
        context.forEach((key, value) {
          crash.setCustomKey(key, value?.toString() ?? '');
        });
      }
      await crash.recordError(error, stack,
          reason: 'Captured in ChatbotScreen');
    } catch (_) {
      // No bloquear ni re-lanzar: esto es solo telemetry
    }
  }

  void _handleConnectivityChange(bool isOnline) {
    if (!mounted) return;
    
    setState(() {
      _isOnline = isOnline;
    });

    if (!isOnline) {
      // Mostrar SnackBar al perder conexión
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Sin conexión - usando FAQs esenciales'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Mostrar SnackBar al recuperar conexión
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 12),
              Text('Conexión restaurada'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // 1. Actualizar caché de FAQs al recuperar conexión
      _updateFaqCache();
      
      // 2. Crear conversación si no existe (por ejemplo, si inició offline)
      _ensureConversationExists();
      
      // 3. Sincronizar historial con Firebase después de reconectar
      _syncWithFirestore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingController.dispose();
    _languageService.close(); // Cerrar el servicio de idioma
    _persistTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // GESTIÓN DE CONVERSACIONES E HISTORIAL
  // ===========================================================================
  Future<void> _restoreCachedHistory() async {
    final cached = await _chatHistoryService.loadLastConversation(
        currentUserId: _firestoreConnection.currentUserId);
    if (!mounted || cached == null) return;

    // Normalizar mensajes cacheados para evitar problemas de tipos (ej. List<dynamic>)
    final normalizedCachedMessages = cached.messages.map((m) {
      final Map<String, dynamic> msg = Map<String, dynamic>.from(m);

      // Normalizar options -> List<String>
      final rawOptions = msg['options'];
      if (rawOptions == null) {
        msg['options'] = <String>[];
      } else if (rawOptions is List) {
        msg['options'] = rawOptions
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        msg['options'] = <String>[];
      }

      // Asegurar type
      if (msg['type'] == null) msg['type'] = '';

      // Normalizar timestamp priorizando el del servidor Firebase (UTC)
      final ts = msg['timestamp'];
      if (ts is Timestamp) {
        // ✅ MEJOR: Timestamp de Firebase (UTC del servidor)
        msg['timestamp'] = ts.toDate().toUtc().toIso8601String();
        _log(
            '✅ Usando timestamp del servidor Firebase para mensaje: ${msg['id']}');
      } else if (ts is DateTime) {
        // ⚠️ DateTime local (menos confiable)
        msg['timestamp'] = ts.toUtc().toIso8601String();
        _log('⚠️ Timestamp es DateTime local para mensaje: ${msg['id']}');
      } else if (ts is String && ts.isNotEmpty && ts != 'unknown') {
        // ✅ Ya es String ISO (probablemente ya normalizado del servidor)
        msg['timestamp'] = ts;
      } else {
        // ❌ Sin timestamp válido: marcar como desconocido
        msg['timestamp'] = 'unknown';
        _log(
            '⚠️ Mensaje ${msg['id']} sin timestamp válido - marcado como unknown');
      }

      return msg;
    }).toList();

    setState(() {
      messages
        ..clear()
        ..addAll(normalizedCachedMessages);
      _currentConversationId = cached.conversationId;
    });

    _currentLanguage = cached.lastLanguage ?? 'es';
    _rebuildMessageLanguageIndex(messages);
    _hasRestoredLocalHistory = true;
    // Historial local restaurado

    //Verificar si al conversación local tiene un documento remoto en Firestore
    //Si no existe, crear comversión remota nueva con los mensajes cacheados
    try {
      if (_currentConversationId != null) {
        final remoteConversation = await _firestoreConnection
            .getCompleteConversation(_currentConversationId!);
        if (remoteConversation == null) {
          final uid = _firestoreConnection.currentUserId;
          if (uid == null) {
            _log(
                '⚠️ Usuario no autenticado: no se puede crear conversación remota.');
            return;
          }

          final newConversationId =
              await _firestoreConnection.createConversation(
            userId: uid,
            language: _currentLanguage,
          );
          _log(
              '🔗 Conversación remota creada: $newConversationId  (se sincroniza caché local)');

          _currentConversationId = newConversationId;

          // Subir mensajes cacheados a la nueva conversación remota.
          // Hacemos una copia para evitar mutaciones durante la iteración.
          final cachedMessages = List<Map<String, dynamic>>.from(messages);
          // Subir mensajes cacheados en background para no bloquear la UI
          _uploadCachedMessagesInBackground(
              List<Map<String, dynamic>>.from(cachedMessages));
        } else {
          _log(
              '✅ Conversación remota existente encontrada: $_currentConversationId');
        }
      }
    } catch (e) {
      _log('❌ Error verificando conversación remota: $e');
      // Reportar a Crashlytics (no bloqueante)
      _reportErrorToCrashlytics(e, StackTrace.current, context: {
        'where': 'restoreCachedHistory_checkRemote',
        'conversationId': _currentConversationId ?? 'null',
      });
    }
  }

  void _rebuildMessageLanguageIndex(List<Map<String, dynamic>> source) {
    _messageLanguages.clear();
    for (final message in source) {
      final id = message['id'] as String?;
      final language = message['language'] as String?;
      if (id != null && language != null) {
        _messageLanguages[id] = language;
      }
    }
  }

  /// Sincroniza mensajes locales con Firebase de forma bidireccional
  Future<void> _syncWithFirestore() async {
    if (_currentConversationId == null) {
      _log('⚠️ No hay conversationId para sincronizar');
      return;
    }

    try {
      _log('🔄 Iniciando sincronización bidireccional con Firebase...');
      final remoteConversation = await _firestoreConnection
          .getCompleteConversation(_currentConversationId!);

      if (remoteConversation == null) {
        _log('⚠️ No se encontró conversación remota');
        return;
      }

      final remoteMessages =
          remoteConversation['messageDetails'] as List? ?? [];
      final localMessageIds = messages.map((m) => m['id']).toSet();

      // 1. Identificar mensajes nuevos en remoto que no están en local
      final newRemoteMessages = remoteMessages
          .where((m) => m['id'] != null && !localMessageIds.contains(m['id']))
          .toList();

      if (newRemoteMessages.isNotEmpty) {
        _log(
            '⬇️ Sincronizando ${newRemoteMessages.length} mensajes nuevos desde Firebase');

        // Normalizar mensajes remotos antes de añadirlos
        final normalizedRemote = newRemoteMessages.map((m) {
          final msg = Map<String, dynamic>.from(m);

          // Normalizar options
          final rawOptions = msg['options'];
          if (rawOptions == null) {
            msg['options'] = <String>[];
          } else if (rawOptions is List) {
            msg['options'] = rawOptions
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          } else {
            msg['options'] = <String>[];
          }

          // Asegurar type
          if (msg['type'] == null) msg['type'] = '';

          // Normalizar timestamp - priorizar timestamp del servidor
          final timestampValue = msg['timestamp'];
          if (timestampValue is Timestamp) {
            // Timestamp de Firebase (mejor caso)
            msg['timestamp'] =
                timestampValue.toDate().toUtc().toIso8601String();
            _log(
                '✅ _syncWithFirestore: Usando timestamp del servidor (${msg['id']})');
          } else if (timestampValue is String && timestampValue.isNotEmpty) {
            // Ya es String ISO
            try {
              DateTime.parse(timestampValue); // Validar formato
              _log(
                  '✅ _syncWithFirestore: Timestamp String válido (${msg['id']})');
            } catch (e) {
              _log(
                  '⚠️ _syncWithFirestore: Timestamp String inválido, marcando como unknown (${msg['id']})');
              msg['timestamp'] = 'unknown';
            }
          } else if (timestampValue is DateTime) {
            // DateTime local (no ideal)
            msg['timestamp'] = timestampValue.toUtc().toIso8601String();
            _log(
                '⚠️ _syncWithFirestore: Timestamp es DateTime local (${msg['id']})');
          } else {
            // Sin timestamp válido
            _log(
                '❌ _syncWithFirestore: Sin timestamp válido, marcando como unknown (${msg['id']})');
            msg['timestamp'] = 'unknown';
          }

          return msg;
        }).toList();

        setState(() {
          messages.addAll(normalizedRemote);
          // Ordenar por timestamp para mantener orden correcto
          messages.sort((a, b) {
            try {
              final aTime = DateTime.parse(a['timestamp'] ?? '');
              final bTime = DateTime.parse(b['timestamp'] ?? '');
              return aTime.compareTo(bTime);
            } catch (e) {
              return 0;
            }
          });
        });

        _rebuildMessageLanguageIndex(messages);
        await _persistMessages(); // Actualizar caché local
        _log('✅ Mensajes remotos sincronizados y caché actualizado');
      }

      // 2. Identificar mensajes locales que no están en remoto (falló la subida)
      final remoteMessageIds = remoteMessages.map((m) => m['id']).toSet();
      final orphanMessages = messages
          .where((m) => m['id'] != null && !remoteMessageIds.contains(m['id']))
          .toList();

      if (orphanMessages.isNotEmpty) {
        _log(
            '⬆️ Subiendo ${orphanMessages.length} mensajes huérfanos a Firebase');
        for (final msg in orphanMessages) {
          final text = msg['text'] as String?;
          final sender = msg['sender'] as String?;
          if (text != null && text.isNotEmpty && sender != null) {
            try {
              final uploadedId =
                  await _firestoreConnection.addMessageToConversation(
                conversationId: _currentConversationId!,
                text: text,
                sender: sender,
                type: msg['type'] as String?,
                isFaq: msg['source'] != null &&
                    (msg['source'] as String).contains('firestore'),
                faqSource: msg['source'] as String?,
              );
              // Actualizar el ID local con el ID de Firebase
              msg['id'] = uploadedId;
              _log('✅ Mensaje huérfano subido con ID: $uploadedId');
            } catch (e) {
              _log('❌ Error subiendo mensaje huérfano: $e');
            }
          }
        }
        await _persistMessages(); // Actualizar caché con nuevos IDs
        _log('✅ Mensajes huérfanos sincronizados');
      }

      if (newRemoteMessages.isEmpty && orphanMessages.isEmpty) {
        _log('✅ Sincronización completa: todo está actualizado');
      }
    } catch (e) {
      _log('❌ Error en sincronización bidireccional: $e');
    }
  }

  Future<void> _persistMessages() async {
    await _chatHistoryService.saveHistory(
      conversationId: _currentConversationId,
      messages: List<Map<String, dynamic>>.from(messages),
      language: _currentLanguage,
      ownerId: _firestoreConnection.currentUserId,
    );
    // Guarda el historial localmente
  }

  void _schedulePersistMessages(
      {Duration delay = const Duration(milliseconds: 800)}) {
    // Cancelar timer previo si existe
    _persistTimer?.cancel();
    _persistTimer = Timer(delay, () {
      // Fire-and-forget: ChatHistoryService internamente sigue guardando
      _persistMessages();
    });
  }

  /// Sube mensajes cacheados a Firestore en background para no bloquear la inicialización
  void _uploadCachedMessagesInBackground(
      List<Map<String, dynamic>> cachedMessages) {
    // Ejecutar asíncronamente sin bloquear init
    Future(() async {
      for (final msg in cachedMessages) {
        try {
          // Normalizar 'options'
          final rawOptionsCached = msg['options'];
          if (rawOptionsCached == null) {
            msg['options'] = <String>[];
          } else if (rawOptionsCached is List) {
            msg['options'] = rawOptionsCached
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          } else {
            msg['options'] = <String>[];
          }

          final text = msg['text'] as String?;
          final sender = msg['sender'] as String?;
          final msgType = msg['type'] as String?;
          if (text != null && text.isNotEmpty && sender != null) {
            final uploadedId =
                await _firestoreConnection.addMessageToConversation(
              conversationId: _currentConversationId!,
              text: text,
              sender: sender,
              type: msgType,
              isFaq: msg['source'] != null &&
                  (msg['source'] as String).contains('firestore'),
              faqSource: msg['source'] as String?,
            );
            // Actualizar el ID del mensaje en la copia local
            msg['id'] = uploadedId;
          }
        } catch (e) {
          // Registrar, pero no bloquear el proceso
          _log(
              '❌ Error subiendo mensaje cacheado a Firestore (background): $e');
          _reportErrorToCrashlytics(e, StackTrace.current, context: {
            'where': 'uploadCachedMessagesInBackground',
            'conversationId': _currentConversationId ?? 'null',
          });
        }
      }

      // Intentar persistir el cache actualizado localmente
      try {
        await _persistMessages();
      } catch (e) {
        _log('⚠️ Error persistiendo cache tras subida background: $e');
        _reportErrorToCrashlytics(e, StackTrace.current, context: {
          'where': 'persist_after_uploadCached',
          'conversationId': _currentConversationId ?? 'null',
        });
      }
    });
  }

  /// Sincroniza timestamp del servidor en background sin bloquear UI
  void _syncMessageTimestampInBackground(String messageId) {
    // Ejecutar en background para no bloquear la UI
    Future(() async {
      try {
        // Esperar un momento para que Firebase procese el serverTimestamp
        await Future.delayed(const Duration(milliseconds: 500));

        final doc = await _firestoreConnection.firestore
            .collection('conversations')
            .doc(_currentConversationId!)
            .collection('messages')
            .doc(messageId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final serverTimestamp = data?['timestamp'];

          if (serverTimestamp != null && serverTimestamp is Timestamp) {
            final serverTime =
                serverTimestamp.toDate().toUtc().toIso8601String();

            // Actualizar timestamp en la lista de mensajes local
            final messageIndex =
                messages.indexWhere((m) => m['id'] == messageId);
            if (messageIndex != -1) {
              messages[messageIndex]['timestamp'] = serverTime;
              _log(
                  '✅ Timestamp del servidor sincronizado en background: $serverTime');

              // Persistir actualización
              _schedulePersistMessages();
            }
          }
        }
      } catch (e) {
        // Error no crítico - el timestamp local ya está funcionando
        _log(
            '⚠️ No se pudo sincronizar timestamp del servidor (no crítico): $e');
      }
    });
  }

  /// Asegura que existe una conversación en Firestore (útil al recuperar conexión)
  Future<void> _ensureConversationExists() async {
    if (_currentConversationId != null) {
      _log('✅ Ya existe conversationId: $_currentConversationId');
      return;
    }
    
    if (!_isOnline) {
      _log('⚠️ No se puede crear conversación: sin conexión');
      return;
    }
    
    try {
      final uid = _firestoreConnection.currentUserId;
      if (uid == null) {
        _log('⚠️ Usuario no autenticado: no se puede crear conversación');
        return;
      }
      
      _log('🔗 Creando conversación tras recuperar conexión...');
      _currentConversationId = await _firestoreConnection.createConversation(
        userId: uid,
        language: _currentLanguage,
      );
      
      _log('✅ Conversación creada: $_currentConversationId');
      
      // Si hay mensajes locales (del caché), subirlos a la nueva conversación
      if (messages.isNotEmpty) {
        _log('⬆️ Subiendo ${messages.length} mensajes locales a Firestore...');
        _uploadCachedMessagesInBackground(List<Map<String, dynamic>>.from(messages));
      }
      
    } catch (e) {
      _log('❌ Error creando conversación al recuperar conexión: $e');
      _reportErrorToCrashlytics(e, StackTrace.current, context: {
        'where': 'ensureConversationExists',
        'isOnline': _isOnline.toString(),
      });
    }
  }

  /// Inicializa la conversación cargando mensajes existentes o creando una nueva
  Future<void> _initializeConversation() async {
    setState(() {
      _isLoadingConversation = true;
    });

    try {
      // SI ESTÁ OFFLINE: Saltar creación de conversación en Firestore
      if (!_isOnline) {
        _log('📴 Modo offline: Saltando inicialización de Firestore');
        setState(() {
          _isLoadingConversation = false;
        });
        return;
      }

      if (_currentConversationId == null) {
        _currentConversationId = await _firestoreConnection.createConversation(
          userId: _firestoreConnection.currentUserId!,
          language: _currentLanguage,
        );
        _log('🔗 Conversación inicializada: $_currentConversationId');
        // Conversación creada en Firestore
      }

      // SI YA SE RESTAURÓ EL HISTORIAL LOCAL: Solo sincronizar, no reemplazar mensajes
      if (_hasRestoredLocalHistory && messages.isNotEmpty) {
        _log('✅ Historial ya restaurado desde caché local (${messages.length} mensajes) - saltando carga desde Firestore');
        setState(() {
          _isLoadingConversation = false;
        });
        return;
      }

      final conversationId = _currentConversationId!;
      final conversationData =
          await _firestoreConnection.getCompleteConversation(conversationId);
      final existingMessages =
          conversationData?['messageDetails'] as List<dynamic>? ?? [];

      if (existingMessages.isNotEmpty) {
        final correctlyTypedMessages = existingMessages
            .map((msg) => Map<String, dynamic>.from(msg))
            .toList();
        // Normalizar campos que pueden venir nulos desde Firestore/caché
        for (final m in correctlyTypedMessages) {
          // options siempre debe ser List<String>
          final rawOptions = m['options'];
          if (rawOptions == null) {
            m['options'] = <String>[];
          } else if (rawOptions is List) {
            m['options'] = rawOptions
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          } else {
            m['options'] = <String>[];
          }

          // Asegurar que 'type' existe (evita nulls inesperados)
          if (m['type'] == null) m['type'] = '';

          // Normalizar timestamp - priorizar timestamp del servidor
          final timestampValue = m['timestamp'];
          if (timestampValue is Timestamp) {
            // Timestamp de Firebase (mejor caso)
            m['timestamp'] = timestampValue.toDate().toUtc().toIso8601String();
            _log(
                '✅ _initializeConversation: Usando timestamp del servidor (${m['id']})');
          } else if (timestampValue is String && timestampValue.isNotEmpty) {
            // Ya es String ISO
            try {
              DateTime.parse(timestampValue); // Validar formato
              _log(
                  '✅ _initializeConversation: Timestamp String válido (${m['id']})');
            } catch (e) {
              _log(
                  '⚠️ _initializeConversation: Timestamp String inválido, marcando como unknown (${m['id']})');
              m['timestamp'] = 'unknown';
            }
          } else if (timestampValue is DateTime) {
            // DateTime local (no ideal)
            m['timestamp'] = timestampValue.toUtc().toIso8601String();
            _log(
                '⚠️ _initializeConversation: Timestamp es DateTime local (${m['id']})');
          } else {
            // Sin timestamp válido - marcar como unknown
            _log(
                '❌ _initializeConversation: Sin timestamp válido, marcando como unknown (${m['id']})');
            m['timestamp'] = 'unknown';
          }
        }

        setState(() {
          messages
            ..clear()
            ..addAll(correctlyTypedMessages);
        });
        _rebuildMessageLanguageIndex(messages);
        await _persistMessages(); // Cachea la última versión
        // Cache actualizado con mensajes de Firestore
        _log('📥 Cargados ${existingMessages.length} mensajes existentes');
      } else if (!_hasRestoredLocalHistory && messages.isEmpty) {
        _initializeChat();
      }
    } catch (e) {
      _log('❌ Error al inicializar conversación: $e');
      _reportErrorToCrashlytics(e, StackTrace.current, context: {
        'where': 'initializeConversation',
        'conversationId': _currentConversationId ?? 'null',
      });
      if (!_hasRestoredLocalHistory && messages.isEmpty) {
        _initializeChat();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConversation = false;
        });
      }
    }
  }

  void _initializeChat() {
    final welcomeMessage =
        ChatbotStrings.get('welcome.message', _currentLanguage);
    addMessage(
      sender: "bot",
      text: welcomeMessage,
      type: "welcome_message",
      language: _currentLanguage, // Pasar el idioma
      saveToDatabase: true, // Guardamos el mensaje de bienvenida
    ).then((_) =>
        _schedulePersistMessages()); // Cachea el mensaje de bienvenida (debounced)
  }

  void _clearChatHistory() async {
    _log('🗑️ INICIANDO BORRADO DE HISTORIAL');
    
    // 1. PRIMERO: Limpiar UI inmediatamente
    if (mounted) {
      setState(() {
        messages.clear();
      });
      _log('✅ UI limpiada - messages.length: ${messages.length}');
    }

    // 2. Borrar conversación en Firestore (solo si está online)
    if (_isOnline) {
      try {
        if (_currentConversationId != null) {
          await _firestoreConnection
              .deleteConversationsByID(_currentConversationId!);
          _log('🗑️ Conversación remota borrada: $_currentConversationId');
        } else {
          await _firestoreConnection.deleteAllUserConversations();
          _log('🗑️ Todas las conversaciones remotas borradas');
        }
      } catch (e) {
        _log('❌ Error al borrar historial remoto: $e');
        _reportErrorToCrashlytics(e, StackTrace.current, context: {
          'where': 'clearChatHistory',
          'conversationId': _currentConversationId ?? 'null',
        });
      }
    } else {
      _log('📴 Modo offline: Saltando borrado remoto');
    }

    // 3. Borrar historial local (caché)
    final oldConversationId = _currentConversationId;
    await _chatHistoryService.clearHistory(conversationId: oldConversationId);
    _log('🗑️ Historial local borrado');

    // 4. Resetear el ID de conversación Y la bandera de restauración
    _currentConversationId = null;
    _hasRestoredLocalHistory = false;

    // 5. Crear nueva conversación (solo si está online)
    if (_isOnline) {
      try {
        _currentConversationId = await _firestoreConnection.createConversation(
          userId: _firestoreConnection.currentUserId!,
          language: _currentLanguage,
        );
        _log('✅ Nueva conversación creada: $_currentConversationId');
      } catch (e) {
        _log('❌ Error creando nueva conversación: $e');
      }
    }

    // 6. FINALMENTE: Agregar mensaje de bienvenida
    _initializeChat();
    _log('✅ BORRADO COMPLETADO - Mensaje de bienvenida agregado');
  }

  // ===========================================================================
  // GESTIÓN DE MENSAJES
  // ===========================================================================
  Future<String?> addMessage({
    required String sender,
    String? text,
    String? type,
    List<String>? options,
    String? messageId,
    int? insertAtIndex,
    bool saveToDatabase = true,
    String? source,
    String? link,
    Map<String, dynamic>? extras,
    String? language, // parametro nuevo
    bool autoScroll = true,
  }) async {
    final newMessage = {
      "id": messageId, // Se actualizará con el ID de Firestore
      "sender": sender, "text": text, "type": type,
      "options": options ?? <String>[],
      "feedback": null, "visible": true, "source": source, "link": link,
      "extras": extras, "language": language,
      "timestamp": null, // Se actualizará con serverTimestamp de Firebase
    };

    String? generatedMessageId;

    if (saveToDatabase &&
        _currentConversationId != null &&
        text != null &&
        text.isNotEmpty &&
        _isOnline) {
      try {
        // 1. Guardar mensaje en Firebase (obtiene serverTimestamp automáticamente)
        generatedMessageId =
            await _firestoreConnection.addMessageToConversation(
          conversationId: _currentConversationId!,
          text: text,
          sender: sender,
          type: type,
          isFaq: source != null && source.contains('firestore'),
          faqSource: source,
        );
        newMessage['id'] = generatedMessageId;

        // 2. OPTIMIZACIÓN: Usar timestamp local en lugar de reintentos a Firebase
        // El timestamp del servidor se sincronizará automáticamente en background
        newMessage['timestamp'] = DateTime.now().toUtc().toIso8601String();
        _log(
            '✅ Usando timestamp local optimizado - sincronización en background');

        // Sincronizar timestamp del servidor en background (sin bloquear UI)
        _syncMessageTimestampInBackground(generatedMessageId);
      } catch (e) {
        debugPrint("❌ Error al guardar mensaje con el nuevo servicio: $e");
      }
    } else if (!_isOnline) {
      // Modo offline: solo timestamp local
      newMessage['timestamp'] = DateTime.now().toUtc().toIso8601String();
      _log('📴 Modo offline: mensaje solo en caché local');
    }

    // Fallback: si no se pudo obtener timestamp del servidor, usar timestamp local como último recurso
    if (newMessage['timestamp'] == null) {
      newMessage['timestamp'] = DateTime.now().toUtc().toIso8601String();
      _log(
          '⚠️ Usando timestamp local (fallback) - el dispositivo podría tener hora incorrecta');
    }
    // Usar el ID generado o el original para el índice de idiomas
    final effectiveId = generatedMessageId ?? messageId;
    if (effectiveId != null && language != null) {
      _messageLanguages[effectiveId] = language;
    }

    if (mounted) {
      // Hacemos un único setState para modificar la lista de mensajes.
      setState(() {
        if (insertAtIndex != null) {
          messages.insert(insertAtIndex, newMessage);
        } else {
          messages.add(newMessage);
        }
      });

      // Persistimos de forma agrupada (debounced) para evitar IO excesivo.
      _schedulePersistMessages();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!autoScroll || !_scrollController.hasClients) return;

      try {
        // Si el usuario ya está lejos del final, hacemos un jump para evitar la animación costosa.
        final offset = _scrollController.offset;
        // Si la diferencia es pequeña, animamos; si es grande, saltamos.
        if ((offset - 0.0).abs() < 200) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(0.0);
        }
      } catch (e) {
        // Ignorar errores de scroll si la posición cambia durante el frame
      }
    });

    return generatedMessageId;
  }

  void _handleFeedback(String messageId, bool wasUseful) {
    if (!mounted) return;

    setState(() {
      final messageIndex = messages.indexWhere((m) => m['id'] == messageId);

      if (messageIndex != -1) {
        final message = messages[messageIndex];
        if (message['extras'] is Map) {
          // 1. Ocultamos los botones como antes
          (message['extras'] as Map)['showFeedback'] = false;
          // 2. ¡NUEVO! Añadimos el mensaje de agradecimiento al mismo objeto
          (message['extras'] as Map)['feedbackMessage'] =
              ChatbotStrings.get('feedback.thanks', _currentLanguage);
        }
      }
    });

    // Guardamos la calificación en Firestore como antes
    if (_currentConversationId != null) {
      _firestoreConnection.saveMessageRating(
        conversationId: _currentConversationId!,
        messageId: messageId,
        helpful: wasUseful,
      );
    }
  }

  // ===========================================================================
  // PROCESAMIENTO DE MENSAJES Y IA
  // ===========================================================================
  void handleSendMessage(String text) async {
    // Iniciar medición de tiempo de respuesta
    final stopwatch = Stopwatch()..start();

    // Detectar idioma
    try {
      _currentLanguage = await _languageService.detectLanguage(text);
      // Verificar si es emergencia
      if (_emergencyService.detectEmergency(text, _currentLanguage)) {
        await _activateEmergencyMode(text);
        return;
      }
    } catch (e) {
      _currentLanguage = 'es'; // Fallback a español
    }

    setState(() => messages.removeWhere((m) => m['type'] == 'faq_options'));

    addMessage(
      sender: "user",
      text: text,
      language: _currentLanguage,
    );

    setState(() {
      _isTyping = true;
    });
    _typingController.repeat();

    try {
      // MODO OFFLINE: Buscar en caché local si no hay conexión
      if (!_isOnline) {
        _log('📴 Modo offline detectado - buscando en FAQs locales');
        
        // 1. Primero intentar con caché esencial optimizado (20 FAQs)
        final cachedFaqResults = _offlineFaqCache.searchInCache(text, _currentLanguage);
        
        if (cachedFaqResults.isNotEmpty) {
          _log('✅ Respuesta encontrada en caché esencial (${cachedFaqResults.length} resultados)');
          final bestMatch = cachedFaqResults.first;
          final answer = bestMatch.getAnswer(_currentLanguage);
          
          await addMessage(
            sender: 'bot',
            text: answer,
            source: 'cache_offline',
            link: bestMatch.link,
            language: _currentLanguage,
            extras: {'showFeedback': true},
          );
          
          stopwatch.stop();
          _log('⏱️ TIEMPO DE RESPUESTA [Cache Esencial]: ${stopwatch.elapsedMilliseconds}ms');
          
          setState(() {
            _isTyping = false;
          });
          _typingController.stop();
          _typingController.reset();
          return;
        }
        
        // 2. Si no hay resultado en caché esencial, buscar en TODAS las FAQs (_allLoadedFaqs)
        _log('⚠️ No encontrado en caché esencial - buscando en ${_allLoadedFaqs.length} FAQs completas');
        
        // Buscar manualmente en _allLoadedFaqs
        final queryLower = text.toLowerCase();
        final allFaqResults = <MapEntry<Faq, double>>[];
        
        for (final faq in _allLoadedFaqs) {
          double score = 0.0;
          
          final question = faq.getQuestion(_currentLanguage).toLowerCase();
          final answer = faq.getAnswer(_currentLanguage).toLowerCase();
          final tags = faq.tags.join(' ').toLowerCase();
          
          // Scoring
          if (question.contains(queryLower)) score += 10.0;
          if (answer.contains(queryLower)) score += 5.0;
          if (tags.contains(queryLower)) score += 7.0;
          
          // Por palabras individuales
          final queryWords = queryLower.split(' ');
          for (final word in queryWords) {
            if (word.length <= 2) continue;
            
            if (question.contains(word)) score += 2.0;
            if (answer.contains(word)) score += 1.0;
            if (tags.contains(word)) score += 1.5;
          }
          
          if (score > 0) {
            allFaqResults.add(MapEntry(faq, score));
          }
        }
        
        if (allFaqResults.isNotEmpty) {
          // Ordenar y tomar el mejor resultado
          allFaqResults.sort((a, b) => b.value.compareTo(a.value));
          final bestMatch = allFaqResults.first.key;
          final answer = bestMatch.getAnswer(_currentLanguage);
          
          _log('✅ Respuesta encontrada en FAQs completas (score: ${allFaqResults.first.value})');
          
          await addMessage(
            sender: 'bot',
            text: answer,
            source: 'offline_all_faqs',
            link: bestMatch.link,
            language: _currentLanguage,
            extras: {'showFeedback': true},
          );
          
          stopwatch.stop();
          _log('⏱️ TIEMPO DE RESPUESTA [FAQs Completas Offline]: ${stopwatch.elapsedMilliseconds}ms');
          
          setState(() {
            _isTyping = false;
          });
          _typingController.stop();
          _typingController.reset();
          return;
        } else {
          // No se encontró respuesta en ninguna FAQ local
          final noConnectionMessage = ChatbotStrings.get('fallback.no_connection', _currentLanguage);
          await addMessage(
            sender: 'bot',
            text: noConnectionMessage,
            source: 'system',
            language: _currentLanguage,
          );
          
          setState(() {
            _isTyping = false;
          });
          _typingController.stop();
          _typingController.reset();
          return;
        }
      }
      
      // PLAN A: Intentar obtener una respuesta de la IA (Lógica online)
      if (kDebugMode) {
        _log("🤖 BUSCANDO FAQs PARA: '$text'");
      }

      // OPTIMIZACIÓN: Ejecutar búsqueda de FAQs y preparación en paralelo
      final cleanText =
          text.toLowerCase().trim().replaceAll(RegExp(r'[?¿]'), '');

      List<Faq> contextFaqs = [];
      // Preparar historial de conversación (se usa más adelante)
      final conversationHistory =
          _openAIService.formatMessagesForOpenAI(messages);

      if (!_contextualTriggers.contains(cleanText)) {
        // Búsqueda de FAQs optimizada con caché
        contextFaqs = await _faqService.findContextFaqs(text);
        if (kDebugMode) {
          _log("� FAQs encontradas: ${contextFaqs.length}");
        }
      }

      // **OBTENER LA URL REAL ANTES DE LLAMAR A OPENAI**
      String? realUrl;
      if (contextFaqs.isNotEmpty) {
        realUrl = contextFaqs.first.link;
      }
      final openAIResponse = await _openAIService.generateRAGResponse(
        userMessage: text,
        contextFaqs: contextFaqs,
        conversationHistory: conversationHistory,
        language: _currentLanguage, // **PASAR EL IDIOMA A OPENAI**
      );

      if (mounted) {
        if (openAIResponse.success) {
          final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();

          // **PRIORIDAD: URL REAL > URL EXTRAÍDA**
          String? finalUrl = realUrl;
          if (finalUrl == null || finalUrl.isEmpty) {
            finalUrl = openAIResponse.extractedUrls.isNotEmpty
                ? openAIResponse.extractedUrls.first
                : null;
          }
          // Limpiar URLs del mensaje si hay una URL final
          String displayMessage = openAIResponse.message;
          if (finalUrl != null && finalUrl.isNotEmpty) {
            // Eliminar links y URLs de forma rápida
            displayMessage = displayMessage
                .replaceAll(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), '')
                .replaceAll(RegExp(r'https?:\/\/[\S]+|www\.[\S]+'), '')
                .replaceAll(RegExp(r'\s{2,}'), ' ')
                .trim();
          }

          addMessage(
            sender: "bot",
            text: displayMessage,
            messageId: aiMessageId,
            source: 'openai_rag',
            link: finalUrl,
            language: _currentLanguage,
            extras: {'showFeedback': true},
          );

          // OPTIMIZACIÓN: Guardar en caché para futuras consultas idénticas
          _responseCacheService.cacheResponse(
            query: text,
            response: displayMessage,
            language: _currentLanguage,
            link: finalUrl,
          );

          // Detener y loggear tiempo de respuesta
          stopwatch.stop();
          if (kDebugMode) {
            final responseTimeMs = stopwatch.elapsedMilliseconds;
            final responseType = contextFaqs.isNotEmpty ? 'FAQ' : 'AI';
            _log(
                '⏱️ [$responseType]: ${(responseTimeMs / 1000).toStringAsFixed(1)}s');
          }
        } else {
          // La IA devolvió un error controlado, aquí también podríamos activar el fallback
          throw Exception(openAIResponse.message);
        }
      }
    } catch (e) {
      // PLAN B: La conexión falló, buscar respuesta en la base de datos local (Lógica offline)
      _log(
          "🔴 Falló la conexión con la IA, iniciando fallback offline. Error: $e");

      // Reutilizamos el servicio de FAQs para buscar en la lista local (_allLoadedFaqs)
      final List<Faq> localResults = await _faqService.findContextFaqs(text);

      if (mounted) {
        if (localResults.isNotEmpty) {
          // ¡Éxito! Encontramos una respuesta local.
          final bestMatch =
              localResults.first; // Tomamos el resultado más relevante

          // **USAR LA RESPUESTA EN EL IDIOMA CORRECTO**
          final offlinePrefix =
              ChatbotStrings.get('fallback.offline_prefix', _currentLanguage);
          String selectedAnswer;
          if (_currentLanguage == 'en' && bestMatch.answerEn.isNotEmpty) {
            selectedAnswer = bestMatch.answerEn;
          } else if (_currentLanguage == 'pt' &&
              bestMatch.answerPt.isNotEmpty) {
            selectedAnswer = bestMatch.answerPt;
          } else {
            selectedAnswer = bestMatch.answer;
          }

          final offlineAnswer = '$offlinePrefix\n\n$selectedAnswer';
          final offlineMessageId =
              DateTime.now().millisecondsSinceEpoch.toString();
          addMessage(
            sender: "bot",
            text: offlineAnswer,
            messageId: offlineMessageId,
            source:
                'offline_faq', // Un nuevo source para identificar la respuesta
            link: bestMatch.link, // ← URL real de la FAQ
            language: _currentLanguage,
            extras: {
              'showFeedback': true
            }, // También podemos mostrar el link si existe
          );

          // Detener y loggear tiempo de respuesta offline
          stopwatch.stop();
          final responseTimeMs = stopwatch.elapsedMilliseconds;
          _log(
              '⏱️ TIEMPO DE RESPUESTA [FAQ Offline]: ${responseTimeMs}ms (${(responseTimeMs / 1000).toStringAsFixed(2)}s)');
        } else {
          // No se encontró respuesta local. Intentar un último reintento a la IA
          try {
            _log(
                '🔁 Reintentando consulta a la IA sin contexto como último recurso...');
            final retryResponse = await _openAIService.sendSimpleMessage(text);
            if (mounted) {
              if (retryResponse.success) {
                final aiMessageId =
                    DateTime.now().millisecondsSinceEpoch.toString();
                addMessage(
                  sender: "bot",
                  text: retryResponse.message,
                  messageId: aiMessageId,
                  source: 'openai_fallback',
                  language: _currentLanguage,
                  extras: {'showFeedback': true},
                );

                // Detener y loggear tiempo de respuesta del reintento
                stopwatch.stop();
                final responseTimeMs = stopwatch.elapsedMilliseconds;
                _log(
                    '⏱️ TIEMPO DE RESPUESTA [Complex AI - Retry]: ${responseTimeMs}ms (${(responseTimeMs / 1000).toStringAsFixed(2)}s)');
              } else {
                // Si OpenAI respondió con error, mostrar mensaje de error amigable
                final errorMessage = ChatbotStrings.get(
                    'fallback.error_message', _currentLanguage);
                addMessage(
                  sender: "bot",
                  text: errorMessage,
                  source: 'error',
                  language: _currentLanguage,
                );
              }
            }
          } catch (e2) {
            _log('❌ Reintento a la IA falló: $e2');
            final errorMessage =
                ChatbotStrings.get('fallback.error_message', _currentLanguage);
            addMessage(
              sender: "bot",
              text: errorMessage,
              source: 'error',
              language: _currentLanguage,
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _typingController.stop();
      }
    }
  }

  // ===========================================================================
  // GESTIÓN DE EMERGENCIAS
  // ===========================================================================
  Future<void> _activateEmergencyMode(String userMessage) async {
    await addMessage(
      sender: "user",
      text: userMessage,
      language: _currentLanguage,
    );
    final relevantContacts =
        _emergencyService.getRelevantContacts(userMessage, _currentLanguage);

    setState(() {
      _currentEmergencyContacts = relevantContacts;
    });

    /// Mensaje automático del bot
    final emergencyMessage =
        ChatbotStrings.get('emergency.alert_message', _currentLanguage);

    await addMessage(
      sender: "bot",
      text: emergencyMessage,
      type: "emergency",
      language: _currentLanguage,
    );

    // Mostrar el modal de emergencia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showEmergencyModal();
    });
  }

  void _deactivateEmergencyMode() {
    setState(() {
      _currentEmergencyContacts = [];
    });
  }

  Future<void> _makeEmergencyCall(String phoneNumber) async {
    try {
      await _emergencyService.makeCall(phoneNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ChatbotStrings.get('emergency.call_failed', _currentLanguage,
                  params: {'phone': phoneNumber}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Agregar este método para mostrar el modal de emergencia
  void _showEmergencyModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54, // Fondo semitransparente
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return _buildEmergencyModal();
      },
    );
  }

  Future<void> _loadEmergencyContacts() async {
    await _emergencyService.loadEmergencyContacts();
  }

  // Reemplazar el método _buildEmergencyCard por este:
  Widget _buildEmergencyModal() {
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.8, // 80% de la altura
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBackground
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmergencyHeader(),
                const SizedBox(height: 16),
                _buildEmergencyDescription(),
                const SizedBox(height: 16),
                Expanded(
                    //scroll en caso de muchos numeros
                    child: SingleChildScrollView(
                        child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildEmergencyContacts(),
                ))),
                const SizedBox(height: 20),
                _buildCloseButton(),
              ],
            ),
          ),
        ));
  }

  // Header de emergencia
  Widget _buildEmergencyHeader() {
    return Center(
      child: Text(
        ChatbotStrings.get('emergency.modal.title', _currentLanguage),
        style: TextStyle(
          color: Colors.red[700],
          fontSize: 28,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        textAlign: TextAlign.center, // Asegura que el texto esté centrado
      ),
    );
  }

  // Descripcion de emergencia
  Widget _buildEmergencyDescription() {
    return Center(
      child: Text(
        ChatbotStrings.get('emergency.modal.description', _currentLanguage),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
        textAlign: TextAlign.center, // Asegura que el texto esté centrado
      ),
    );
  }

  // Lista de contactos de emergencia
  List<Widget> _buildEmergencyContacts() {
    return _currentEmergencyContacts.map((contact) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        elevation: 2,
        child: ListTile(
          title: Text(
            contact.getName(_currentLanguage),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          subtitle: Text(
            '${contact.phone} • ${contact.getType(_currentLanguage)}',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
          trailing: FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar modal
              _makeEmergencyCall(contact.phone);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[100],
              foregroundColor: Colors.red[900],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 4),
                Text(
                  ChatbotStrings.get(
                      'emergency.modal.call_button', _currentLanguage),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // Botón de cierre
  Widget _buildCloseButton() {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deactivateEmergencyMode();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              ChatbotStrings.get(
                  'emergency.modal.close_button', _currentLanguage),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // GESTIÓN DE FAQs
  // ===========================================================================
  Future<void> _loadAllFaqs() async {
    // Si está offline, cargar solo FAQs del caché
    if (!_isOnline) {
      final cachedFaqs = _offlineFaqCache.getAllCachedFaqs();
      _log('📴 Modo offline: ${cachedFaqs.length} FAQs esenciales disponibles desde caché');
      if (mounted) {
        setState(() {
          _allLoadedFaqs = cachedFaqs;
        });
      }
      return;
    }
    
    // Modo online: cargar todas las FAQs desde Firestore
    final faqs = await _faqService.getAllFaqs();
    // Esta línea nos dirá si la carga de datos fue exitosa
    _log('FAQs cargadas desde Firestore: ${faqs.length} preguntas');
    if (mounted) {
      setState(() {
        _allLoadedFaqs = faqs;
      });
    }
  }

  /// Actualizar caché de FAQs al recuperar conexión
  Future<void> _updateFaqCache() async {
    if (!_isOnline) {
      _log('⚠️ No se puede actualizar caché: sin conexión');
      return;
    }
    
    try {
      _log('🔄 Actualizando caché de FAQs desde Firestore...');
      
      // 1. Recargar todas las FAQs desde Firestore
      final allFaqs = await _faqService.getAllFaqs();
      
      if (mounted) {
        setState(() {
          _allLoadedFaqs = allFaqs;
        });
      }
      
      _log('✅ _allLoadedFaqs actualizado: ${allFaqs.length} FAQs');
      
      // 2. Actualizar caché offline con las 20 FAQs esenciales
      await _offlineFaqCache.saveEssentialFaqsToCache(allFaqs);
      
      _log('✅ Caché offline actualizado: ${_offlineFaqCache.cachedFaqs.length} FAQs esenciales');
      
    } catch (e) {
      _log('❌ Error actualizando caché de FAQs: $e');
      _reportErrorToCrashlytics(e, StackTrace.current, context: {
        'where': 'updateFaqCache',
        'isOnline': _isOnline.toString(),
      });
    }
  }

  void _showFrequentlyAskedQuestions() {
    _log('Se presionó el botón de Preguntas Frecuentes.');
    _log('🌐 Idioma actual para FAQs: $_currentLanguage');
    _log('📊 Estado de conexión: ${_isOnline ? "ONLINE" : "OFFLINE"}');

    final faqBloc = context.read<FaqBloc>();
    final currentState = faqBloc.state;

    if (!currentState.showFaqs || currentState.currentFaqs.isEmpty) {
      List<String> randomFaqs = [];
      
      // Si está offline, obtener FAQs del caché
      if (!_isOnline) {
        final cachedFaqs = _offlineFaqCache.getAllCachedFaqs();
        _log('📴 FAQs disponibles en caché: ${cachedFaqs.length}');
        
        if (cachedFaqs.isEmpty) {
          _log('⚠️ No hay FAQs en caché offline');
          // Mostrar mensaje al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay preguntas frecuentes disponibles offline'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        // Seleccionar 3 FAQs aleatorias del caché
        final shuffled = List<Faq>.from(cachedFaqs)..shuffle();
        randomFaqs = shuffled
            .take(3)
            .map((faq) => faq.getQuestion(_currentLanguage))
            .toList();
        
        _log('📴 Mostrando ${randomFaqs.length} FAQs desde caché offline:');
        for (int i = 0; i < randomFaqs.length; i++) {
          _log('  ${i + 1}. ${randomFaqs[i]}');
        }
      } else {
        // Modo online: usar servicio normal
        randomFaqs = _faqService.getRandomFaqsByLanguage(_currentLanguage, count: 3);
        _log('📡 Mostrando ${randomFaqs.length} FAQs desde Firestore');
      }

      if (randomFaqs.isEmpty) {
        _log('❌ No se pudieron obtener FAQs');
        return;
      }

      // Encontrar la posición del mensaje de bienvenida
      final welcomeIndex = messages.indexWhere((m) => m['type'] == 'welcome_message');
      _log('📍 Posición del mensaje de bienvenida: $welcomeIndex');

      //Enviar evento a FAQS
      faqBloc.add(ToggleFaqsEvent(newFaqs: randomFaqs));

      // Texto dinámico según idioma para la introducción de FAQs
      final introText = ChatbotStrings.get('faq.intro', _currentLanguage);

      if (welcomeIndex != -1) {
        _log('✅ Insertando mensaje de FAQs con ${randomFaqs.length} opciones después de bienvenida');
        
        // Insertar las FAQs justo después del mensaje de bienvenida
        addMessage(
          sender: "bot",
          text: introText,
          type: "faq_options",
          options: randomFaqs,
          insertAtIndex: welcomeIndex + 1, // Insertar después del welcome
          language: _currentLanguage,
          autoScroll: false,
        );
      } else {
        // FALLBACK: Si no hay mensaje de bienvenida, insertar al inicio
        _log('⚠️ No se encontró mensaje de bienvenida, insertando FAQs al inicio');
        addMessage(
          sender: "bot",
          text: introText,
          type: "faq_options",
          options: randomFaqs,
          insertAtIndex: 0, // Insertar al inicio
          language: _currentLanguage,
          autoScroll: false,
        );
      }
    } else {
      //Ocultar faqs
      faqBloc.add(ToggleFaqsEvent());

      // Eliminar FAQs existentes
      setState(() {
        messages.removeWhere((message) => message['type'] == 'faq_options');
      });
    }
  }

  void _onFaqSelected(String selectedFaq) {
    _log('Se seleccionó la FAQ y se enviará este texto: "$selectedFaq"');
    //1ro oculta faqs actuales
    final faqBloc = context.read<FaqBloc>();
    faqBloc.add(ToggleFaqsEvent());

    // 2. Eliminar el mensaje de FAQs de la interfaz
    setState(() {
      messages.removeWhere((message) => message['type'] == 'faq_options');
    });

    handleSendMessage(selectedFaq);
  }

  // ===========================================================================
  // MÉTODOS DE UI AUXILIARES
  // ===========================================================================
  /// Widget para mostrar indicador de carga durante la inicialización
  Widget _buildLoadingIndicator(bool isDarkMode) {
    return Container(
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ChatbotStrings.get('loading.conversation', _currentLanguage),
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ChatbotStrings.get('loading.firestore', _currentLanguage),
            style: TextStyle(
              color: isDarkMode ? Colors.white38 : Colors.black38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _launchWhatsApp() async {
    const phoneNumber = "14155238886";
    const message = "Hola, necesito ayuda de un asesor.";
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return; // <-- Añade esta línea de seguridad
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ChatbotStrings.get('whatsapp.error', _currentLanguage)),
        ),
      );
    }
  }

  // ===========================================================================
  // CONSTRUCCIÓN DE LA UI
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
      //
      // --- CAMBIO 1: Envolvemos todo en AnnotatedRegion ---
      //
      return AnnotatedRegion<SystemUiOverlayStyle>(
        // Le damos el estilo dinámico a la barra de estado
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              state.isDarkMode ? Brightness.light : Brightness.dark,
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          //
          // --- CAMBIO 2: Añadimos 'top: false' al SafeArea ---
          //
          child: SafeArea(
            top: false, // Evita un doble espaciado en la parte de arriba
            child: Scaffold(
              backgroundColor:
                  state.isDarkMode ? AppColors.darkBackground : Colors.grey[50],
              resizeToAvoidBottomInset: true,
              floatingActionButton: const Column(
                mainAxisSize: MainAxisSize.min,
              ),
              body: Column(
                children: [
                  ChatbotHeader(
                    onClearHistory: _clearChatHistory,
                    onContactWhatsApp: _launchWhatsApp,
                  ),
                  // Indicador de conectividad
                  ConnectivityIndicator(isOnline: _isOnline),
                  // Test buttons removed after verification
                  Expanded(
                    child: _isLoadingConversation
                        ? _buildLoadingIndicator(state.isDarkMode)
                        : _typingAnimation != null
                            ? ChatbotBody(
                                isDarkMode: state.isDarkMode,
                                messages: messages,
                                scrollController: _scrollController,
                                isTyping: _isTyping,
                                typingAnimation: _typingAnimation!,
                                onFeedback: _handleFeedback,
                                onSendMessage: handleSendMessage,
                                onShowFrequentlyAskedQuestions:
                                    _showFrequentlyAskedQuestions,
                                onFaqSelected: _onFaqSelected,
                                emergencyContacts:
                                    _currentEmergencyContacts.map((contact) {
                                  return {
                                    'name': contact.name,
                                    'phone': contact.phone,
                                    'type': contact.type,
                                  };
                                }).toList(),
                                onEmergencyCall: _makeEmergencyCall,
                                onCloseEmergency: _deactivateEmergencyMode,
                              )
                            : Container(),
                  ),
                  ChatbotFooter(
                    isDarkMode: state.isDarkMode,
                    onSendMessage: handleSendMessage,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
