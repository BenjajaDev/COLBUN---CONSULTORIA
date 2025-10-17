// Reemplaza TODO el contenido de tu index.js con este código corregido

const functions = require("firebase-functions");
const https = require("https");

// Usamos el método moderno y seguro para manejar secretos en Firebase.
// Asegúrate de haberlo configurado con:
// firebase functions:secrets:set OPENAI_API_KEY
const {defineString} = require("firebase-functions/params");
const openaiApiKey = defineString("OPENAI_API_KEY");

const OPENAI_API_HOST = "api.openai.com";
const OPENAI_API_PATH = "/v1/chat/completions";

/**
 * Actúa como un proxy seguro para las llamadas a la API de OpenAI.
 * Recibe la petición desde la app web de Flutter, añade la API Key
 * en el servidor y reenvía la petición a OpenAI.
 */
exports.openAIProxy = functions.https.onRequest((req, res) => {
  // Configura los encabezados CORS para permitir que tu app web llame.
  // Para mayor seguridad en producción, puedes reemplazar "*"
  // con el dominio de tu app web (ej: "https://tu-proyecto.web.app").
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  // El navegador envía una petición "pre-vuelo" (OPTIONS) para CORS.
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Solo aceptamos peticiones POST.
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  // Opciones para la llamada a la API de OpenAI.
  const options = {
    hostname: OPENAI_API_HOST,
    path: OPENAI_API_PATH,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      // Aquí se inserta la clave API de forma segura.
      "Authorization": `Bearer ${openaiApiKey.value()}`,
    },
  };

  // Creamos la petición hacia la API de OpenAI.
  const apiRequest = https.request(options, (apiResponse) => {
    let data = "";
    apiResponse.on("data", (chunk) => {
      data += chunk;
    });
    apiResponse.on("end", () => {
      // Devolvemos la respuesta de OpenAI a la app de Flutter.
      res.status(apiResponse.statusCode).send(data);
    });
  });

  apiRequest.on("error", (error) => {
    console.error("Error al llamar a la API de OpenAI:", error);
    res.status(500).send({error: "Failed to communicate with OpenAI API"});
  });

  // Pasamos el cuerpo de la petición de Flutter directamente a OpenAI.
  apiRequest.write(JSON.stringify(req.body));
  apiRequest.end();
});