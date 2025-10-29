// Script para generar y subir FAQs a Firestore para el chatbot de la Municipalidad de Colbún
// Basado en información de municipalidadcolbun.cl y visitacolbun.cl

const admin = require('firebase-admin');
const crypto = require('crypto');

// Configuración de Firebase - Reemplaza con tu configuración
const serviceAccount = require('./config/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Sistema de gestión de tags para evitar duplicados y solapamientos
class TagManager {
  constructor() {
    this.usedTags = new Set();
    this.tagSynonyms = {
      'municipio': 'municipalidad',
      'comuna': 'municipalidad',
      'horarios': 'horario',
      'atencion': 'servicio',
      'oficinas': 'oficina',
      'telefono': 'contacto',
      'direccion': 'ubicacion',
      'licencias': 'licencia',
      'permisos': 'permiso',
      'documentos': 'documento',
      'tramites': 'tramite',
      'medicos': 'medico',
      'consultorios': 'consultorio',
      'escuelas': 'escuela',
      'colegios': 'colegio',
      'lugares': 'lugar',
      'sitios': 'lugar',
      'destinos': 'destino',
      'hola': 'saludo',
      'buenos': 'saludo',
      'buenas': 'saludo',
      'gracias': 'despedida',
      'adios': 'despedida',
      'chao': 'despedida',
      'tren': 'tren_chico',
      'ferrocarril': 'tren_chico',
      'artesanas': 'artesania',
      'crin': 'artesania_crin',
      'termas': 'aguas_termales',
      'balneario': 'playa',
      'senderismo': 'trekking',
      'caminatas': 'trekking',
      'hiking': 'trekking',
      'mirador': 'vista_panoramica',
      'petroglifos': 'arte_rupestre',
      'volcanes': 'volcan',
      'lagunas': 'laguna',
      'zoit': 'zona_turistica',
      'fiestas': 'eventos',
      'festivales': 'eventos',
      'celebraciones': 'eventos',
      'alojamiento': 'hospedaje',
      'cabañas': 'hospedaje',
      'hoteles': 'hospedaje',
      'camping': 'hospedaje',
      'gastronomia': 'comida',
      'restaurantes': 'comida',
      'comida': 'gastronomia',
      'transporte': 'movilidad',
      'vehiculo': 'movilidad',
      'clima': 'tiempo',
      'epoca': 'temporada',
      'estaciones': 'temporada',
      'salud': 'atencion_medica',
      'cesfam': 'atencion_medica',
      'postas': 'atencion_medica',
      'veterinaria': 'mascotas',
      'empleo': 'trabajo',
      'omil': 'trabajo',
      'omdel': 'desarrollo_economico',
      'dideco': 'programas_sociales',
      'deportes': 'actividad_fisica',
      'talleres': 'actividades_culturales',
      'compras': 'artesanias',
      'souvenirs': 'artesanias'
    };
  }

  normalizeTag(tag) {
    const replacements = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'ñ': 'n', 'ü': 'u',
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
      'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ü': 'u'
    };
    
    let normalized = tag.toLowerCase().trim();
    
    // Reemplazar caracteres especiales manteniendo la vocal
    for (const [oldChar, newChar] of Object.entries(replacements)) {
      normalized = normalized.replace(new RegExp(oldChar, 'g'), newChar);
    }
    
    // Aplicar sinónimos
    if (this.tagSynonyms[normalized]) {
      normalized = this.tagSynonyms[normalized];
    }
    
    return normalized;
  }
  generateTags(question, answer, category) {
    const keywords = [];
    
    // Palabras excluidas
    const excludeWords = new Set([
      'como', 'donde', 'cuando', 'cual', 'cuales', 'quien', 'que', 'para',
      'con', 'por', 'una', 'uno', 'esta', 'este', 'son', 'hay', 'tiene',
      'puede', 'puedo', 'debo', 'necesito', 'quiero', 'hacer', 'obtener',
      'encontrar', 'ubicado', 'ubicada', 'algun', 'algunos', 'algunas'
    ]);
    
    // Extraer palabras clave específicas de pregunta y respuesta
    const allText = `${question} ${answer}`.toLowerCase();
     const words = allText.match(/[\wáéíóúñüàèìòùäëïöü]+/g) || [];
    
    for (const word of words) {
    const cleanWord = word.replace(/[^\wáéíóúñüàèìòùäëïöü]/gi, '');
    
      if (cleanWord.length > 3 && !excludeWords.has(cleanWord)) {
        // Añadir la palabra original
        keywords.push(cleanWord);
        
        // Añadir también la versión normalizada (sin tildes)
        const normalizedWord = this.normalizeTag(cleanWord);
        if (normalizedWord !== cleanWord) {
          keywords.push(normalizedWord);
        }
      }
    }
    // Comentado para evitar solapamientos
    /* // Tags específicos y únicos por categoría + combinaciones
    const categoryTags = {
      'servicios_municipales': [
        'municipalidad_horario', 'municipalidad_ubicacion', 'municipalidad_telefono',
        'veterinaria_municipal', 'servicios_publicos', 'contacto_municipalidad'
      ],
      'tramites': [
        'licencia_conducir', 'permiso_circulacion', 'tramites_transito',
        'documentos_personales', 'requisitos_licencia'
      ],
      'salud': [
        'cesfam_colbun', 'cesfam_panimavida', 'postas_rurales',
        'horarios_salud', 'atencion_medica', 'servicios_salud'
      ],
      'educacion': [
        'establecimientos_educacionales', 'escuelas_rurales', 'liceo_colbun',
        'daem_contacto', 'educacion_municipal'
      ],
      'turismo': [
        'lago_colbun', 'termas_panimavida', 'termas_quinamavida', 'artesania_rari',
        'atractivos_turisticos', 'zoit_colbun', 'senderos_trekking', 'balneario_machicura',
        'destinos_turisticos', 'actividades_turismo'
      ],
      'emergencias': [
        'numeros_emergencia', 'seguridad_ciudadana', 'urgencias_colbun',
        'carabineros_bomberos', 'contactos_emergencia'
      ],
      'autoridades': [
        'alcalde_colbun', 'concejo_municipal', 'autoridades_municipales'
      ],
      'informacion_general': [
        'historia_colbun', 'fundacion_comuna', 'mision_vision_municipal',
        'informacion_comunal', 'colbun_general'
      ],
      'saludos_despedidas': [
        'saludo_inicial', 'presentacion_bot', 'despedida_final'
      ]
    }; */
    
    /* // Agregar tags específicos de la categoría
    if (categoryTags[category]) {
      keywords.push(...categoryTags[category]);
    } */
    
    // Generar tags específicos basados en contenido clave
    const specificTags = this.generateSpecificTags(question, answer, category);
    keywords.push(...specificTags);
    
    // Normalizar y deduplicar - IMPORTANTE: mantener ambas versiones
    const uniqueTags = [];
    const seenTags = new Set();
    
    for (const tag of keywords) {
      const normalized = this.normalizeTag(tag);
      
      // Añadir tanto la versión original como la normalizada
      const tagsToAdd = [tag];
      if (normalized !== tag) {
        tagsToAdd.push(normalized);
      }
      
      for (const tagToAdd of tagsToAdd) {
        if (!seenTags.has(tagToAdd) && tagToAdd.length > 2) {
          uniqueTags.push(tagToAdd);
          seenTags.add(tagToAdd);
          this.usedTags.add(tagToAdd);
        }
      }
    }
    
    return uniqueTags.slice(0, 10); // Aumentado a 10 para acomodar ambas versiones
  }
  generateSpecificTags(question, answer, category) {
    const specificTags = [];
    
    // Tags específicos basados en patrones de contenido
    const patterns = [
      { pattern: /hola|buenos|buenas|saludos/i, tag: 'saludo_inicial' },
      { pattern: /gracias|adios|chao|despedida/i, tag: 'despedida_final' },
      { pattern: /lago colbun|embalse/i, tag: 'lago_colbun_actividades' },
      { pattern: /rari|crin/i, tag: 'rari_artesania_crin' },
      { pattern: /panimavida|termas/i, tag: 'panimavida_termas_historia' },
      { pattern: /quinamavida|piedra toba|telar mapuche/i, tag: 'quinamavida_artesania' },
      { pattern: /el melado|precordillera/i, tag: 'el_melado_naturaleza' },
      { pattern: /pehuenche|fiesta chivo/i, tag: 'pehuenche_tradiciones' },
      { pattern: /senderismo|trekking|caminatas/i, tag: 'senderismo_rutas' },
      { pattern: /petroglifos|guaiquivilo/i, tag: 'petroglifos_arqueologia' },
      { pattern: /volcanes|san pedro|san pablo/i, tag: 'volcanes_cordillera' },
      { pattern: /lagunas verdes|achibueno/i, tag: 'lagunas_verdes_trekking' },
      { pattern: /mirador vizcachas|rabones/i, tag: 'mirador_vistas' },
      { pattern: /baños socorro|termas naturales/i, tag: 'termas_naturales' },
      { pattern: /eventos|culturales|fiestas/i, tag: 'eventos_culturales' },
      { pattern: /tren chico|ferrocarril/i, tag: 'tren_chico_historia' },
      { pattern: /molino tilos|historia/i, tag: 'molino_tilos_patrimonio' },
      { pattern: /iglesia panimavida|buena esperanza/i, tag: 'iglesia_panimavida' },
      { pattern: /chancho al humo|la guardia/i, tag: 'chancho_humo_tradicion' },
      { pattern: /zoit|zona turistica/i, tag: 'zoit_desarrollo_turistico' },
      { pattern: /video promocional|youtube/i, tag: 'video_promocional' },
      { pattern: /informacion turistica|oficina turismo/i, tag: 'informacion_turistica' },
      { pattern: /alojamiento|cabañas|hoteles/i, tag: 'alojamiento_opciones' },
      { pattern: /catastro|oferente|servicios/i, tag: 'catastro_emprendimientos' },
      { pattern: /reserva bellotos|cavernas/i, tag: 'reserva_bellotos_naturaleza' },
      { pattern: /mirador loros tricahue|aves/i, tag: 'mirador_loros_conservacion' },
      { pattern: /balneario machicura|playa/i, tag: 'balneario_machicura_actividades' },
      { pattern: /embalse machicura|aves/i, tag: 'embalse_machicura' },
      { pattern: /termas|aguas mineromedicinales/i, tag: 'termas_beneficios_salud' },
      { pattern: /poza mona|agua termal/i, tag: 'poza_mona_historia' },
      { pattern: /artesanos|nomina/i, tag: 'artesanos_locales' },
      { pattern: /actividades familiares|niños/i, tag: 'actividades_familiares' },
      { pattern: /seguridad|emergencia/i, tag: 'seguridad_emergencias' },
      { pattern: /transporte publico|moverse/i, tag: 'transporte_interno' },
      { pattern: /mejor epoca|visitar/i, tag: 'mejor_epoca_visita' },
      { pattern: /gastronomia|comida/i, tag: 'gastronomia_local' },
      { pattern: /compras|artesanias/i, tag: 'compras_artesanias' }
    ];

    for (const { pattern, tag } of patterns) {
      if (pattern.test(question) || pattern.test(answer)) {
        specificTags.push(tag);
      }
    }
    
    return specificTags;
  }
}

