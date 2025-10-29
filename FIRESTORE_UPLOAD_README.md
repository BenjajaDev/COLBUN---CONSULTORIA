# 📤 Guía de Carga de Datos a Firestore

Este documento explica cómo usar el script `upload-to-firestore.js` para cargar las colecciones de datos a Firestore.

## 📋 Requisitos Previos

### 1. Node.js y npm
Asegúrate de tener Node.js instalado:
```bash
node --version
npm --version
```

### 2. Instalar Firebase Admin SDK
```bash
npm install firebase-admin
```

### 3. Archivo de Credenciales de Firebase

Necesitas el archivo `serviceAccountKey.json` con las credenciales de tu proyecto Firebase:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Configuración del proyecto** (⚙️) → **Cuentas de servicio**
4. Haz clic en **Generar nueva clave privada**
5. Guarda el archivo como `serviceAccountKey.json` en la raíz del proyecto

### 4. Archivos de Datos

Asegúrate de tener estos archivos en la raíz del proyecto:
- ✅ `faqs_curadas.txt` (FAQs)
- ✅ `emergency_conctacts.txt` (Contactos de emergencia)
- ✅ `categories_v2.txt` (Categorías)
- ✅ `serviceAccountKey.json` (Credenciales de Firebase)

## 🚀 Uso del Script

### Opción 1: Cargar sin limpiar datos existentes
```bash
node upload-to-firestore.js
```

Esto **agregará o actualizará** los documentos sin eliminar los existentes.

### Opción 2: Limpiar y cargar (recomendado para primera vez)
```bash
node upload-to-firestore.js --clear
```

Esto **eliminará todos los documentos existentes** antes de cargar los nuevos.

### Ver ayuda
```bash
node upload-to-firestore.js --help
```

## 📊 Colecciones que se Crean

### 1. `faqs` (Preguntas Frecuentes)
Campos:
- `question` (string): Pregunta en español
- `questionEn` (string): Pregunta en inglés
- `questionPt` (string): Pregunta en portugués
- `answer` (string): Respuesta en español
- `answerEn` (string): Respuesta en inglés
- `answerPt` (string): Respuesta en portugués
- `category` (string): Categoría de la FAQ
- `priority` (number): Prioridad (1-10)
- `link` (string | null): URL de fuente
- `tags` (array): Palabras clave
- `createdAt` (timestamp): Fecha de creación
- `updatedAt` (timestamp): Fecha de actualización

### 2. `emergency_contacts` (Contactos de Emergencia)
Campos:
- `name` (string): Nombre en español
- `nameEn` (string): Nombre en inglés
- `namePt` (string): Nombre en portugués
- `phone` (string): Número de teléfono
- `type` (string): Tipo de servicio en español
- `typeEn` (string): Tipo de servicio en inglés
- `typePt` (string): Tipo de servicio en portugués
- `keyWords` (array): Palabras clave en español
- `keyWordsEn` (array): Palabras clave en inglés
- `keyWordsPt` (array): Palabras clave en portugués
- `available24h` (boolean): Disponible 24 horas
- `createdAt` (timestamp): Fecha de creación
- `updatedAt` (timestamp): Fecha de actualización

### 3. `categories` (Categorías)
Campos:
- `name` (string): Nombre de la categoría
- `icon` (string): Emoji o icono
- `priority` (number): Prioridad de visualización
- `description` (string): Descripción
- `createdAt` (timestamp): Fecha de creación
- `updatedAt` (timestamp): Fecha de actualización

## 📈 Ejemplo de Salida

```
🚀 SCRIPT DE CARGA A FIRESTORE
================================

📋 Verificando archivos necesarios...
✅ ./faqs_curadas.txt
✅ ./emergency_conctacts.txt
✅ ./categories_v2.txt
✅ ./serviceAccountKey.json

✅ Todos los archivos están presentes

📊 ESTADÍSTICAS DE DATOS A CARGAR:

📚 FAQs: 87 documentos
🚨 Contactos de Emergencia: 4 documentos
📂 Categorías: 9 documentos
📦 Total: 100 documentos

📊 FAQs por categoría:
   turismo: 25
   tramites: 18
   salud: 12
   ...

📂 Iniciando carga de Categorías...
✅ Total de Categorías cargadas: 9

🚨 Iniciando carga de Contactos de Emergencia...
✅ Total de Contactos de Emergencia cargados: 4

📚 Iniciando carga de FAQs...
✅ Total de FAQs cargadas: 87

════════════════════════════════════════════════════════
✅ CARGA COMPLETADA EXITOSAMENTE
════════════════════════════════════════════════════════
⏱️  Tiempo total: 3.45 segundos
════════════════════════════════════════════════════════
```

## ⚠️ Advertencias Importantes

1. **Respaldo**: Siempre haz un respaldo de tus datos antes de ejecutar el script con `--clear`
2. **Credenciales**: NUNCA subas `serviceAccountKey.json` a Git (ya está en `.gitignore`)
3. **Límites de Firestore**: El script respeta los límites de batch (500 operaciones)
4. **Costos**: Verifica los costos de Firestore antes de cargas masivas

## 🔧 Solución de Problemas

### Error: "serviceAccountKey.json not found"
- Asegúrate de haber descargado el archivo de credenciales de Firebase
- Colócalo en la raíz del proyecto (mismo nivel que `upload-to-firestore.js`)

### Error: "Permission denied"
- Verifica que la cuenta de servicio tenga permisos de lectura/escritura en Firestore
- Ve a Firebase Console → Firestore → Reglas

### Error: "firebase-admin not found"
```bash
npm install firebase-admin
```

### Los datos no aparecen en Firestore
- Verifica que estés conectado al proyecto correcto
- Revisa la consola de Firebase para ver si hay errores
- Comprueba las reglas de seguridad de Firestore

## 📝 Notas Adicionales

- El script usa **batch writes** para optimizar el rendimiento
- Los IDs de los documentos se mantienen de los archivos originales
- Las fechas se convierten automáticamente de formato Firebase a Date
- Si un documento ya existe con el mismo ID, será **sobrescrito**

## 🎯 Próximos Pasos

Después de cargar los datos:

1. Verifica en Firebase Console que los datos se cargaron correctamente
2. Prueba las consultas desde tu aplicación Flutter
3. Ajusta los índices de Firestore si es necesario para mejorar el rendimiento

## 📞 Soporte

Si tienes problemas con la carga:
1. Revisa los logs del script para identificar el error
2. Verifica los permisos en Firebase Console
3. Comprueba que los archivos JSON están bien formateados

---

**¿Todo listo?** Ejecuta:
```bash
node upload-to-firestore.js --clear
```
