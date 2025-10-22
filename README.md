# COLBUN - CONSULTORIA

Aplicación Flutter para la Ilustre Municipalidad de Colbún con chatbot AI integrado.

En este repositorio están albergados los equipos PCIS1 (Chatbot), PCIS2 Y PCIS3 (Rutas).

## 🚀 Configuración del Proyecto

### Prerrequisitos
- Flutter SDK (versión >=3.4.0)
- Dart SDK
- Firebase configurado
- API Key de OpenAI

### 🔧 Configuración de Variables de Entorno

<<<<<<< HEAD
**IMPORTANTE**: Este proyecto utiliza variables de entorno para proteger información sensible como las API keys.

#### Paso 1: Crear archivo de configuración
1. Copia el archivo `.env.example` y renómbralo a `.env`
2. El archivo `.env` debe quedar en la raíz del proyecto

#### Paso 2: Configurar tu API Key de OpenAI
1. Obtén tu API Key en: https://platform.openai.com/api-keys
2. Edita el archivo `.env` y reemplaza `tu-api-key-aqui` con tu API key real:

```env
OPENAI_API_KEY=sk-proj-tu-api-key-real-aqui
```

#### Paso 3: Verificar seguridad
- ✅ El archivo `.env` está incluido en `.gitignore` y NO se subirá a Git
- ✅ Nunca subas tu API key al repositorio
- ✅ Cada desarrollador debe tener su propia copia local del archivo `.env`

### 📦 Instalación

```bash
# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run
```

### 🛡️ Seguridad

- **Archivo `.env`**: Contiene información sensible, nunca debe subirse a Git
- **Archivo `.env.example`**: Plantilla sin información sensible, SÍ se sube a Git
- Las API keys están protegidas y solo se cargan en tiempo de ejecución

### 🤖 Chatbot AI

El chatbot está especializado en la Municipalidad de Colbún y tiene limitaciones estrictas para mantener el contexto apropiado:

- Solo responde consultas sobre Colbún y su comuna
- Información turística, servicios municipales, eventos locales
- Fuentes oficiales de visitacolbun.cl
=======
For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
<<<<<<< HEAD
>>>>>>> main
=======

# COLBUN---CONSULTORIA
En este repositorio están albergados los equipos PCIS1 (Chatbot), PCIS2 Y PCIS3 (Rutas).
>>>>>>> a1e5ef9c7910876421df87eae1962758e0bb50fe
>>>>>>> d097eb0d456fe583b90a20610951b8087f4da104


 Configuración de Firebase - Nueva Instalación

## Prerrequisitos
- Flutter SDK instalado
- Node.js y npm instalados
- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

## Paso 1: Crear Proyecto Firebase

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto
3. Habilitar servicios:
   - **Firestore Database** (modo Native)
   - **Authentication** (Email/Password)
   - **Crashlytics**
   - **Cloud Functions** (si se requiere)

## Paso 2: Registrar Apps

### Android:
1. En Firebase Console > Agregar app Android
2. Package name: `com.example.consultoria_chat_bot`
3. Descargar `google-services.json`
4. Colocar en: `android/app/google-services.json`

### iOS (opcional):
1. En Firebase Console > Agregar app iOS
2. Bundle ID: verificar en `ios/Runner/Info.plist`
3. Descargar `GoogleService-Info.plist`
4. Colocar en: `ios/Runner/GoogleService-Info.plist`

## Paso 3: Configurar FlutterFire

```bash
# Iniciar sesión en Firebase
firebase login

# Configurar el proyecto
flutterfire configure --project=<TU_PROJECT_ID>

# Esto generará automáticamente:
# - lib/firebase_options.dart
# - Actualizará .firebaserc
```

## Paso 4: Configurar Reglas de Firestore

En Firebase Console > Firestore > Reglas, usar:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura/escritura solo a usuarios autenticados
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Paso 5: Probar la Configuración

```bash
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

- Si `flutterfire` no se encuentra, añadir al PATH:
  - Windows: `%USERPROFILE%\AppData\Local\Pub\Cache\bin`
  - Mac/Linux: `$HOME/.pub-cache/bin`

- Si hay errores de Firebase, verificar:
  - `google-services.json` en la ubicación correcta
  - Package name coincide en Firebase Console y `build.gradle`

# Configuración de OpenAI

## Paso 1: Obtener API Key

1. Crear cuenta en [OpenAI Platform](https://platform.openai.com/)
2. Ir a [API Keys](https://platform.openai.com/api-keys)
3. Crear nueva Secret Key
4. **IMPORTANTE**: Copiar y guardar la key (solo se muestra una vez)

## Paso 2: Configurar en el Proyecto

1. Copiar el archivo de ejemplo:
```bash
cp .env.example .env
```

2. Editar `.env` y agregar tu API key:
```env
OPENAI_API_KEY=sk-proj-XXXXXXXXXXXXXXXXX
```

3. **NUNCA** subir el archivo `.env` a Git

## Paso 3: Verificar Configuración

El archivo `.env` debe estar en la raíz del proyecto:
```
COLBUN---CONSULTORIA/
├── .env          ← Aquí (no versionado)
├── .env.example  ← Template
├── lib/
├── android/
└── ...
```

## Costos

- Revisar [pricing de OpenAI](https://openai.com/api/pricing/)
- Configurar límites de uso en OpenAI Dashboard
- Monitorear uso en: https://platform.openai.com/usage

## Seguridad

- ✅ Usar `.env` local (desarrollo)
- ✅ Variables de entorno en producción
- ❌ NUNCA hardcodear la key en el código
- ❌ NUNCA subir `.env` a Git