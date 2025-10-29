// upload-to-firestore.js
// Script para cargar FAQs, contactos de emergencia y categorías a Firestore

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ============================================================================
// CONFIGURACIÓN
// ============================================================================

// Inicializar Firebase Admin con tu archivo de credenciales
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ============================================================================
// FUNCIONES DE CARGA
// ============================================================================

/**
 * Convierte timestamp de Firestore a Date para facilitar la carga
 */
function convertTimestamp(timestamp) {
  if (timestamp && timestamp._seconds) {
    return new Date(timestamp._seconds * 1000);
  }
  return new Date();
}

/**
 * Carga las FAQs a Firestore
 */
async function uploadFAQs() {
  console.log('\n📚 Iniciando carga de FAQs...');
  
  try {
    const faqsData = JSON.parse(fs.readFileSync('./faqs_curadas.txt', 'utf8'));
    const batch = db.batch();
    let count = 0;

    for (const faq of faqsData) {
      const docRef = db.collection('faqs').doc(faq.id);
      
      // Preparar el documento con los campos correctos
      const faqDoc = {
        question: faq.question || '',
        questionEn: faq.question_en || '',
        questionPt: faq.question_pt || '',
        answer: faq.answer || '',
        answerEn: faq.answer_en || '',
        answerPt: faq.answer_pt || '',
        category: faq.category || 'general',
        priority: faq.priority || 5,
        link: faq.source_url || null,
        tags: faq.tags || [],
        createdAt: faq.created_at ? convertTimestamp(faq.created_at) : new Date(),
        updatedAt: new Date()
      };

      batch.set(docRef, faqDoc);
      count++;

      // Firestore tiene un límite de 500 operaciones por batch
      if (count % 400 === 0) {
        await batch.commit();
        console.log(`✅ Cargadas ${count} FAQs...`);
      }
    }

    // Commit del último batch
    if (count % 400 !== 0) {
      await batch.commit();
    }

    console.log(`✅ Total de FAQs cargadas: ${count}`);
    return count;
  } catch (error) {
    console.error('❌ Error cargando FAQs:', error);
    throw error;
  }
}

/**
 * Carga los contactos de emergencia a Firestore
 */
async function uploadEmergencyContacts() {
  console.log('\n🚨 Iniciando carga de Contactos de Emergencia...');
  
  try {
    const contactsData = JSON.parse(fs.readFileSync('./emergency_conctacts.txt', 'utf8'));
    const batch = db.batch();
    let count = 0;

    for (const contact of contactsData) {
      const docRef = db.collection('emergency_contacts').doc(contact.id);
      
      const contactDoc = {
        name: contact.name || '',
        nameEn: contact.name_en || '',
        namePt: contact.name_pt || '',
        phone: contact.phone || '',
        type: contact.type || '',
        typeEn: contact.type_en || '',
        typePt: contact.type_pt || '',
        keyWords: contact.key_words || [],
        keyWordsEn: contact.key_words_en || [],
        keyWordsPt: contact.key_words_pt || [],
        available24h: contact.available_24h || false,
        createdAt: contact.created_at ? convertTimestamp(contact.created_at) : new Date(),
        updatedAt: new Date()
      };

      batch.set(docRef, contactDoc);
      count++;
    }

    await batch.commit();
    console.log(`✅ Total de Contactos de Emergencia cargados: ${count}`);
    return count;
  } catch (error) {
    console.error('❌ Error cargando contactos de emergencia:', error);
    throw error;
  }
}

/**
 * Carga las categorías a Firestore
 */
async function uploadCategories() {
  console.log('\n📂 Iniciando carga de Categorías...');
  
  try {
    const categoriesData = JSON.parse(fs.readFileSync('./categories_v2.txt', 'utf8'));
    const batch = db.batch();
    let count = 0;

    for (const category of categoriesData) {
      const docRef = db.collection('categories').doc(category.id);
      
      const categoryDoc = {
        name: category.name || '',
        icon: category.icon || '📁',
        priority: category.priority || 5,
        description: category.description || '',
        createdAt: category.created_at ? convertTimestamp(category.created_at) : new Date(),
        updatedAt: category.updated_at ? convertTimestamp(category.updated_at) : new Date()
      };

      batch.set(docRef, categoryDoc);
      count++;
    }

    await batch.commit();
    console.log(`✅ Total de Categorías cargadas: ${count}`);
    return count;
  } catch (error) {
    console.error('❌ Error cargando categorías:', error);
    throw error;
  }
}

/**
 * Limpia una colección antes de cargar nuevos datos
 */
