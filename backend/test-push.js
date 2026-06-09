import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import path from 'path';

const serviceAccount = JSON.parse(readFileSync('./serviceAccountKey.json', 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const message = {
  token: "dlEJ2_qERZuUKO2L1zWqNH:APA91bHZb6RTojh3QIavYdjNoO-xsdohK7IR36ANjuGcc886c_1b6TRM2x2EnaNHiEmEHm5m3tiPmlI0KlBpaVTwD3c49IWg92seGMZTYQmGCAIP1Qk7vTE",
  notification: {
    title: "Prueba cruda",
    body: "Mensaje desde script aislado"
  }
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Successfully sent message:', response);
    process.exit(0);
  })
  .catch((error) => {
    console.log('Error sending message:', error);
    process.exit(1);
  });
