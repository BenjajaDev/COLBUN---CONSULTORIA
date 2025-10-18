class ChatbotStrings {
  static const String _defaultLanguage = 'es';
  static String _normalizeLanguage(String? language) {
    switch (language?.toLowerCase()) {
      case 'en':
        return 'en';
      case 'pt':
        return 'pt';
      case 'es':
      default:
        return _defaultLanguage;
    }
  }

  static const Map<String, Map<String, String>> _strings = {
    'welcome.message': {
      'es': '¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?',
      'en': 'Hello! I am the virtual assistant of Colbún. How can I help you?',
      'pt': 'Olá! Eu sou o assistente virtual de Colbún. Como posso ajudá-lo?'
    },
    'faq.intro': {
      'es': 'Aquí tienes algunas preguntas frecuentes:',
      'en': 'Here are some frequently asked questions:',
      'pt': 'Aqui estão algumas perguntas frequentes:'
    },
    'faq.button_label': {
      'es': 'Preguntas frecuentes',
      'en': 'Frequently asked questions',
      'pt': 'Perguntas frequentes'
    },
    'link.source_label': {
      'es': 'Fuente',
      'en': 'Source',
      'pt': 'Fonte'
    },
    'feedback.yes': {
      'es': 'Sí, fue útil',
      'en': 'Yes, helpful',
      'pt': 'Sim, útil'
    },
    'feedback.no': {
      'es': 'No, no fue útil',
      'en': 'No, not helpful',
      'pt': 'Não, não foi útil'
    },
    'feedback.thanks': {
      'es': '¡Gracias por tu feedback!',
      'en': 'Thank you for your feedback!',
      'pt': 'Obrigado pelo seu feedback!'
    },
    'emergency.alert_message': {
      'es': 'He detectado una situación de emergencia. Estoy mostrando contactos de emergencia que pueden ayudarte.',
      'en': "I've detected an emergency situation. I'm showing emergency contacts that can help you.",
      'pt': 'Detectei uma situação de emergência. Estou mostrando contatos de emergência que podem ajudá-lo.'
    },
    'emergency.modal.title': {
      'es': 'EMERGENCIA DETECTADA',
      'en': 'EMERGENCY DETECTED',
      'pt': 'EMERGÊNCIA DETECTADA'
    },
    'emergency.modal.description': {
      'es': 'He detectado una situación de emergencia. Aquí tienes contactos que pueden ayudarte inmediatamente.',
      'en': "I've detected an emergency situation. Here are contacts that can help you immediately.",
      'pt': 'Detectei uma situação de emergência. Aqui estão contatos que podem ajudá-lo imediatamente.'
    },
    'emergency.modal.call_button': {
      'es': 'Llamar',
      'en': 'Call',
      'pt': 'Ligar'
    },
    'emergency.modal.close_button': {
      'es': 'Cerrar',
      'en': 'Close',
      'pt': 'Fechar'
    },
    'emergency.call_failed': {
      'es': 'No se pudo realizar la llamada. Por favor marca {phone} manualmente.',
      'en': 'Could not make the call. Please dial {phone} manually.',
      'pt': 'Não foi possível fazer a chamada. Por favor, disque {phone} manualmente.'
    },
    'fallback.offline_prefix': {
      'es': 'No tengo conexión en este momento, pero encontré esto que podría ayudarte:',
      'en': "I don't have connection right now, but I found this that might help you:",
      'pt': 'No momento estou sem conexão, mas encontrei isto que pode ajudar você:'
    },
    'fallback.error_message': {
      'es': 'Lo siento, no pude conectarme y no encontré una respuesta local para tu pregunta. Por favor, revisa tu conexión a internet.',
      'en': "Sorry, I couldn't connect and didn't find a local answer for your question. Please check your internet connection.",
      'pt': 'Desculpe, não consegui conectar e não encontrei uma resposta local para a sua pergunta. Por favor, verifique sua conexão com a internet.'
    },
    'loading.conversation': {
      'es': 'Cargando conversación...',
      'en': 'Loading conversation...',
      'pt': 'Carregando conversa...'
    },
    'loading.firestore': {
      'es': 'Conectando con Firestore',
      'en': 'Connecting to Firestore',
      'pt': 'Conectando ao Firestore'
    },
    'whatsapp.error': {
      'es': 'No se pudo abrir WhatsApp.',
      'en': 'Could not open WhatsApp.',
      'pt': 'Não foi possível abrir o WhatsApp.'
    },
    'chat.hint': {
      'es': 'Escribe un mensaje',
      'en': 'Type a message',
      'pt': 'Digite uma mensagem'
    },
    'link.open_error': {
      'es': 'No se pudo abrir el enlace: {url}',
      'en': 'Could not open the link: {url}',
      'pt': 'Não foi possível abrir o link: {url}'
    }
  };

  static String get(String key, String? language, {Map<String, String>? params}) {
    final lang = _normalizeLanguage(language);
    final value = _strings[key]?[lang] ?? _strings[key]?[_defaultLanguage] ?? '';
    if (params == null || params.isEmpty) {
      return value;
    }
    return params.entries.fold<String>(
      value,
      (current, entry) => current.replaceAll('{${entry.key}}', entry.value),
    );
  }
}