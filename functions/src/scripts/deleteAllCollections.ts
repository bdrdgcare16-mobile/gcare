import * as admin from "firebase-admin";
import * as path from "path";

const serviceAccountPath = path.resolve(__dirname, "../../serviceAccountKey.json");
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id,
});

const db = admin.firestore();

async function deleteCollection(collectionName: string) {
  while (true) {
    const snapshot = await db.collection(collectionName).limit(200).get();

    if (snapshot.empty) {
      console.log(`${collectionName} is empty or fully deleted`);
      break;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${snapshot.size} docs from ${collectionName}`);
  }
}

async function deleteAllCollections() {
  try {
    const collections = [
      "attendance",
      "companyProfile",
      "employees",
      "events",
      "feedbacks",
      "leave_types",
      "leaves",
      "officeLocations",
      "otherLocation",
      "password_resets",
      "reason_types",
      "reasons",
      "rewards",
      "shifts",
      "staticContent",
      "tasks",
      "tracking",
      "users",
    ];

    for (const collection of collections) {
      console.log(`\nDeleting collection: ${collection}`);
      await deleteCollection(collection);
    }

    console.log("\nAll collections deleted successfully");
    process.exit(0);
  } catch (error) {
    console.error("Error deleting collections:", error);
    process.exit(1);
  }
}

deleteAllCollections();