async function clearCollection(collectionName) {
  console.log(`\n🗑️  Limpiando colección: ${collectionName}...`);
  
  try {
    const snapshot = await db.collection(collectionName).get();
    const batch = db.batch();
    let count = 0;

    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`✅ Eliminados ${count} documentos de ${collectionName}`);
    } else {
      console.log(`ℹ️  La colección ${collectionName} ya estaba vacía`);
    }
  } catch (error) {
    console.error(`❌ Error limpiando colección ${collectionName}:`, error);
    throw error;
  }
}

/**
 * Verifica que los archivos existan antes de comenzar
 */
function checkFiles() {
  const files = [
    './faqs_curadas.txt',
    './emergency_conctacts.txt',
    './categories_v2.txt',
    './serviceAccountKey.json'
  ];

  console.log('\n📋 Verificando archivos necesarios...');
  
  for (const file of files) {
    if (!fs.existsSync(file)) {
      console.error(`❌ Archivo no encontrado: ${file}`);
      process.exit(1);
    }
    console.log(`✅ ${file}`);
  }
  
  console.log('\n✅ Todos los archivos están presentes');
}

/**
 * Muestra estadísticas de los datos a cargar
 */
function showStatistics() {
  console.log('\n📊 ESTADÍSTICAS DE DATOS A CARGAR:\n');
  
  const faqsData = JSON.parse(fs.readFileSync('./faqs_curadas.txt', 'utf8'));
  const contactsData = JSON.parse(fs.readFileSync('./emergency_conctacts.txt', 'utf8'));
  const categoriesData = JSON.parse(fs.readFileSync('./categories_v2.txt', 'utf8'));

  console.log(`📚 FAQs: ${faqsData.length} documentos`);
  console.log(`🚨 Contactos de Emergencia: ${contactsData.length} documentos`);
  console.log(`📂 Categorías: ${categoriesData.length} documentos`);
  console.log(`📦 Total: ${faqsData.length + contactsData.length + categoriesData.length} documentos\n`);

  // Estadísticas por categoría
  const faqsByCategory = {};
  faqsData.forEach(faq => {
    faqsByCategory[faq.category] = (faqsByCategory[faq.category] || 0) + 1;
  });

  console.log('📊 FAQs por categoría:');
  Object.entries(faqsByCategory)
    .sort((a, b) => b[1] - a[1])
    .forEach(([category, count]) => {
      console.log(`   ${category}: ${count}`);
    });
}

// ============================================================================
// FUNCIÓN PRINCIPAL
// ============================================================================

async function main() {
  console.log('🚀 SCRIPT DE CARGA A FIRESTORE');
  console.log('================================\n');

  try {
    // 1. Verificar archivos
    checkFiles();

    // 2. Mostrar estadísticas
    showStatistics();

    // 3. Confirmar con el usuario
    console.log('\n⚠️  ADVERTENCIA: Este script sobrescribirá los datos existentes en Firestore.');
    console.log('   Asegúrate de tener un respaldo antes de continuar.\n');

    // 4. Limpiar colecciones (opcional - comentar si no quieres limpiar)
    const shouldClear = process.argv.includes('--clear');
    if (shouldClear) {
      await clearCollection('faqs');
      await clearCollection('emergency_contacts');
      await clearCollection('categories');
    }

    // 5. Cargar datos
    const startTime = Date.now();

    await uploadCategories();
    await uploadEmergencyContacts();
    await uploadFAQs();

    const endTime = Date.now();
    const duration = ((endTime - startTime) / 1000).toFixed(2);

    // 6. Resumen final
    console.log('\n════════════════════════════════════════════════════════');
    console.log('✅ CARGA COMPLETADA EXITOSAMENTE');
    console.log('════════════════════════════════════════════════════════');
    console.log(`⏱️  Tiempo total: ${duration} segundos`);
    console.log('════════════════════════════════════════════════════════\n');

  } catch (error) {
    console.error('\n❌ ERROR EN LA CARGA:', error);
    process.exit(1);
  } finally {
    // Cerrar la conexión
    process.exit(0);
  }
}

// ============================================================================
// EJECUCIÓN
// ============================================================================

// Verificar argumentos
if (process.argv.includes('--help')) {
  console.log(`
Uso: node upload-to-firestore.js [opciones]

Opciones:
  --clear    Limpia las colecciones antes de cargar los nuevos datos
  --help     Muestra esta ayuda

Ejemplos:
  node upload-to-firestore.js           # Carga sin limpiar
  node upload-to-firestore.js --clear   # Limpia y carga
  `);
  process.exit(0);
}

// Ejecutar
main().catch(error => {
  console.error('Error fatal:', error);
  process.exit(1);
});
