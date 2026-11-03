const admin = require('firebase-admin');

/**
 * Initialize Firebase Admin SDK
 * Supports:
 * 1. FIREBASE_SERVICE_ACCOUNT_JSON (Render secret environment variable containing full JSON string)
 * 2. Individual env variables (FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY)
 * 3. Default Application Credentials (GOOGLE_APPLICATION_CREDENTIALS file path)
 */
function initFirebase() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  let credential;

  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const parsed = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      credential = admin.credential.cert(parsed);
      console.log('[FirebaseAdmin] Initialized using FIREBASE_SERVICE_ACCOUNT_JSON');
    } catch (err) {
      console.error('[FirebaseAdmin] Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON:', err.message);
      throw new Error('Invalid FIREBASE_SERVICE_ACCOUNT_JSON environment variable');
    }
  } else if (process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
    credential = admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID || 'bright-future-classes-ca39a',
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: privateKey,
    });
    console.log('[FirebaseAdmin] Initialized using individual environment variables');
  } else {
    // Falls back to Google Application Default Credentials or existing gcloud login
    credential = admin.credential.applicationDefault();
    console.log('[FirebaseAdmin] Initialized using applicationDefault credential');
  }

  return admin.initializeApp({
    credential,
    projectId: process.env.FIREBASE_PROJECT_ID || 'bright-future-classes-ca39a',
  });
}

const app = initFirebase();
const auth = admin.auth(app);
const db = admin.firestore(app);

module.exports = {
  admin,
  auth,
  db,
};
