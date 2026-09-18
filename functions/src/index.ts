import { onRequest } from "firebase-functions/v2/https";
import { onInit } from "firebase-functions/v2/core";
import { defineString, defineSecret } from "firebase-functions/params";
import app from "./app";
import { checkRequiredEnv } from "./config/envCheck";

// Params
const REGION = defineString("REGION", { default: "us-central1" });
const JWT_SECRET = defineSecret("JWT_SECRET");

// Runtime configuration validation.
//
// onInit() registers a callback that the Firebase Functions runtime
// executes once, lazily, before the first function invocation in
// production — never at module-import time and never during export
// discovery. This guarantees:
//   - Export discovery completes before .env values are injected.
//   - The check runs before any service (Firestore, Auth, Storage, FCM)
//     is touched, because those services are only initialised inside
//     request handlers via the lazy getters in config/firebase.ts.
//   - No secret values are printed — only missing key names are reported.
onInit(() => {
  const result = checkRequiredEnv();
  if (!result.ok) {
    throw new Error(
      `Missing required production configuration: ${result.missing.join(", ")}`
    );
  }
});

// Export function
export const api = onRequest(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: "1GiB",
    minInstances: 0,
    maxInstances: 10,
    secrets: [JWT_SECRET],
  },
  app
);