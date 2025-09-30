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
