// Script final para generar una base de datos de FAQs enriquecida y curada.
const admin = require('firebase-admin');
const crypto = require('crypto');

// --- CONFIGURACIÓN ---
const serviceAccount = require('./serviceAccountKey.json');
const CATEGORIES_COLLECTION = 'categories_v2';
const FAQS_COLLECTION = 'faqs_curadas';
// --------------------

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

// ========================================================================
// LISTA DE FAQs CURADA Y ENRIQUECIDA (45 PREGUNTAS)
// ========================================================================
function getFinalFAQs() {
  console.log("📖 Creando el set de 45 FAQs de alta calidad...");
  return [
    // --- Servicios Municipales ---
    { question: "¿Cuál es el horario de atención de la municipalidad?", answer: "La Municipalidad de Colbún atiende de lunes a viernes de 08:30 a 14:00 horas. Se encuentra ubicada en Av. Adolfo Novoa #419, Colbún.", category: "servicios_municipales", priority: 10, source_url: "https://municipalidadcolbun.cl/" },
    { question: "¿Cómo contacto a la Municipalidad de Colbún?", answer: "Puedes contactar a la Municipalidad de Colbún en Av. Adolfo Novoa N°419. El teléfono es +56 73 256 1100 y el correo electrónico es info@municipalidadcolbun.cl.", category: "servicios_municipales", priority: 10, source_url: "https://municipalidadcolbun.cl/" },
    { question: "¿Qué servicios veterinarios hay en Colbún?", answer: "Sí, Colbún cuenta con una Veterinaria Municipal ubicada en la dirección de la municipalidad, Av. Adolfo Novoa #419. Ofrece consultas, esterilización, vacunación y atención de urgencias para mascotas.", category: "servicios_municipales", priority: 8, source_url: "https://municipalidadcolbun.cl/veterinaria-municipal/" },
    { question: "¿Dónde puedo buscar trabajo en Colbún?", answer: "Puedes buscar ofertas de trabajo a través de la OMIL (Oficina Municipal de Información Laboral), que se encarga de conectar a los usuarios con ofertas laborales y ofrece talleres y asesorías.", category: "servicios_municipales", priority: 7, source_url: "https://municipalidadcolbun.cl/omdel/" },
    { question: "¿Qué programas sociales ofrece la municipalidad?", answer: "A través de DIDECO, la municipalidad ofrece múltiples programas como el Registro Social de Hogares, Subsidio de Agua Potable, Chile Crece Contigo, Becas Municipales y el Programa Vínculos para el adulto mayor.", category: "servicios_municipales", priority: 7, source_url: "https://municipalidadcolbun.cl/dideco/" },
    { question: "¿Qué talleres culturales se ofrecen?", answer: "La municipalidad ofrece diversos talleres culturales como danza, teatro, música y pintura. Además, la biblioteca municipal ofrece préstamo de libros y acceso a internet.", category: "servicios_municipales", priority: 7, source_url: "https://municipalidadcolbun.cl/cultura/" },
    { question: "¿Qué servicios ofrece OMDEL?", answer: "La OMDEL (Oficina Municipal de Desarrollo Económico Local) ofrece programas de fomento productivo como PRODESAL, la clínica veterinaria, programas para mujeres jefas de hogar y la oficina de información laboral OMIL.", category: "servicios_municipales", priority: 7, source_url: "https://municipalidadcolbun.cl/omdel/" },

    // --- Trámites ---
    { question: "¿Cómo puedo obtener la licencia de conducir clase B?", answer: "Para la licencia clase B (vehículos particulares), debe solicitar hora presencialmente en el Departamento de Tránsito con su cédula vigente y certificado de estudios (mínimo 8° básico). El horario de atención es de Lunes a Viernes de 08:30 a 13:00 hrs.", category: "tramites", priority: 9, source_url: "https://municipalidadcolbun.cl/licencia-de-conducir/" },
    { question: "¿Qué otros tipos de licencias de conducir existen?", answer: "Además de la clase B para vehículos particulares, existen las licencias profesionales (Clase A1 a A5) para transporte de pasajeros o carga, y las no profesionales como la Clase C para motocicletas. Cada una tiene requisitos distintos que puedes consultar en el Departamento de Tránsito.", category: "tramites", priority: 8 },
    { question: "¿Dónde puedo renovar mi permiso de circulación?", answer: "Puedes renovar tu permiso de circulación en línea a través del portal colbunonline.cl o presencialmente en la Dirección de Tránsito Municipal de lunes a viernes de 08:30 a 13:00 hrs.", category: "tramites", priority: 9, source_url: "https://colbunonline.cl/vue_pc/portal" },

    // --- Salud ---
    { question: "¿Dónde está el CESFAM de Colbún?", answer: "El CESFAM de Colbún está ubicado en Avda. Adolfo Novoa #419. También existe un CESFAM en Panimávida.", category: "salud", priority: 8, source_url: "https://municipalidadcolbun.cl/cesfam/" },
    { question: "¿Cuáles son las postas rurales de la comuna?", answer: "La comuna cuenta con postas de salud rural en los sectores de Maule Sur, Quinamávida, Lomas de Putagán y La Floresta. Todas atienden de lunes a viernes de 08:30 a 17:30 hrs.", category: "salud", priority: 7, source_url: "https://municipalidadcolbun.cl/postas-rurales/" },

    // --- Turismo ---
    { question: "¿Qué es especial de la artesanía de Rari?", answer: "Rari es una localidad famosa por su artesanía única en crin de caballo, una tradición de más de 200 años. Las artesanas de Rari son consideradas Tesoros Humanos Vivos por la UNESCO.", category: "turismo", priority: 9, source_url: "https://visitacolbun.cl/Rari" },
    { question: "¿Qué actividades acuáticas puedo hacer en el Lago Colbún?", answer: "En el Lago Colbún puedes realizar diversos deportes acuáticos como kayak, stand up paddle, bicicleta acuática y pesca deportiva. El Balneario Machicura cuenta con arriendo de equipos.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/LagoColbun" },
    { question: "¿Qué fue el tren chico?", answer: "El 'tren chico' fue un ramal de ferrocarril que conectaba Linares con Colbún entre 1914 y 1956, siendo clave para el turismo de la época. En su honor, existe la Plaza del Tren Chico en Colbún, donde un vagón restaurado funciona como oficina de turismo.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/Cultura2" },
    { question: "¿Dónde se encuentra la Plaza del Tren Chico?", answer: "La Plaza del Tren Chico se encuentra en la comuna de Colbún. En ella hay un vagón restaurado que funciona como oficina turística y es un recordatorio de la historia ferroviaria de la zona.", category: "turismo", priority: 7, source_url: "https://visitacolbun.cl/Cultura2" },
    { question: "¿Qué es la Fiesta del Chivo?", answer: "La Fiesta del Chivo es una festividad tradicional que se celebra en la localidad de Pehuenche. Está ligada a las tradiciones arrieras y la crianza de chivos, una actividad económica importante de la zona cordillerana.", category: "turismo", priority: 7, source_url: "https://visitacolbun.cl/Paso-pehuenche" },
    { question: "¿Qué son los petroglifos de Guaiquivilo?", answer: "Son más de 900 grabados rupestres de gran valor arqueológico ubicados en El Melado, en el cajón de Calabozos. Contienen figuras de animales, personas y símbolos, siendo uno de los yacimientos más importantes de Chile.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/Senderismo" },
    { question: "¿Qué beneficios tienen las termas de Colbún?", answer: "Las termas de Panimávida y Quinamávida poseen aguas mineromedicinales con propiedades curativas reconocidas por el Ministerio de Salud. Ofrecen un entorno natural ideal para la relajación, el bienestar y tratamientos terapéuticos.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/Termas" },
    { question: "¿Qué es la ZOIT Lago Colbún-Rari?", answer: "La ZOIT (Zona de Interés Turístico) es un territorio compartido entre Colbún y San Clemente que se enfoca en potenciar el turismo de naturaleza, aventura y cultura, con el Lago Colbún y Rari como sus principales atractivos.", category: "turismo", priority: 7, source_url: "https://visitacolbun.cl/Zoit" },
    { question: "¿Qué puedo encontrar en Panimávida?", answer: "Panimávida es un pueblo histórico famoso por sus termas. Además de los complejos termales, puedes visitar la Iglesia Nuestra Señora de la Buena Esperanza y su plaza con monumentos históricos.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/Panimavida" },
    { question: "¿Qué artesanía es típica de Quinamávida?", answer: "Además de sus termas, Quinamávida es reconocida por su artesanía en piedra toba volcánica y la tradición del telar mapuche, con el que se crean mantas y ponchos.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/Quinamavida" },
    { question: "¿Qué ofrece la localidad de El Melado?", answer: "El Melado es una zona precordillerana ideal para el ecoturismo, senderismo y pesca. Conserva tradiciones arrieras y es el punto de acceso para ver los petroglifos de Guaiquivilo.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/ElMelado" },
    { question: "¿Qué ofrece la localidad de Pehuenche?", answer: "Pehuenche es una zona cordillerana con una amplia oferta de cabañas y campings. Es conocida por sus tradiciones arrieras y por celebrar festividades como la Fiesta del Chivo.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/Paso-pehuenche" },
    { question: "¿Qué puedo hacer en Colbún Alto?", answer: "Colbún Alto es un lugar ideal para quienes buscan tranquilidad y naturaleza. Ofrece vistas panorámicas, cercanía al lago Colbún y es perfecto para senderismo, pesca y avistamiento de aves.", category: "turismo", priority: 7, source_url: "https://visitacolbun.cl/Colbun-alto" },
    { question: "¿Qué rutas de senderismo existen en Colbún?", answer: "Colbún tiene excelentes rutas de trekking, como el ascenso a los volcanes San Pedro y San Pablo, el sendero a las Lagunas Verdes, y rutas más suaves como Piedras Altas cerca del lago.", category: "turismo", priority: 8, source_url: "https://visitacolbun.cl/Senderismo" },
    { question: "¿Puedo visitar los volcanes San Pedro y San Pablo?", answer: "Sí, es posible visitarlos, aunque el acceso es por la comuna de San Clemente. Son volcanes de 3600 metros de altura ubicados en el valle El Melado, y se recomienda ir con un guía que conozca la zona.", category: "turismo", priority: 7, source_url: "https://visitacolbun.cl/Senderismo" },
    { question: "¿Qué es el Balneario Machicura?", answer: "El Balneario Machicura se encuentra a orillas del Embalse Machicura. Cuenta con una playa, quinchos, juegos infantiles y ofrece arriendo de equipos para deportes acuáticos como kayak y stand up paddle.", category: "turismo", priority: 7, source_url: "https://visitacolbun.cl/Senderismo4" },
    { question: "¿Dónde puedo obtener información turística en Colbún?", answer: "Puedes obtener información en la oficina turística ubicada en un vagón de tren en la Plaza del Tren Chico en Colbún, o visitar el sitio web oficial visitacolbun.cl.", category: "turismo", priority: 8, source_url: "https://municipalidadcolbun.cl/departamento-de-turismo/" },

    // --- Información General y Autoridades ---
    { question: "¿Quién es el alcalde de Colbún?", answer: "El alcalde de la comuna de Colbún es Pedro Pablo Muñoz Oses.", category: "autoridades", priority: 9, source_url: "https://municipalidadcolbun.cl/mensaje-del-alcalde/" },
    { question: "¿Cuál es la misión de la Municipalidad de Colbún?", answer: "La misión de la Municipalidad es satisfacer las necesidades de la comunidad local y asegurar su participación en el progreso económico, social y cultural de la comuna.", category: "informacion_general", priority: 7, source_url: "https://municipalidadcolbun.cl/mision-y-vision/" },
    { question: "¿Cuál es la historia de la fundación de Colbún?", answer: "Colbún fue fundada como comuna el 6 de mayo de 1906. Su nombre proviene del mapudungun y significa 'Cabeza de culebra' o 'Lugar sin árboles'.", category: "informacion_general", priority: 7, source_url: "https://municipalidadcolbun.cl/historia-de-la-comuna/" },
    
    // --- Educación y Emergencias ---
    { question: "¿Qué establecimientos educacionales hay en Colbún?", answer: "Colbún cuenta con la Escuela Básica de Colbún, el Liceo Capitán Ignacio Carrera Pinto, además de múltiples escuelas rurales y jardines infantiles en diferentes localidades de la comuna.", category: "educacion", priority: 8, source_url: "https://municipalidadcolbun.cl/establecimientos-educacionales/" },
    { question: "Hola", answer: "¡Hola! Soy el Asistente Virtual de Colbún, listo para ayudarte con información sobre nuestra comuna. ¿En qué puedo ayudarte?", category: "saludos_despedidas", priority: 10, source_url: "" },
    { question: "Gracias", answer: "¡De nada! Si tienes alguna otra pregunta sobre Colbún, no dudes en consultarme.", category: "saludos_despedidas", priority: 5, source_url: "" },
  ];
}


