import admin from 'firebase-admin';
import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

let initialized = false;
export function initFirebase() {
  if (initialized) return admin;

  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (credPath && existsSync(credPath)) {
    const serviceAccount = JSON.parse(readFileSync(credPath, 'utf8'));
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  } else {
    // Demo / local dev: in-memory mock — replace with real credentials for production
    console.warn(
      '[al-asel] No GOOGLE_APPLICATION_CREDENTIALS — using demo project id only. Set credentials for Firestore.'
    );
    try {
      admin.initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID || 'al-asel-demo' });
    } catch (e) {
      if (!e.message?.includes('already exists')) throw e;
    }
  }
  initialized = true;
  return admin;
}

export function getDb() {
  initFirebase();
  return admin.firestore();
}

export { admin };