// Función para crear la colección de categorías
async function createCategoriesCollection() {
  const categoriesData = {
    'servicios_municipales': {
      name: 'Servicios Municipales',
      name_en: 'Municipal Services',
      icon: '🏛️',
      priority: 1,
      description: 'Información sobre servicios municipales',
      description_en: 'Information about municipal services',
      tags: [
        'municipalidad_horario', 'municipalidad_ubicacion', 'municipalidad_telefono',
        'veterinaria_municipal', 'servicios_publicos', 'contacto_municipalidad'
      ]
    },
    'tramites': {
      name: 'Trámites',
      name_en: 'Procedures',
      icon: '📋',
      priority: 2,
      description: 'Trámites y documentos municipales',
      description_en: 'Municipal procedures and documents',
      tags: [
        'licencia_conducir', 'permiso_circulacion', 'tramites_transito',
        'documentos_personales', 'requisitos_licencia'
      ]
    },
    'turismo': {
      name: 'Turismo',
      name_en: 'Tourism',
      icon: '🏔️',
      priority: 3,
      description: 'Atractivos turísticos y actividades',
      description_en: 'Tourist attractions and activities',
      tags: [
        'lago_colbun', 'termas_panimavida', 'termas_quinamavida', 'artesania_rari',
        'atractivos_turisticos', 'zoit_colbun', 'senderos_trekking', 'balneario_machicura',
        'destinos_turisticos', 'actividades_turismo'
      ]
    },
    'salud': {
      name: 'Salud',
      name_en: 'Health',
      icon: '🏥',
      priority: 4,
      description: 'Servicios de salud y emergencias',
      description_en: 'Health services and emergencies',
      tags: [
        'cesfam_colbun', 'cesfam_panimavida', 'postas_rurales',
        'horarios_salud', 'atencion_medica', 'servicios_salud'
      ]
    },
    'educacion': {
      name: 'Educación',
      name_en: 'Education',
      icon: '🎓',
      priority: 5,
      description: 'Establecimientos educacionales',
      description_en: 'Educational establishments',
      tags: [
        'establecimientos_educacionales', 'escuelas_rurales', 'liceo_colbun',
        'daem_contacto', 'educacion_municipal'
      ]
    },
    'emergencias': {
      name: 'Emergencias',
      name_en: 'Emergencies',
      icon: '🚨',
      priority: 6,
      description: 'Números de emergencia y seguridad',
      description_en: 'Emergency numbers and security',
      tags: [
        'numeros_emergencia', 'seguridad_ciudadana', 'urgencias_colbun',
        'carabineros_bomberos', 'contactos_emergencia'
      ]
    },
    'autoridades': {
      name: 'Autoridades',
      name_en: 'Authorities',
      icon: '👥',
      priority: 7,
      description: 'Información de autoridades municipales',
      description_en: 'Municipal authorities information',
      tags: [
        'alcalde_colbun', 'concejo_municipal', 'autoridades_municipales'
      ]
    },
    'informacion_general': {
      name: 'Información General',
      name_en: 'General Information',
      icon: 'ℹ️',
      priority: 8,
      description: 'Información general sobre Colbún',
      description_en: 'General information about Colbún',
      tags: [
        'historia_colbun', 'fundacion_comuna', 'mision_vision_municipal',
        'informacion_comunal', 'colbun_general'
      ]
    },
    'saludos_despedidas': {
      name: 'Saludos y Despedidas',
      name_en: 'Greetings and Farewells',
      icon: '👋',
      priority: 9,
      description: 'Interacciones básicas con el chatbot',
      description_en: 'Basic interactions with the chatbot',
      tags: [
        'saludo_inicial', 'presentacion_bot', 'despedida_final'
      ]
    }
  };

  try {
    console.log('📂 Creando colección de categorías...');
    
    for (const [categoryId, categoryData] of Object.entries(categoriesData)) {
      const categoryDoc = {
        ...categoryData,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      };
      
      await db.collection('categories').doc(categoryId).set(categoryDoc);
      console.log(`✅ Categoría creada: ${categoryData.name}`);
    }
    
    console.log('🎉 Colección de categorías creada exitosamente');
    return true;
  } catch (error) {
    console.error('❌ Error creando categorías:', error);
    return false;
  }
}