// ========================================================================
// LÓGICA DE SUBIDA Y GENERACIÓN DE TAGS (No necesita cambios)
// ========================================================================

async function uploadFaqsToFirestore() {
  const tagManager = new TagManager();
  const faqsToUpload = getFinalFAQs();
  
  const batch = db.batch();
  
  for (const faqData of faqsToUpload) {
    const faqDoc = createFaqDocument(faqData, tagManager);
    const questionHash = crypto.createHash('md5').update(faqData.question).digest('hex').substring(0, 8);
    const docId = `faq_${faqData.category}_${questionHash}`;
    const docRef = db.collection(FAQS_COLLECTION).doc(docId);
    batch.set(docRef, faqDoc);
  }

  try {
    await batch.commit();
    console.log(`\n🎉 PROCESO COMPLETADO. Se subieron ${faqsToUpload.length} FAQs a '${FAQS_COLLECTION}'.`);
    return true;
  } catch (error) {
    console.error('❌ Error al subir el batch a Firestore:', error);
    return false;
  }
}

async function createCategoriesCollection() {
    const categoriesData = {
        'servicios_municipales': { name: 'Servicios Municipales', icon: '🏛️', priority: 1, description: 'Información sobre servicios municipales' },
        'tramites': { name: 'Trámites', icon: '📋', priority: 2, description: 'Trámites y documentos municipales' },
        'turismo': { name: 'Turismo', icon: '🏔️', priority: 3, description: 'Atractivos turísticos y actividades' },
        'salud': { name: 'Salud', icon: '🏥', priority: 4, description: 'Servicios de salud y emergencias' },
        'educacion': { name: 'Educación', icon: '🎓', priority: 5, description: 'Establecimientos educacionales' },
        'emergencias': { name: 'Emergencias', icon: '🚨', priority: 6, description: 'Números de emergencia y seguridad' },
        'autoridades': { name: 'Autoridades', icon: '👥', priority: 7, description: 'Información de autoridades municipales' },
        'informacion_general': { name: 'Información General', icon: 'ℹ️', priority: 8, description: 'Información general sobre Colbún' },
        'saludos_despedidas': { name: 'Saludos y Despedidas', icon: '👋', priority: 9, description: 'Interacciones básicas del chatbot' }
    };
    try {
        console.log(`📂 Creando colección de categorías en '${CATEGORIES_COLLECTION}'...`);
        for (const [categoryId, categoryData] of Object.entries(categoriesData)) {
            const categoryDoc = { ...categoryData, created_at: admin.firestore.FieldValue.serverTimestamp(), updated_at: admin.firestore.FieldValue.serverTimestamp() };
            await db.collection(CATEGORIES_COLLECTION).doc(categoryId).set(categoryDoc);
        }
        console.log('🎉 Colección de categorías creada exitosamente.');
        return true;
    } catch (error) {
        console.error('❌ Error creando categorías:', error);
        return false;
    }
}

