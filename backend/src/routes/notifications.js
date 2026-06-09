import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler.js';
import { sendNotificationToAll, sendNotificationToToken } from '../services/firebaseService.js';

export const notificationsRouter = Router();

// Ruta para pruebas directas a un dispositivo específico
notificationsRouter.post(
  '/test',
  asyncHandler(async (req, res) => {
    const { token, title, body, data } = req.body;
    
    if (!token) {
      return res.status(400).json({ success: false, error: 'Token is required' });
    }

    const response = await sendNotificationToToken(token, title, body, data);
    res.json({ success: true, message: 'Notificación enviada', response });
  })
);

// Ruta Oficial de Webhook (Para disparar cuando se apruebe una observación en ODK/iNat)
notificationsRouter.post(
  '/broadcast',
  asyncHandler(async (req, res) => {
    const { title, body, data } = req.body;
    
    // Aquí puedes agregar seguridad en el futuro (ej. un API Key o Token secreto)
    // para evitar que cualquiera pueda mandar notificaciones públicas.

    // Transmitir a todos los dispositivos suscritos a 'biodiversity_updates'
    const response = await sendNotificationToAll(title || 'Nueva Observación', body || 'Se ha registrado una nueva especie en el mapa.', data);
    res.json({ success: true, message: 'Notificación masiva enviada', response });
  })
);
