const admin = require("firebase-admin");
const fs = require("fs");

// Reemplaza por la ruta correcta de tu archivo de credenciales
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function getCollectionAndSaveToTxt(collectionName, outputFile) {
  const snapshot = await db.collection(collectionName).get();
  const results = [];

  snapshot.forEach(doc => {
    // Puedes cambiar el formato aquí si prefieres
    results.push({ id: doc.id, ...doc.data() });
  });

  // Guarda como texto plano (puedes adaptar la línea para json, csv, etc)
  fs.writeFileSync(outputFile, JSON.stringify(results, null, 2), "utf8");
  console.log(`Colección guardada en ${outputFile}`);
}

// Ejemplo de uso:
getCollectionAndSaveToTxt("categories_v2", "output.txt");
