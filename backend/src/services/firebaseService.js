import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Buscar el archivo (intentamos con las dos extensiones por si acaso)
let serviceAccount;
try {
  const keyPath = path.join(__dirname, '../../serviceAccountKey.json');
  serviceAccount = JSON.parse(readFileSync(keyPath, 'utf-8'));
} catch (e) {
  try {
    const keyPathFallback = path.join(__dirname, '../../serviceAccountKey.json.json');
    serviceAccount = JSON.parse(readFileSync(keyPathFallback, 'utf-8'));
  } catch (err) {
    console.error("Error al cargar serviceAccountKey:", err);
  }
}

if (serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('🔥 Firebase Admin inicializado correctamente.');
}

/**
 * Envia una notificación push a todos los dispositivos suscritos
 * al tema 'biodiversity_updates'.
 */
export async function sendNotificationToAll(title, body, additionalData = {}) {
  if (!serviceAccount) {
    console.warn('⚠️ No se puede enviar la notificación: Firebase no está inicializado.');
    return;
  }

  const message = {
    notification: {
      title,
      body,
    },
    android: {
      priority: "high"
    },
    data: additionalData,
    topic: 'biodiversity_updates'
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notificación enviada con éxito al Topic:', response);
    return response;
  } catch (error) {
    console.error('❌ Error enviando notificación Push al Topic:', error);
  }
}

/**
 * Envia una notificación push directamente a un token específico (para pruebas).
 */
export async function sendNotificationToToken(token, title, body, additionalData = {}) {
  if (!serviceAccount) return;

  const message = {
    notification: {
      title,
      body,
    },
    android: {
      priority: "high"
    },
    data: additionalData,
    token: token
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notificación enviada con éxito al Token:', response);
    return response;
  } catch (error) {
    console.error('❌ Error enviando notificación al Token:', error);
  }
}
