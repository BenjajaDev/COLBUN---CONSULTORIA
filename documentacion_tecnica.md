# 🤖 Documentación Técnica - Chatbot Colbún

## 🎯 Descripción General
Chatbot inteligente para la Municipalidad de Colbún con soporte multidioma español/inglés, integración OpenAI y Firebase.

---

## 🔍 UBICACIÓN DE FUNCIONALIDADES PRINCIPALES

### 1. 🌐 DETECCIÓN Y MANEJO DE IDIOMAS

#### **Detección de Idioma**
- **Archivo:** `services/language_service.dart`
- **Método Principal:** `detectLanguage(String text)`
- **Líneas:** 12-35
- **Propósito:** Detecta si el texto es español o inglés usando Google ML Kit

#### **Textos Dinámicos (ES/EN)**
- **Chat Screen:** `chatbot_screen.dart` (líneas 150-154, 264-268, 290-294)
- **UI Components:** `chatbot_body.dart` (líneas 172, 193-195, 232)
- **IA Service:** `openai_service.dart` (líneas 156-159, 210-213)

### 2. 🤖 SISTEMA DE IA (OpenAI + RAG)

#### **Búsqueda Inteligente**
- **Archivo:** `services/openai_service.dart`
- **Método Principal:** `generateRAGResponse()`
- **Líneas:** 106-166
- **Flujo:** 
  1. Recibe contexto de FAQs
  2. Formatea según idioma
  3. Construye prompt con contexto
  4. Llama a API OpenAI

#### **Integración en Chatbot**
- **Archivo:** `chatbot_screen.dart`
- **Método:** `handleSendMessage()` 
- **Líneas:** 175-210
- **Flujo:** Detección idioma → Búsqueda FAQs → Llamada OpenAI → Respuesta

### 3. 📚 SISTEMA DE FAQs Y BÚSQUEDA

#### **Base de Datos de FAQs**
- **Archivo:** `services/firestore_faq_service.dart`
- **Modelo:** Clase `Faq` (líneas 8-40)
- **Carga:** `loadFaqsAndCalculateScores()` (líneas 54-67)

#### **Búsqueda Semántica (TF-IDF)**
- **Archivo:** `services/firestore_faq_service.dart`
- **Método:** `findContextFaqs()` (líneas 95-149)
- **Algoritmo:** TF-IDF con sinónimos y stopwords

#### **Vocabulario y Sinónimos**
- **Sinónimos:** Líneas 206-298 (Map `_synonyms`)
- **Stopwords:** Líneas 300-369 (Set `_excludeWords`)
- **Generación Keywords:** `_generateKeywordsFromText()` (líneas 178-199)

### 4. 🔄 CONVERSIÓN MULTIDIOMA FAQs

#### **Sistema Bilingüe**
- **Archivo:** `services/firestore_faq_service.dart`
- **Métodos:** 
  - `getQuestion(String language)` - Línea 33
  - `getAnswer(String language)` - Línea 38
- **Campos:** `questionEn`, `answerEn` en modelo Faq

### 5. 💾 PERSISTENCIA Y BASE DE DATOS

#### **Firestore Integration**
- **Archivo:** `services/firestore_conversations.dart`
- **Conversaciones:** `createConversation()`, `addMessageToConversation()`
- **Ratings:** `saveMessageRating()`

#### **Estructura de Datos**
```dart
// Mensajes en la UI
{
  "id": "unique_id",
  "sender": "user|bot", 
  "text": "mensaje",
  "type": "text|faq_options|welcome_message",
  "language": "es|en",
  "link": "url_opcional",
  "extras": {"showFeedback": bool}
}