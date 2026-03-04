"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.storage = exports.auth = exports.db = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const storage_1 = require("firebase-admin/storage");
// NOTE:
// - Do NOT use firebase-functions Params here (no defineString / .value() at module load).
// - Rely on ADC in production. In local dev, use serviceAccountKey.json if present.
let appInitialized = false;
if (!(0, app_1.getApps)().length) {
    let options;
    // Prefer explicit service account when available locally
    try {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const serviceAccount = require('../../serviceAccountKey.json');
        options = {
            credential: (0, app_1.cert)(serviceAccount),
            storageBucket: process.env.APP_STORAGE_BUCKET ||
                (process.env.GCLOUD_PROJECT ? `${process.env.GCLOUD_PROJECT}.appspot.com` : undefined),
        };
    }
    catch {
        // Fall back to Application Default Credentials (Functions/Cloud Run)
        options = {
            credential: (0, app_1.applicationDefault)(),
            storageBucket: process.env.APP_STORAGE_BUCKET ||
                (process.env.GCLOUD_PROJECT ? `${process.env.GCLOUD_PROJECT}.appspot.com` : undefined),
        };
    }
    (0, app_1.initializeApp)(options);
    appInitialized = true;
}
// Expose Admin services
exports.db = (0, firestore_1.getFirestore)();
exports.auth = (0, auth_1.getAuth)();
exports.storage = (0, storage_1.getStorage)();
// Firestore recommended setting to ignore undefined fields
exports.db.settings({ ignoreUndefinedProperties: true });
// Helpful log in dev
if (appInitialized) {
    // eslint-disable-next-line no-console
    console.log('[firebase] Admin initialized. Bucket:', exports.storage.bucket().name);
}
exports.default = { db: exports.db, auth: exports.auth, storage: exports.storage };
//# sourceMappingURL=firebase.js.map