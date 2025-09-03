const fs = require('fs');
const path = require('path');

// Your Firebase Admin SDK service account key
const serviceAccount = {
  "type": "service_account",
  "project_id": "servappbackend",
  "private_key_id": process.env.FIREBASE_PRIVATE_KEY_ID,
  "private_key": process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  "client_email": "firebase-adminsdk-fbsvc@servappbackend.iam.gserviceaccount.com",
  "client_id": process.env.FIREBASE_CLIENT_ID,
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40servappbackend.iam.gserviceaccount.com"
};

// Ensure the functions directory exists
const functionsDir = path.join(__dirname, '../functions');
if (!fs.existsSync(functionsDir)) {
  fs.mkdirSync(functionsDir, { recursive: true });
}

// Write the service account key to a file
const serviceAccountPath = path.join(functionsDir, 'serviceAccountKey.json');
fs.writeFileSync(serviceAccountPath, JSON.stringify(serviceAccount, null, 2));

console.log('Firebase Admin SDK service account key has been created at:', serviceAccountPath);
console.log('IMPORTANT: Add serviceAccountKey.json to your .gitignore file!');