// Datos de FAQs originales (municipalidad)
function getMunicipalidadFAQs() {
  return [
    {
      question: "¿Cuál es el horario de atención de la municipalidad?",
      question_en: "What are the municipality office hours?",
      answer: "La Municipalidad de Colbún atiende de lunes a viernes de 08:30 a 14:00 horas. Está ubicada en Av. Adolfo Novoa #419, Colbún. Teléfono: +56 73 256 1100.",
      answer_en: "The Municipality of Colbún is open Monday to Friday from 08:30 to 14:00. Located at Av. Adolfo Novoa #419, Colbún. Phone: +56 73 256 1100.",
      category: "servicios_municipales",
      priority: 10,
      source_url: "https://municipalidadcolbun.cl/"
    },
    {
      question: "¿Quién es el alcalde de Colbún?",
      question_en: "Who is the mayor of Colbún?",
      answer: "El alcalde de Colbún es Pedro Pablo Muñoz Oses. Su mensaje destaca el trabajo para unir esfuerzos, promover inversión pública y privada, y convocar a la comunidad a participar en el desarrollo sustentable de la comuna.",
      answer_en: "The mayor of Colbún is Pedro Pablo Muñoz Oses. His message emphasizes working to unite efforts, promote public and private investment, and invite the community to participate in the sustainable development of the commune.",
      category: "autoridades",
      priority: 8,
      source_url: "https://municipalidadcolbun.cl/mensaje-del-alcalde/"
    },
    {
      question: "¿Cuál es la misión y visión de la Municipalidad de Colbún?",
      question_en: "What is the mission and vision of Colbún Municipality?",
      answer: "MISIÓN: Satisfacer las necesidades de la comunidad local y asegurar su participación en el progreso económico, social y cultural de la comuna. VISIÓN: Ser una comuna de interés turístico nacional e internacional, generando oportunidades que promuevan la participación e integración económica y social.",
      answer_en: "MISSION: To satisfy the needs of the local community and ensure their participation in the economic, social and cultural progress of the commune. VISION: To be a commune of national and international tourist interest, generating opportunities that promote economic and social participation and integration.",
      category: "informacion_general",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/mision-y-vision/"
    },
    {
      question: "¿Cómo puedo obtener mi licencia de conducir en Colbún?",
      question_en: "How can I get my driver's license in Colbún?",
      answer: "Debe solicitar presencialmente una hora de atención en el Departamento de Tránsito Municipal. Los requisitos varían según la clase de licencia. Para clase B: Cédula vigente, certificado de estudios (mínimo 8° básico), tener 18 años mínimo y $1.050 para certificado de antecedentes. Horario: Lunes a viernes 08:30-13:00 hrs. Teléfono: +56 73 256 1164.",
      answer_en: "You must request an appointment in person at the Municipal Transit Department. Requirements vary by license class. For class B: Valid ID, study certificate (minimum 8th grade), minimum 18 years old, and $1,050 for background check certificate. Hours: Monday to Friday 08:30-13:00. Phone: +56 73 256 1164.",
      category: "tramites",
      priority: 9,
      source_url: "https://municipalidadcolbun.cl/licencia-de-conducir/"
    },
    {
      question: "¿Dónde puedo renovar mi permiso de circulación?",
      question_en: "Where can I renew my vehicle registration?",
      answer: "Puede renovar su permiso de circulación en línea a través de https://colbunonline.cl/vue_pc/portal o presencialmente en la Dirección de Tránsito Municipal. Horario de atención presencial: lunes a viernes 08:30-13:00 hrs.",
      answer_en: "You can renew your vehicle registration online at https://colbunonline.cl/vue_pc/portal or in person at the Municipal Transit Directorate. In-person service hours: Monday to Friday 08:30-13:00.",
      category: "tramites",
      priority: 9,
      source_url: "https://colbunonline.cl/vue_pc/portal"
    },
    {
      question: "¿Dónde está ubicado el CESFAM de Colbún y cuáles son sus horarios?",
      question_en: "Where is the CESFAM of Colbún located and what are its hours?",
      answer: "El CESFAM Colbún está ubicado en Avda. Adolfo Novoa #419. Director: Fernando Cáceres Medina. Horario: lunes a viernes 08:30-14:00 hrs. Teléfonos: 73 235 1128 - 73 2630222. También existe el CESFAM Panimávida que atiende lunes a viernes 08:30-17:30 hrs.",
      answer_en: "CESFAM Colbún is located at Avda. Adolfo Novoa #419. Director: Fernando Cáceres Medina. Hours: Monday to Friday 08:30-14:00. Phones: 73 235 1128 - 73 2630222. There's also CESFAM Panimávida open Monday to Friday 08:30-17:30.",
      category: "salud",
      priority: 8,
      source_url: "https://municipalidadcolbun.cl/cesfam/"
    },
    {
      question: "¿Cuáles son las postas rurales disponibles en la comuna?",
      question_en: "What rural health posts are available in the commune?",
      answer: "La comuna cuenta con postas rurales en: Maule Sur (+56 992131461), Quinamávida (+56 982167203), Lomas de Putagán (+56 978371128), y La Floresta (+56 910094339). Todas atienden de lunes a viernes de 08:30 a 17:30 hrs.",
      answer_en: "The commune has rural health posts in: Maule Sur (+56 992131461), Quinamávida (+56 982167203), Lomas de Putagán (+56 978371128), and La Floresta (+56 910094339). All open Monday to Friday 08:30-17:30.",
      category: "salud",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/postas-rurales/"
    },
    {
      question: "¿Cuáles son los principales atractivos turísticos de Colbún?",
      question_en: "What are the main tourist attractions in Colbún?",
      answer: "Los principales atractivos incluyen: Lago Colbún (mayor embalse artificial de Chile), Termas de Panimávida y Quinamávida, Rari (artesanía en crin), petroglifos de Guaiquivilo, El Melado, volcanes San Pedro y San Pablo, Balneario Machicura, y múltiples senderos de trekking. La comuna es parte de la ZOIT Lago Colbún-Rari.",
      answer_en: "Main attractions include: Lake Colbún (Chile's largest artificial reservoir), Panimávida and Quinamávida Hot Springs, Rari (horsehair crafts), Guaiquivilo petroglyphs, El Melado, San Pedro and San Pablo volcanoes, Machicura Beach, and multiple trekking trails. The commune is part of ZOIT Lake Colbún-Rari.",
      category: "turismo",
      priority: 10,
      source_url: "https://visitacolbun.cl/"
    },
    {
      question: "¿Dónde puedo encontrar artesanía en crin de caballo?",
      question_en: "Where can I find horsehair crafts?",
      answer: "En la localidad de Rari, reconocida como 'Ciudad Artesanal del Mundo' por UNESCO. Las artesanas en crin son consideradas Tesoros Humanos Vivos y la localidad cuenta con denominación de origen. Rari se encuentra a pocos kilómetros de Panimávida, con múltiples talleres y puntos de venta a lo largo de sus calles.",
      answer_en: "In the town of Rari, recognized as 'World Craft City' by UNESCO. The horsehair artisans are considered Living Human Treasures and the locality has designation of origin. Rari is located a few kilometers from Panimávida, with multiple workshops and sales points along its streets.",
      category: "turismo",
      priority: 9,
      source_url: "https://visitacolbun.cl/Rari"
    },
    {
      question: "¿Qué actividades puedo realizar en el Lago Colbún?",
      question_en: "What activities can I do at Lake Colbún?",
      answer: "En el Lago Colbún puede realizar deportes acuáticos como kayak, stand up paddle, bicicleta acuática, pesca deportiva. El Balneario Machicura ofrece una playa de 150 metros con quinchos, baños, duchas, juegos infantiles y arriendo de equipos acuáticos. También hay senderos de trekking como Piedras Altas con vistas panorámicas.",
      answer_en: "At Lake Colbún you can do water sports like kayaking, stand up paddle, water biking, sport fishing. Machicura Beach offers a 150-meter beach with barbecue areas, bathrooms, showers, children's games and water equipment rental. There are also trekking trails like Piedras Altas with panoramic views.",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/LagoColbun"
    },
    {
      question: "¿Cuáles son los establecimientos educacionales de Colbún?",
      question_en: "What are the educational establishments in Colbún?",
      answer: "Colbún cuenta con: Escuela Básica de Colbún, Liceo Capitán Ignacio Carrera Pinto, y múltiples escuelas rurales en Panimávida, San Dionisio, Capilla Palacios, Santa Elena, San Juan, Los Boldos, Lomas de Putagán, La Floresta, La Guardia, Quinamávida, Paso Rari, Rari, y Maule Sur. Contacto DAEM: +56 73 256 1107.",
      answer_en: "Colbún has: Colbún Basic School, Capitán Ignacio Carrera Pinto High School, and multiple rural schools in Panimávida, San Dionisio, Capilla Palacios, Santa Elena, San Juan, Los Boldos, Lomas de Putagán, La Floresta, La Guardia, Quinamávida, Paso Rari, Rari, and Maule Sur. DAEM contact: +56 73 256 1107.",
      category: "educacion",
      priority: 8,
      source_url: "https://municipalidadcolbun.cl/establecimientos-educacionales/"
    },
    {
      question: "¿Cuáles son los números de emergencia en Colbún?",
      question_en: "What are the emergency numbers in Colbún?",
      answer: "Números de emergencia: Seguridad Ciudadana *4100, Urgencia Colbún: +56 956396622 / +56 732351067, Urgencia Panimávida: +56 732636870, Carabineros: 133, Bomberos: 132. La Seguridad Ciudadana municipal atiende 24 hrs continuas al +56 73 256 1157.",
      answer_en: "Emergency numbers: Citizen Security *4100, Colbún Emergency: +56 956396622 / +56 732351067, Panimávida Emergency: +56 732636870, Police: 133, Fire Department: 132. Municipal Citizen Security operates 24/7 at +56 73 256 1157.",
      category: "emergencias",
      priority: 10,
      source_url: "https://municipalidadcolbun.cl/seguridad-ciudadana/"
    },
    {
      question: "¿Dónde puedo llevar a mi mascota para esterilización o atención veterinaria?",
      question_en: "Where can I take my pet for sterilization or veterinary care?",
      answer: "La Veterinaria Municipal atiende de lunes a viernes de 08:30 a 17:00 hrs. Teléfono: +56 965754818. Ofrecen esterilización (previa inscripción), consultas, diagnóstico de enfermedades, atención de urgencias, operativos de desparasitación y vacunación antirrábica. Importante: gatos en jaula, perros con correa (bozal si son agresivos).",
      answer_en: "The Municipal Veterinary Clinic is open Monday to Friday 08:30-17:00. Phone: +56 965754818. They offer sterilization (prior registration), consultations, disease diagnosis, emergency care, deworming and rabies vaccination campaigns. Important: cats in cages, dogs on leash (muzzle if aggressive).",
      category: "servicios_municipales",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/veterinaria-municipal/"
    },
    {
      question: "¿Cuál es la historia de la fundación de Colbún?",
      question_en: "What is the history of Colbún's foundation?",
      answer: "Colbún fue fundado como comuna el 6 de mayo de 1906, aunque existen antecedentes de 1904. Originalmente el municipio se localizó en Panimávida, pero en 1927 se trasladó a Colbún por decreto de Carlos Ibáñez del Campo. El nombre 'Colbún' proviene del mapudungun y significa 'Cabeza de culebra' o 'Lugar sin árboles'.",
      answer_en: "Colbún was founded as a commune on May 6, 1906, although there are records from 1904. Originally the municipality was located in Panimávida, but in 1927 it was moved to Colbún by decree of Carlos Ibáñez del Campo. The name 'Colbún' comes from Mapudungun and means 'Snake's head' or 'Place without trees'.",
      category: "informacion_general",
      priority: 6,
      source_url: "https://municipalidadcolbun.cl/historia-de-la-comuna/"
    },
    {
      question: "¿Qué es la ZOIT Lago Colbún-Rari?",
      question_en: "What is the ZOIT Lake Colbún-Rari?",
      answer: "La ZOIT (Zona de Interés Turístico) Lago Colbún-Rari es una zona turística compartida entre las comunas de Colbún y San Clemente. Su visión es posicionarse como destino para turismo de naturaleza, aventura, deporte y tradición cultural, centrando al Lago Colbún como atractivo principal junto con la localidad de Rari.",
      answer_en: "The ZOIT (Zone of Tourist Interest) Lake Colbún-Rari is a tourist zone shared between the communes of Colbún and San Clemente. Its vision is to position itself as a destination for nature tourism, adventure, sport and cultural tradition, centering Lake Colbún as the main attraction along with the town of Rari.",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Zoit"
    },
    {
      question: "¿Cuándo se realizan las principales fiestas y eventos culturales de Colbún?",
      question_en: "When are the main festivals and cultural events of Colbún held?",
      answer: "Los principales eventos incluyen: Fiesta del Crin (enero), Fiesta de San Sebastián (enero), Trilla a Yegua Suelta (enero), Muestra de Artesanía y Folclor de Panimávida (enero-febrero), Carreras a la Chilena (marzo), Chancho al Humo en La Guardia (agosto), Fiesta de la Esquila, y La Noche de San Juan (única fiesta de invierno en la región).",
      answer_en: "Main events include: Horsehair Festival (January), San Sebastián Festival (January), Horse Threshing (January), Panimávida Crafts and Folklore Show (January-February), Chilean Races (March), Smoked Pig in La Guardia (August), Shearing Festival, and San Juan Night (only winter festival in the region).",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/Panoramas"
    },
  ];
}

