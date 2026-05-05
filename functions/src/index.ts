import { onRequest } from "firebase-functions/v2/https";
import { defineString, defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import app from "./app";

// Initialize Firebase
if (!admin.apps.length) {
  admin.initializeApp();
}

// Params
const REGION = defineString("REGION", { default: "us-central1" });
const JWT_SECRET = defineSecret("JWT_SECRET");

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