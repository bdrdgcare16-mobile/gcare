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

// Scheduled monitors live in their own modules; re-exported so
// `firebase deploy` picks them up alongside the HTTP api function.
// NOTE: schedulers/payrollScheduler and triggers/attendanceTracking are
// intentionally NOT exported - they have never been deployed, and
// enabling them changes production behavior outside this change's scope.
export { trackingHeartbeatMonitor } from './schedulers/trackingHeartbeat';

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