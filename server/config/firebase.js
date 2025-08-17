// // // const admin = require('firebase-admin');
// // // const serviceAccount = require('./serviceAccountKey.json');

// // // admin.initializeApp({
// // //   credential: admin.credential.cert(serviceAccount),
// // //   storageBucket: "<your-project-id>.appspot.com", // Optional for logo
// // // });

// // // const db = admin.firestore();
// // // module.exports = db;

// // const admin = require('firebase-admin');
// // const serviceAccount = require('./serviceAccountKey.json');

// // admin.initializeApp({
// //   credential: admin.credential.cert(serviceAccount),
// //   storageBucket: "<your-project-id>.appspot.com", // Optional for logo
// // });

// // const db = admin.firestore();
// // module.exports = db;
// const admin = require('firebase-admin');
// const serviceAccount = require('./serviceAccountKey.json'); // Path to your Firebase service account key

// // Initialize Firebase Admin SDK
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
// });

// const db = admin.firestore(); // Get Firestore instance

// module.exports = { db }; // Export Firestore instance to be used in other files

const admin = require('firebase-admin');

// Path to your Firebase service account key
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // Uncomment below if you plan to use Firebase Storage
  // storageBucket: "<your-project-id>.appspot.com",
});

// Get Firestore instance
const db = admin.firestore();

// Export the Firestore instance to be used in other files
module.exports = { db };
