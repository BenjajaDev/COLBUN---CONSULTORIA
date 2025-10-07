const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {OpenAI} = require("openai");

// Define el parámetro para tu clave secreta de OpenAI
// Asegúrate de haberla configurado en Firebase con:
// firebase functions:secrets:set OPENAI_API_KEY
const {defineString} = require("firebase-functions/params");
const openaiApiKey = defineString("OPENAI_API_KEY");

// Inicializa Firebase Admin para poder acceder a Firestore
admin.initializeApp();
const db = admin.firestore();

/**
 * Busca en Firestore las FAQs más relevantes para el mensaje del usuario.
 * @param {string} userMessage El mensaje del usuario.
 * @return {Promise<Array>} Una lista de objetos FAQ encontrados.
 */
async function findContextFaqs(userMessage) {
  console.log(`Buscando FAQs para el mensaje: "${userMessage}"`);
  try {
    const faqsCollection = db.collection("faqs");
    const snapshot = await faqsCollection.get();

    if (snapshot.empty) {
      console.log("No se encontraron FAQs en la colección.");
      return [];
    }

    const allFaqs = [];
    snapshot.forEach((doc) => {
      allFaqs.push({id: doc.id, ...doc.data()});
    });

    const searchTerms = userMessage.toLowerCase().split(/\s+/);
    const relevantFaqs = allFaqs.filter((faq) => {
      const question = (faq.question || "").toLowerCase();
      const answer = (faq.answer || "").toLowerCase();
      const tags = (faq.tags || []).join(" ").toLowerCase();

      return searchTerms.some(
          (term) =>
            question.includes(term) ||
            answer.includes(term) ||
            tags.includes(term),
      );
    });

    console.log(`Se encontraron ${relevantFaqs.length} FAQs relevantes.`);
    return relevantFaqs;
  } catch (error) {
    console.error("Error al buscar FAQs en Firestore:", error);
    return [];
  }
}

/**
 * Esta es nuestra función de 1ª Generación con toda la lógica del chatbot.
 */
exports.whatsappWebhookGen1 = functions.https.onRequest(async (req, res) => {
  const openai = new OpenAI({
    apiKey: openaiApiKey.value(),
  });

  const userMessage = req.body.Body;
  if (!userMessage) {
    res.status(200).send("<Response/>");
    return;
  }

  console.log(`Mensaje recibido: "${userMessage}"`);

  try {
    const contextFaqs = await findContextFaqs(userMessage);

    const faqContextText = contextFaqs
        .map(
            (faq) =>
              `Pregunta: ${faq.question}\nRespuesta: ${faq.answer}\nLink: ${
                faq.link || "No disponible"
              }`,
        )
        .join("\n\n---\n\n");

    const systemPrompt = `
      Eres el asistente virtual de Colbún. Tu personalidad es amigable.
      Tu misión es responder basándote PRINCIPALMENTE en el siguiente
      contexto. Si la respuesta está en el contexto, úsala. Si no,
      responde que solo puedes dar información sobre Colbún.
      Si el contexto incluye un link, proporciónalo al final.

      --- CONTEXTO DE PREGUNTAS FRECUENTES ---
      ${faqContextText}
      --- FIN DEL CONTEXTO ---
    `;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {role: "system", content: systemPrompt},
        {role: "user", content: userMessage},
      ],
    });

    const botResponse = completion.choices[0].message.content;

    const twiml = `
      <Response>
        <Message>
          <Body>${botResponse}</Body>
        </Message>
      </Response>
    `;

    res.set("Content-Type", "text/xml");
    res.status(200).send(twiml);
  } catch (error) {
    console.error("Error procesando el mensaje con IA:", error);
    const errorResponse = `
      <Response>
        <Message>
          <Body>Lo siento, tuve un problema para procesar tu solicitud.
          Intenta de nuevo.</Body>
        </Message>
      </Response>
    `;
    res.set("Content-Type", "text/xml");
    res.status(200).send(errorResponse);
  }
});
