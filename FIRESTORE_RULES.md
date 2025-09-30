# 🔥 Configuración de Firestore Security Rules

## 📍 **Ubicación:**
Firebase Console → Firestore Database → Rules

## 🔧 **Reglas para desarrollo (temporal):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir todas las operaciones para desarrollo
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## 🔒 **Reglas para producción (recomendadas):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Conversaciones: acceso limitado por usuario
    match /conversations/{conversationId} {
      allow read, write: if resource.data.userId == request.auth.uid
                         || !exists(/databases/$(database)/documents/conversations/$(conversationId));
      
      // Mensajes dentro de conversaciones
      match /messages/{messageId} {
        allow read, write: if get(/databases/$(database)/documents/conversations/$(conversationId)).data.userId == request.auth.uid
                           || !exists(/databases/$(database)/documents/conversations/$(conversationId));
      }
    }
  }
}
```

## ⚡ **Pasos para configurar:**

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Ve a **Firestore Database**
4. Click en **Rules** (pestaña superior)
5. Reemplaza las reglas existentes con las de **desarrollo**
6. Click **Publish**

## ⚠️ **Importante:**
- Las reglas de desarrollo permiten acceso total (solo para testing)
- Para producción, usa las reglas más restrictivas
- Los usuarios anónimos también tendrán acceso con estas reglas

---

## 🎯 **Después de configurar:**
1. Reinicia la app Flutter
2. Las conversaciones se guardarán automáticamente
3. El historial persistirá entre sesiones