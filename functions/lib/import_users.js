"use strict";
/**
 * import_users.ts
 * Run once to bulk-create Firebase Authentication users from a JSON list.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const admin = __importStar(require("firebase-admin"));
const fs = __importStar(require("fs"));
// Initialize Firebase Admin SDK
admin.initializeApp({
    credential: admin.credential.cert(require("../serviceAccountKey.json") // adjust path if needed
    ),
});
async function importUsers() {
    try {
        const users = JSON.parse(fs.readFileSync("./users.json", "utf8"));
        for (const u of users) {
            try {
                await admin.auth().createUser({
                    email: u.email,
                    password: u.password,
                });
                console.log(`✅ Added: ${u.email}`);
            }
            catch (err) {
                console.error(`❌ Error adding ${u.email} - ${err.message}`);
            }
        }
        console.log("\n🎉 Import complete!");
        process.exit(0);
    }
    catch (err) {
        console.error("Failed to read or process users.json:", err);
    }
}
importUsers();
//# sourceMappingURL=import_users.js.map