# 🚀 PASOS RÁPIDOS PARA CARGAR DATOS A FIRESTORE

## Paso 1: Obtener Credenciales de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **ChatBotSecond**
3. Click en ⚙️ **Configuración del proyecto**
4. Ve a la pestaña **Cuentas de servicio**
5. Click en **Generar nueva clave privada**
6. Guarda el archivo como `serviceAccountKey.json` en la raíz del proyecto

## Paso 2: Instalar Dependencias

```bash
npm install
```

O si no funciona:
```bash
npm install firebase-admin
```

## Paso 3: Verificar Conexión (Opcional pero Recomendado)

```bash
node test-connection.js
```

Deberías ver:
```
✅ Conexión exitosa a Firestore!
📊 Proyecto: [tu-proyecto]
```

## Paso 4: Cargar los Datos

### Primera vez (limpiar y cargar):
```bash
node upload-to-firestore.js --clear
```

### Actualizar datos existentes:
```bash
node upload-to-firestore.js
```

## Paso 5: Verificar en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Firestore Database**
4. Deberías ver 3 colecciones:
   - ✅ `faqs` (87 documentos)
   - ✅ `emergency_contacts` (4 documentos)
   - ✅ `categories` (9 documentos)

## 📊 Resultado Esperado

```
════════════════════════════════════════════════════════
✅ CARGA COMPLETADA EXITOSAMENTE
════════════════════════════════════════════════════════
📚 FAQs: 87 documentos
🚨 Contactos de Emergencia: 4 documentos
📂 Categorías: 9 documentos
📦 Total: 100 documentos
⏱️  Tiempo total: ~3-5 segundos
════════════════════════════════════════════════════════
```

## ⚠️ IMPORTANTE

- ❌ **NO subas** `serviceAccountKey.json` a Git (ya está en .gitignore)
- ✅ **SÍ haz** un respaldo antes de usar `--clear`
- ✅ **SÍ verifica** la conexión primero con `test-connection.js`

## 🆘 ¿Problemas?

### Error: "Cannot find module 'firebase-admin'"
```bash
npm install firebase-admin
```

### Error: "serviceAccountKey.json not found"
- Verifica que el archivo esté en la raíz del proyecto
- Verifica que se llame exactamente `serviceAccountKey.json`

### Error: "Permission denied"
- Ve a Firebase Console → Firestore → Reglas
- Asegúrate de tener permisos de escritura

### Los datos no aparecen
- Espera 5-10 segundos y refresca Firebase Console
- Verifica que el script terminó sin errores
- Revisa los logs en Firebase Console

## 📞 Comandos Útiles

```bash
# Ver ayuda del script
node upload-to-firestore.js --help

# Verificar conexión
node test-connection.js

# Cargar sin limpiar
node upload-to-firestore.js

# Limpiar y cargar
node upload-to-firestore.js --clear
```

---

**¿Listo?** Comienza con el Paso 1 👆