// Datos de FAQs adaptados del JSON (turismo y general)
function getTurismoFAQs() {
  return [
    {
      question: "Hola",
      question_en: "Hello",
      answer: "¡Hola! Soy el asistente virtual de turismo de Colbún. Estoy aquí para ayudarte a descubrir los mejores destinos y atractivos turísticos de nuestra hermosa comuna en la Región del Maule. ¿En qué puedo ayudarte hoy?",
      answer_en: "Hello! I'm the virtual tourism assistant of Colbún. I'm here to help you discover the best destinations and tourist attractions of our beautiful commune in the Maule Region. How can I help you today?",
      category: "saludos_despedidas",
      priority: 10,
      source_url: "https://visitacolbun.cl/"
    },
    {
      question: "¿Qué es Colbún?",
      question_en: "What is Colbún?",
      answer: "Colbún es una comuna de la Región del Maule en Chile, conocida por su rica belleza natural, patrimonio cultural y tradiciones artesanales. Es famosa por sus termas, el lago Colbún (el mayor embalse artificial de Chile), las artesanas en crin de Rari, y sus paisajes cordilleranos únicos.",
      answer_en: "Colbún is a commune in the Maule Region of Chile, known for its rich natural beauty, cultural heritage and craft traditions. It is famous for its hot springs, Lake Colbún (Chile's largest artificial reservoir), the horsehair artisans of Rari, and its unique mountain landscapes.",
      category: "informacion_general",
      priority: 9,
      source_url: "https://municipalidadcolbun.cl/historia-de-la-comuna/"
    },
    {
      question: "¿Cómo llegar a Colbún?",
      question_en: "How to get to Colbún?",
      answer: "Puedes llegar a Colbún por la ruta L-11 desde Linares (16 km). La comuna está ubicada en la precordillera maulina y cuenta con acceso desde diferentes rutas dependiendo del destino específico que desees visitar dentro de la comuna.",
      answer_en: "You can reach Colbún via route L-11 from Linares (16 km). The commune is located in the Maule foothills and has access from different routes depending on the specific destination you want to visit within the commune.",
      category: "turismo",
      priority: 8,
      source_url: "https://municipalidadcolbun.cl/mapa/"
    },
    {
      question: "¿Qué lugares puedo visitar en Colbún?",
      question_en: "What places can I visit in Colbún?",
      answer: "Colbún ofrece múltiples destinos increíbles: El Melado (precordillera), Pehuenche (camino a la cordillera), Lago Colbún, Panimávida (pueblo termal histórico), Rari (artesanas en crin), Quinamávida (termas y artesanía), Los Bellotos, La Guardia, Colbún Alto, y muchos más lugares llenos de naturaleza y cultura.",
      answer_en: "Colbún offers multiple amazing destinations: El Melado (foothills), Pehuenche (on the way to the mountains), Lake Colbún, Panimávida (historic thermal town), Rari (horsehair artisans), Quinamávida (hot springs and crafts), Los Bellotos, La Guardia, Colbún Alto, and many more places full of nature and culture.",
      category: "turismo",
      priority: 10,
      source_url: "https://visitacolbun.cl/"
    },
    {
      question: "¿Qué puedo hacer en el Lago Colbún?",
      question_en: "What can I do at Lake Colbún?",
      answer: "El Lago Colbún es el mayor embalse artificial de Chile. Aquí puedes disfrutar de deportes acuáticos como kayak, stand up paddle, bicicleta acuática, pesca deportiva, y relajarte en sus riberas. El Balneario Machicura ofrece una playa de 150 metros con quinchos, juegos infantiles y arriendo de equipos acuáticos.",
      answer_en: "Lake Colbún is Chile's largest artificial reservoir. Here you can enjoy water sports like kayaking, stand up paddleboarding, water biking, sport fishing, and relax on its shores. Machicura Beach offers a 150-meter beach with barbecue areas, children's games and water equipment rental.",
      category: "turismo",
      priority: 9,
      source_url: "https://visitacolbun.cl/LagoColbun"
    },
    {
      question: "¿Qué es especial de Rari?",
      question_en: "What is special about Rari?",
      answer: "Rari es una localidad única donde las artesanas trabajan el crin de caballo desde hace más de 200 años. Han sido reconocidas como Tesoros Humanos Vivos, la localidad cuenta con denominación de origen y fue declarada Ciudad Artesanal del Mundo. Es un destino obligado para conocer esta tradición ancestral.",
      answer_en: "Rari is a unique town where artisans have been working with horsehair for over 200 years. They have been recognized as Living Human Treasures, the town has designation of origin and was declared a World Craft City. It's a must-visit destination to learn about this ancestral tradition.",
      category: "turismo",
      priority: 9,
      source_url: "https://visitacolbun.cl/Rari"
    },
    {
      question: "¿Qué eventos culturales se realizan en Colbún?",
      question_en: "What cultural events take place in Colbún?",
      answer: "Colbún tiene un rico calendario cultural: Fiesta del Crin (enero), Fiesta de San Sebastián (enero), Muestra de Artesanía y Folclore Panimávida, Fiesta de la Esquila, La Noche de San Juan (única fiesta de invierno regional), Chancho al Humo en La Guardia (agosto), Trilla a Yegua Suelta, entre muchas otras.",
      answer_en: "Colbún has a rich cultural calendar: Horsehair Festival (January), San Sebastián Festival (January), Panimávida Crafts and Folklore Show, Shearing Festival, San Juan Night (only regional winter festival), Smoked Pig in La Guardia (August), Horse Threshing, among many others.",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/Panoramas"
    },
    {
      question: "¿Qué fue el tren chico?",
      question_en: "What was the 'tren chico'?",
      answer: "El 'tren chico' fue el Ramal Linares-Colbún, operativo entre 1914 y 1956. Fue el principal medio de transporte de la época y motor del turismo en Panimávida. Contaba con 8 estaciones. En su honor se creó la Plaza del Tren Chico en Colbún, donde hay un vagón convertido en oficina turística.",
      answer_en: "The 'tren chico' was the Linares-Colbún branch line, operational between 1914 and 1956. It was the main means of transportation of the time and the engine of tourism in Panimávida. It had 8 stations. In its honor, the Tren Chico Square was created in Colbún, where there is a wagon converted into a tourist office.",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Cultura2"
    },
    {
      question: "¿Dónde puedo alojarme en Colbún?",
      question_en: "Where can I stay in Colbún?",
      answer: "Colbún cuenta con diversas opciones de alojamiento incluyendo las Termas de Panimávida (hotel termal con más de 90 habitaciones), Hotel Termas de Quinamávida, cabañas en diferentes localidades como Pehuenche, y campings. Puedes registrarte como oferente en visitacolbun.cl si tienes servicios de alojamiento.",
      answer_en: "Colbún has various accommodation options including the Panimávida Hot Springs (thermal hotel with over 90 rooms), Quinamávida Hot Springs Hotel, cabins in different towns like Pehuenche, and campsites. You can register as a provider at visitacolbun.cl if you have accommodation services.",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/Catastro"
    },
    {
      question: "Gracias",
      question_en: "Thank you",
      answer: "¡Ha sido un gusto ayudarte! Espero que disfrutes mucho tu visita a Colbún y descubras todos los maravillosos atractivos que nuestra comuna tiene para ofrecer. ¡Vuelve pronto!",
      answer_en: "It's been a pleasure to help you! I hope you enjoy your visit to Colbún and discover all the wonderful attractions that our commune has to offer. Come back soon!",
      category: "saludos_despedidas",
      priority: 5,
      source_url: "https://visitacolbun.cl/"
    },
    {
      question: "¿Qué puedo encontrar en Panimávida?",
      question_en: "",
      answer: "Panimávida es un pueblo histórico famoso por sus termas que datan de 1822. Fue capital comunal hasta 1923 y centro turístico importante del país. Hoy cuenta con complejos termales, la Iglesia Nuestra Señora de la Buena Esperanza (1913), una hermosa plaza con grandes árboles y monumentos históricos.",
      answer_en: "",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/Panimavida"
    },
    {
      question: "¿Qué atractivos tiene Quinamávida?",
      question_en: "",
      answer: "Quinamávida se destaca por sus termas reconocidas regionalmente, el trabajo artesanal en piedra toba volcánica, y la tradición del telar mapuche. Las artesanas mantienen viva la práctica del tejido en telar vertical (witral), creando mantas, ponchos y bolsos tradicionales.",
      answer_en: "",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/Quinamavida"
    },
    {
      question: "¿Qué puedo encontrar en El Melado?",
      question_en: "",
      answer: "El Melado es una localidad en la precordillera rodeada de montañas, ríos y vegetación exuberante. Es ideal para ecoturismo, conserva tradiciones arrieras, y ofrece paisajes perfectos para senderismo, pesca y avistamiento de flora y fauna. También alberga los famosos petroglifos de Guaiquivilo.",
      answer_en: "",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/ElMelado"
    },
    {
      question: "¿Qué ofrece Pehuenche?",
      question_en: "",
      answer: "Pehuenche está a 45 minutos de Colbún, camino a la cordillera. Ofrece un entorno de montañas, ríos, flora y fauna local, con amplia oferta de cabañas y campings. Preserva tradiciones arrieras y celebra festividades típicas como La Fiesta del Chivo.",
      answer_en: "",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/Paso-pehuenche"
    },
    {
      question: "¿Qué puedo hacer en Colbún Alto?",
      question_en: "",
      answer: "Colbún Alto se destaca por sus vistas panorámicas y cercanía al lago Colbún. Aquí la tranquilidad rural se combina con la naturaleza, ideal para senderismo, pesca, avistamiento de aves y para quienes buscan escapar del bullicio urbano en un entorno sereno.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Colbun-alto"
    },
    {
      question: "¿Qué actividades de senderismo puedo hacer?",
      question_en: "",
      answer: "Colbún ofrece excelentes rutas de senderismo: Volcán San Pedro y San Pablo (3600m), Laguna del Dial, Lagunas Verdes, Piedras Altas (cerca del lago), Mirador Las Vizcachas, Piedra del Indio en Rari, y acceso a la Reserva Nacional Los Bellotos con sus famosas cavernas.",
      answer_en: "",
      category: "turismo",
      priority: 8,
      source_url: "https://visitacolbun.cl/Senderismo"
    },
    {
      question: "¿Qué son los petroglifos de Guaiquivilo?",
      question_en: "",
      answer: "Los petroglifos de Guaiquivilo están ubicados en el cajón de Calabozos, El Melado. Son más de 900 dibujos inscritos en roca granítica que contienen figuras biomorfas, fitomorfas y zoomorfas. Constituyen uno de los yacimientos de Chile con más petroglifos concentrados en un lugar.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Senderismo"
    },
    {
      question: "¿Puedo visitar los volcanes San Pedro y San Pablo?",
      question_en: "",
      answer: "Los volcanes San Pedro y San Pablo alcanzan los 3600 metros de altura y están ubicados en la precordillera de Colbún, en el valle El Melado. Son estructuras geológicas poco conocidas debido a que no son visibles desde el valle central. El acceso es por la comuna de San Clemente.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Senderismo"
    },
    {
      question: "¿Cómo puedo llegar a las Lagunas Verdes?",
      question_en: "",
      answer: "Las Lagunas Verdes están ubicadas en el cajón del Achibueno, donde una alimenta a la otra. Desde El Melado son 5 días de caminata hasta la Laguna Cuéllar y después un día más para llegar. Se necesita equipo de alta montaña para esta expedición.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Senderismo2"
    },
    {
      question: "¿Qué puedo ver desde el Mirador Las Vizcachas?",
      question_en: "",
      answer: "El Mirador Las Vizcachas ofrece una vista exclusiva de todo el Valle de Rabones y Rari, desde donde se pueden observar vestigios del embalse Ancoa y las rutas del Achibueno. Es una caminata exigente de 2 horas y más de 10 kilómetros, pero la vista lo recompensa.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Senderismo4"
    },
    {
      question: "¿Qué son los Baños del Socorro?",
      question_en: "",
      answer: "Los Baños del Socorro son termas naturales rústicas ubicadas en la localidad del Melado, en el sector de Carrizales. Son aguas calientes con azufre que nacen de la cuenca Guaiquivilo. Se puede llegar en un día con implementos de trekking o acampar cerca de las termas.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Senderismo"
    },
    {
      question: "¿Qué parques y reservas puedo visitar?",
      question_en: "",
      answer: "Puedes visitar la Reserva Nacional Los Bellotos (417 hectáreas) famosa por proteger el belloto del sur en peligro de extinción y sus cavernas, y el Parque Guaiquivilo (proyecto privado de 8500 hectáreas) que se enfoca en preservar y difundir la naturaleza con diversa flora y fauna.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Los-Bellotos"
    },
    {
      question: "¿Qué es el Mirador Loros Tricahue?",
      question_en: "",
      answer: "El Mirador Loros Tricahue está en el sector Los Avellanos, Rabones. Es un punto de observación diseñado para la conservación del loro tricahue, especie en peligro crítico. Forma parte del Parque Natural Tricahue (2,000 hectáreas) y es resultado de un proyecto colaborativo entre la Municipalidad y la Fundación Putagán Libre.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Parque"
    },
    {
      question: "¿Qué ofrece el Balneario Machicura?",
      question_en: "",
      answer: "El Balneario Machicura está ubicado en la ribera sur poniente del embalse, cuenta con una playa de 150 metros ideal para deportes acuáticos como kayak, stand up paddle y bicicleta acuática. Ofrece quinchos, baños, duchas, juegos infantiles, locales comerciales, muelles y arriendo de equipos acuáticos.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Senderismo4"
    },
    {
      question: "¿Qué es el Embalse Machicura?",
      question_en: "",
      answer: "El Embalse Machicura es un cuerpo de agua artificial creado en 1985, más pequeño que el Lago Colbún con 8 km². Está muy cerca del centro de Colbún, cuenta con un balneario del mismo nombre, mirador de aves y es visitado diariamente por personas de la comuna y foráneas.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Termas"
    },
    {
      question: "¿Qué beneficios tienen las termas de Colbún?",
      question_en: "",
      answer: "Las termas de Colbún (Panimávida y Quinamávida) poseen aguas mineromedicinales con propiedades curativas, declaradas como tales por el Ministerio de Salud desde 1946. Ofrecen piscinas climatizadas, spa, tratamientos de belleza, y un entorno natural ideal para la relajación y el bienestar.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Termas"
    },
    {
      question: "¿Qué es la Poza de La Mona?",
      question_en: "",
      answer: "La Poza de La Mona es una de las fuentes de agua termal más conocidas de Panimávida, que emerge a 32°C. Durante décadas fue destino de peregrinación por sus propiedades curativas. Actualmente se mantiene cerrada, pero conserva su valor histórico y su estructura colonial.",
      answer_en: "",
      category: "turismo",
      priority: 6,
      source_url: "https://visitacolbun.cl/Cultura3"
    },
    {
      question: "¿Qué es la Fiesta del Chivo?",
      question_en: "",
      answer: "La Fiesta del Chivo es una festividad típica que se celebra en Pehuenche, donde se preservan tradiciones arrieras. Esta celebración está relacionada con la crianza de chivos, una actividad tradicional de la zona, junto con otras costumbres como el trabajo en lana.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Paso-pehuenche"
    },
    {
      question: "¿Dónde puedo encontrar artesanos locales?",
      question_en: "",
      answer: "Colbún cuenta con una nómina completa de artesanos locales que trabajan diferentes técnicas tradicionales como el crin en Rari, la piedra toba en Quinamávida, y el telar mapuche. Puedes encontrar la nómina completa de artesanos con sus contactos en el sitio web municipal.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/artesanos/"
    },
    {
      question: "¿Qué actividades hay para familias con niños?",
      question_en: "",
      answer: "Colbún ofrece múltiples actividades familiares: el Balneario Machicura con juegos infantiles, las termas con piscinas para toda la familia, caminatas suaves como Piedras Altas, visitas culturales a Rari para conocer artesanías, y los diversos eventos culturales durante el año.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Panoramas"
    },
    {
      question: "¿Cuáles son los números de emergencia en Colbún?",
      question_en: "",
      answer: "Números de emergencia en Colbún: Seguridad Ciudadana *4100, Urgencia Colbún 956396622 / 732351067, Urgencia Panimávida 732636870, Carabineros 133, Bomberos 132. La Seguridad Ciudadana opera las 24 horas continuas.",
      answer_en: "",
      category: "emergencias",
      priority: 10,
      source_url: "https://municipalidadcolbun.cl/seguridad-ciudadana/"
    },
    {
      question: "¿Cómo me muevo dentro de la comuna?",
      question_en: "",
      answer: "Para moverte dentro de Colbún, es recomendable contar con vehículo propio, especialmente para llegar a destinos como El Melado, Los Bellotos o rutas de senderismo. Algunos destinos en la precordillera requieren vehículos 4x4. El transporte público conecta principalmente los centros urbanos.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/mapa/"
    },
    {
      question: "¿Cuál es la mejor época para visitar Colbún?",
      question_en: "",
      answer: "Colbún se puede visitar todo el año. Primavera y verano son ideales para actividades acuáticas y senderismo. Otoño ofrece paisajes coloridos. Invierno es perfecto para termas y es la única época para disfrutar la Noche de San Juan. Cada estación tiene sus encantos particulares.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/Panoramas"
    },
    {
      question: "¿Qué servicios de salud hay disponibles?",
      question_en: "",
      answer: "Colbún cuenta con CESFAM Colbún (Lilian Plaza, directora) y CESFAM Panimávida (Marisol Navia, directora), además de postas rurales en Maule Sur, Quinamávida, Lomas de Putagán y La Floresta. El sistema está dividido en 4 sectores geográficos para mejor atención.",
      answer_en: "",
      category: "salud",
      priority: 8,
      source_url: "https://municipalidadcolbun.cl/cesfam/"
    },
    {
      question: "¿Qué establecimientos educacionales hay en Colbún?",
      question_en: "",
      answer: "Colbún cuenta con múltiples establecimientos: Escuela Básica de Colbún, Liceo Capitán Ignacio Carrera Pinto, escuelas rurales (Panimávida, San Dionisio, Santa Elena, etc.), y 6 jardines infantiles VTF JUNJI incluyendo Lincanrayen, Mis Primeros Pasos, y otros.",
      answer_en: "",
      category: "educacion",
      priority: 8,
      source_url: "https://municipalidadcolbun.cl/establecimientos-educacionales/"
    },
    {
      question: "¿Hay servicios veterinarios en Colbún?",
      question_en: "",
      answer: "Sí, Colbún cuenta con Veterinaria Municipal que ofrece consultas, diagnóstico de enfermedades, esterilización (previa inscripción), operativos de desparasitación y vacunación antirrábica, control de pulgas y garrapatas, y atención de urgencias como picaduras, atropellos e intoxicaciones.",
      answer_en: "",
      category: "servicios_municipales",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/veterinaria-municipal/"
    },
    {
      question: "¿Dónde puedo buscar trabajo en Colbún?",
      question_en: "",
      answer: "La OMIL (Oficina Municipal de Información Laboral) se encarga de la búsqueda de oferta laboral en la comuna, derivación de usuarios a ofertas, talleres de apresto laboral, asesoría para tramitar seguro de cesantía y difusión de capacitaciones SENCE.",
      answer_en: "",
      category: "servicios_municipales",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/omdel/"
    },
    {
      question: "¿Qué servicios ofrece OMDEL?",
      question_en: "",
      answer: "OMDEL ofrece múltiples programas: PRODESAL (asesoría a 389 usuarios), Programa Fomento Productivo, clínica veterinaria, programa de mujeres jefas de hogar, OMIL, oficina agrícola, programa pecuario y actividades como la Trilla a Yegua Suelta y Carreras a la Chilena.",
      answer_en: "",
      category: "servicios_municipales",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/omdel/"
    },
    {
      question: "¿Qué programas sociales ofrece la municipalidad?",
      question_en: "",
      answer: "DIDECO ofrece múltiples programas: Registro Social de Hogares, Subsidio de Agua Potable Rural, Chile Crece Contigo, Becas Municipales, Programa Vínculos (Adulto Mayor), Programa Habitabilidad, Familia Seguridades y Oportunidades, y otros beneficios sociales.",
      answer_en: "",
      category: "servicios_municipales",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/dideco/"
    },
    {
      question: "¿Qué actividades deportivas puedo realizar?",
      question_en: "",
      answer: "Colbún ofrece múltiples actividades deportivas: campeonatos de fútbol, tenis de mesa, ciclismo, senderismo, deportes acuáticos en el lago, y uso de gimnasio municipal. También se realizan eventos deportivos durante el año en diferentes localidades de la comuna.",
      answer_en: "",
      category: "servicios_municipales",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/deportes/"
    },
    {
      question: "¿Qué talleres culturales se ofrecen?",
      question_en: "",
      answer: "Colbún cuenta con diversos talleres culturales: danza, teatro, música, pintura, y otros. También ofrece biblioteca municipal con servicio de préstamo de libros y acceso a internet. Se realizan actividades culturales durante todo el año en diferentes localidades.",
      answer_en: "",
      category: "servicios_municipales",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/cultura/"
    },
    {
      question: "¿Dónde puedo comprar artesanías locales?",
      question_en: "",
      answer: "Puedes comprar artesanías directamente en Rari (artesanía en crin), Quinamávida (piedra toba y telar mapuche), y en las ferias artesanales locales. También en la oficina de turismo y durante los eventos culturales donde los artesanos exponen y venden sus productos.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/registrarse"
    },
    {
      question: "¿Qué opciones gastronómicas hay en Colbún?",
      question_en: "",
      answer: "Colbún ofrece diversas opciones gastronómicas: restaurantes en las termas, locales de comida típica, emprendimientos locales que ofrecen platos tradicionales, y durante eventos como la Fiesta del Chivo o Chancho al Humo se pueden degustar preparaciones típicas de la zona.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/registrarse"
    },
    {
      question: "¿Cómo contacto a la Municipalidad de Colbún?",
      question_en: "",
      answer: "La Municipalidad de Colbún está ubicada en Av. Adolfo Novoa N°419, Colbún. Teléfono: +56 73 256 1100. Horario de atención: Lunes a Viernes de 08:30 a 14:00 hrs. Email: info@municipalidadcolbun.cl. Web: municipalidadcolbun.cl",
      answer_en: "",
      category: "servicios_municipales",
      priority: 10,
      source_url: "https://municipalidadcolbun.cl/"
    },
    {
      question: "¿Cómo puedo registrar mi servicio turístico?",
      question_en: "",
      answer: "Si eres artesana/o, ofreces productos, servicios o tienes cabañas, puedes registrarte gratuitamente en el Catastro de Servicios de Colbún. Esto te permitirá visibilizar tu emprendimiento, conectar con clientes y formar parte de proyectos promocionales a nivel regional y nacional.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://visitacolbun.cl/registrarse"
    },
    {
      question: "¿Hay algún video promocional de Colbún?",
      question_en: "",
      answer: "Sí, puedes ver el video promocional 'Visita Colbún' que muestra la belleza y atractivos de la comuna. Este video te dará una excelente vista previa de todo lo que puedes encontrar y hacer en nuestros destinos turísticos.",
      answer_en: "",
      category: "turismo",
      priority: 6,
      source_url: "https://www.youtube.com/watch?v=7l3B_AjYnhI"
    },
    {
      question: "¿Dónde puedo obtener más información turística?",
      question_en: "",
      answer: "Puedes visitar la oficina turística ubicada en un vagón de tren en la Plaza del Tren Chico en Colbún, o contactar al Departamento de Turismo Municipal. También puedes visitar el sitio web visitacolbun.cl para información completa sobre destinos y actividades.",
      answer_en: "",
      category: "turismo",
      priority: 7,
      source_url: "https://municipalidadcolbun.cl/departamento-de-turismo/"
    }
    
  ];
}

