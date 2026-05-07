import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import path from 'path';

dotenv.config();

// Para fins de desenvolvimento local, o arquivo serviceAccount.json deve ser gerado no Firebase Console.
// Coloque ele na raiz do backend (backend/serviceAccount.json)
try {
  const serviceAccount = require(path.join(__dirname, '..', 'serviceAccount.json'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin inicializado com serviceAccount.json');
} catch (e) {
  console.warn('⚠️ serviceAccount.json não encontrado. Tentando Application Default Credentials...');
  admin.initializeApp();
}

export const db: admin.firestore.Firestore = admin.firestore();
export const auth: admin.auth.Auth = admin.auth();