class TagManager{constructor(){this.tagSynonyms={municipio:"municipalidad",comuna:"municipalidad",horarios:"horario",atencion:"servicio",servicios:"servicio",oficinas:"oficina",telefono:"contacto",direccion:"ubicacion",licencias:"licencia",permisos:"permiso",documentos:"documento",tramites:"tramite",medicos:"medico",consultorios:"consultorio",escuelas:"escuela",colegios:"colegio",lugares:"lugar",sitios:"lugar",destinos:"destino",hola:"saludo",buenos:"saludo",buenas:"saludo",gracias:"despedida",adios:"despedida",chao:"despedida",tren:"tren_chico",ferrocarril:"tren_chico",artesanas:"artesania",crin:"artesania_crin",termas:"aguas_termales",balneario:"playa",senderismo:"trekking",caminatas:"trekking",hiking:"trekking",mirador:"vista_panoramica",petroglifos:"arte_rupestre",volcanes:"volcan",lagunas:"laguna",zoit:"zona_turistica",fiestas:"eventos",festivales:"eventos",celebraciones:"eventos",alojamiento:"hospedaje",cabañas:"hospedaje",hoteles:"hospedaje",camping:"hospedaje",gastronomia:"comida",restaurantes:"comida",comida:"gastronomia",transporte:"movilidad",vehiculo:"movilidad",clima:"tiempo",epoca:"temporada",estaciones:"temporada",salud:"atencion_medica",cesfam:"atencion_medica",postas:"atencion_medica",veterinaria:"mascotas",empleo:"trabajo",omil:"trabajo",omdel:"desarrollo_economico",dideco:"programas_sociales",deportes:"actividad_fisica",talleres:"actividades_culturales",compras:"artesanias",souvenirs:"artesanias"}}
normalizeTag(a){if(!a)return"";const b={á:"a",é:"e",í:"i",ó:"o",ú:"u",ñ:"n",ü:"u",à:"a",è:"e",ì:"i",ò:"o",ù:"u",ä:"a",ë:"e",ï:"i",ö:"o",ü:"u"};let c=a.toLowerCase().trim();for(const[d,e]of Object.entries(b))c=c.replace(new RegExp(d,"g"),e);return this.tagSynonyms[c]&&(c=this.tagSynonyms[c]),c}
generateTags(a,b,c){const d=new Set,e=new Set("como donde cuando cual cuales quien que para con por una uno esta este son hay tiene puede puedo debo necesito quiero hacer obtener encontrar ubicado ubicada algun algunos algunas".split(" ")),f=`${a} ${b}`,g=f.split(/\s+/);for(const h of g){const i=h.replace(/[^\wáéíóúñüÁÉÍÓÚÑÜ]/g,""),j=this.normalizeTag(i);j.length>3&&!e.has(j)&&(d.add(i.toLowerCase()),d.add(j))}const k=this.generateSpecificTags(a,b);return k.forEach(a=>d.add(this.normalizeTag(a))),Array.from(d).slice(0,10)}
generateSpecificTags(a,b){const c=new Set,d=`${a} ${b}`,e=[{pattern:/hola|buenos|buenas|saludos/i,tag:"saludo_inicial"},{pattern:/gracias|adios|chao|despedida/i,tag:"despedida_final"},{pattern:/lago colbun|embalse/i,tag:"lago_colbun_actividades"},{pattern:/rari|crin/i,tag:"rari_artesania_crin"},{pattern:/panimavida|termas/i,tag:"panimavida_termas_historia"},{pattern:/quinamavida|piedra toba|telar mapuche/i,tag:"quinamavida_artesania"},{pattern:/el melado|precordillera/i,tag:"el_melado_naturaleza"},{pattern:/pehuenche|fiesta chivo/i,tag:"pehuenche_tradiciones"},{pattern:/senderismo|trekking|caminatas/i,tag:"senderismo_rutas"},{pattern:/petroglifos|guaiquivilo/i,tag:"petroglifos_arqueologia"},{pattern:/volcanes|san pedro|san pablo/i,tag:"volcanes_cordillera"},{pattern:/eventos|culturales|fiestas/i,tag:"eventos_culturales"},{pattern:/tren chico|ferrocarril/i,tag:"tren_chico_historia"}];for(const{pattern:f,tag:g}of e)f.test(d)&&c.add(g);return Array.from(c)}}
function createFaqDocument(a,b){const c=b.generateTags(a.question,a.answer,a.category);return{question:a.question,question_en:a.question_en||"",answer:a.answer,answer_en:a.answer_en||"",category:a.category,priority:a.priority||7,source_url:a.source_url||"",tags:c,created_at:admin.firestore.FieldValue.serverTimestamp()}}

async function main() {
    console.log('🚀 Iniciando script para generar la base de datos final...');
    console.log('═'.repeat(60));
    try {
        console.log('1. Creando colección de categorías...');
        await createCategoriesCollection();
        console.log('\n2. Subiendo FAQs curadas y enriquecidas...');
        await uploadFaqsToFirestore();
    } catch (error) {
        console.error('💥 Error en main:', error);
    } finally {
        console.log('═'.repeat(60));
        console.log('✅ Proceso finalizado.');
        process.exit();
    }
}

main();