// Combinar todos los FAQs
function getAllFAQs() {
  const municipalidadFAQs = getMunicipalidadFAQs();
  const turismoFAQs = getTurismoFAQs();
  
  return [...municipalidadFAQs, ...turismoFAQs];
}

function createFaqDocument(faqData, tagManager) {
  const tags = tagManager.generateTags(faqData.question, faqData.answer, faqData.category);
  
  return {
    question: faqData.question,
    question_en: faqData.question_en,
    answer: faqData.answer,
    answer_en: faqData.answer_en,
    category: faqData.category,
    priority: faqData.priority,
    source_url: faqData.source_url,
    tags: tags,
    embeddings: [],
    created_at: admin.firestore.FieldValue.serverTimestamp()
  };
}

async function uploadFaqsToFirestore() {
  const tagManager = new TagManager();
  const allFAQs = getAllFAQs();
  
  console.log(`Total de FAQs a procesar: ${allFAQs.length}`);
  
  // Dividir en batches de 500 (límite de Firestore)
  const batchSize = 500;
  let successCount = 0;
  
  try {
    for (let i = 0; i < allFAQs.length; i += batchSize) {
      const batch = db.batch();
      const batchFAQs = allFAQs.slice(i, i + batchSize);
      
      console.log(`Procesando batch ${Math.floor(i/batchSize) + 1} con ${batchFAQs.length} FAQs...`);
      
      for (const faqData of batchFAQs) {
        try {
          const faqDoc = createFaqDocument(faqData, tagManager);
          
          // ID personalizado basado en categoría y hash de la pregunta
          const questionHash = crypto.createHash('md5').update(faqData.question).digest('hex').substring(0, 8);
          const docId = `faq_${faqData.category}_${questionHash}`;
          const docRef = db.collection('faqs').doc(docId);
          
          batch.set(docRef, faqDoc);
          successCount++;
          
          console.log(`✓ Preparada FAQ: ${faqData.question.substring(0, 40)}...`);
          
        } catch (error) {
          console.error(`✗ Error preparando FAQ: ${faqData.question.substring(0, 30)}...`, error);
        }
      }
      
      // Ejecutar batch actual
      await batch.commit();
      console.log(`✅ Batch ${Math.floor(i/batchSize) + 1} completado`);
      
      // Pequeña pausa entre batches para evitar sobrecarga
      if (i + batchSize < allFAQs.length) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
    
    console.log(`\n🎉 PROCESO COMPLETADO EXITOSAMENTE`);
    console.log(`📊 Estadísticas:`);
    console.log(`   • FAQs procesadas: ${successCount}/${allFAQs.length}`);
    console.log(`   • Tags únicos generados: ${tagManager.usedTags.size}`);
    console.log(`   • Categorías utilizadas: ${[...new Set(allFAQs.map(f => f.category))].join(', ')}`);
    
    // Mostrar muestra de tags por categoría
    console.log(`\n🏷️  Muestra de tags por categoría:`);
    const tagsByCategory = {};
    allFAQs.forEach(faq => {
      if (!tagsByCategory[faq.category]) tagsByCategory[faq.category] = new Set();
      // Simular tags para esta demostración
      const simulatedTags = faq.question.toLowerCase().split(' ').filter(w => w.length > 3).slice(0, 3);
      simulatedTags.forEach(tag => tagsByCategory[faq.category].add(tag));
    });
    
    Object.entries(tagsByCategory).forEach(([category, tags]) => {
      console.log(`   ${category}: ${Array.from(tags).slice(0, 5).join(', ')}`);
    });
    
    return true;
    
  } catch (error) {
    console.error('❌ Error general en el proceso:', error);
    return false;
  }
}

// Función principal
async function main() {
  console.log('🚀 Iniciando configuración completa para firestore de Colbún...');
  console.log('═'.repeat(60));
  
  try {
    const startTime = Date.now();

    // 1. Crear coleccion de categorias
    console.log('📂 Paso 1: Creando colección de categorías...');
    const categoriesSuccess = await createCategoriesCollection();
    if (!categoriesSuccess) {
      console.log('❌ Falló la creación de categorías. Deteniendo proceso.');
      return;
    }

    // 2  Crear faqs
    console.log('\n📝 Paso 2: Creando FAQs...');
    const faqsSuccess = await uploadFaqsToFirestore();
    
    const endTime = Date.now();
    
    console.log('═'.repeat(60));
    
     
    if (faqsSuccess) {
      console.log(`✅ Proceso completado en ${((endTime - startTime) / 1000).toFixed(2)} segundos`);
      console.log('📍 Categorías y FAQs disponibles en Firestore');
      console.log('\n🎯 Para usar en Flutter:');
      console.log('   • Consulta categorías: db.collection("categories").orderBy("priority")');
      console.log('   • Consulta FAQs por categoría: db.collection("faqs").where("category", "==", "turismo")');
      console.log('   • Búsqueda combinada: Usa tags de categoría + tags de FAQ');
    } else {
      console.log('❌ El proceso de FAQs falló');
    }

  } catch (error) {
    console.error('💥 Error en main:', error);
  } finally {
    process.exit();
  }
}

// Ejecutar script
main();