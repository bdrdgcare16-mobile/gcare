import { db, auth } from "../config/firebase";
import * as bcrypt from "bcryptjs";
import { decryptCredential } from "./onboardingCredential.service";
import { checkUserLimit } from "./entitlementService";

const EMPLOYEES = "employees";
const USERS = "users";
const ONBOARDING = "employee_onboarding_dev";

/**
 * Error with an HTTP status so the controller can map provisioning
 * failures deterministically (400 validation / 403 entitlement / 409 dup).
 */
export class ProvisioningError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly code?: string
  ) {
    super(message);
  }
}

export interface ProvisionResult {
  employeeDocId: string;
  userId: string;
  firebaseUid: string | null;
  tempPassword: string | null; // null when the record was already provisioned
  alreadyProvisioned: boolean;
}

const norm = (v: any) => String(v ?? "").trim();
const normEmail = (v: any) => norm(v).toLowerCase();

/**
 * V2 employee provisioning — called when a Company Admin approves an
 * onboarding request. Creates the canonical `employees` master record,
 * a linked `users` login record (bcrypt temp password, mustChangePassword),
 * and a Firebase Auth identity (created or linked by email).
 *
 * Idempotent: if the onboarding doc already carries linkage fields the
 * existing records are returned unchanged — repeated approval is safe.
 */
export async function provisionEmployeeFromOnboarding(
  onboardingId: string,
  data: any,
  companyId: string,
  actorId: string
): Promise<ProvisionResult> {
  const personal = data.personalDetails ?? {};
  const company = data.companyDetails ?? {};

  const empid = norm(company.employeeId);
  const email = normEmail(company.officialEmail || personal.personalEmail);
  const name = norm(personal.fullName);

  if (!empid || !email || !name) {
    throw new ProvisioningError(
      400,
      "Onboarding record is missing employeeId, email or fullName"
    );
  }

  // Idempotent retry: approval already completed for this onboarding.
  // Still verify the Firebase Auth identity — if it is gone (e.g. the Auth
  // emulator restarted and dropped users) recreate it from the stored
  // encrypted credential so the employee can actually log in.
  if (data.employeeDocId && data.userId) {
    let firebaseUid: string | null = data.firebaseUid
      ? String(data.firebaseUid)
      : null;
    try {
      await auth.getUserByEmail(email);
    } catch {
      const encCred = String(data.initialPasswordEnc ?? "");
      if (!encCred) {
        throw new ProvisioningError(
          400,
          "Employee record exists but no stored credential is available to repair the login — resubmit the onboarding form.",
          "NO_STORED_CREDENTIAL"
        );
      }
      let pw: string;
      try {
        pw = decryptCredential(encCred);
      } catch {
        throw new ProvisioningError(
          400,
          "The stored employee password could not be read — resubmit the onboarding form.",
          "BAD_STORED_CREDENTIAL"
        );
      }
      const created = await auth.createUser({
        email,
        password: pw,
        displayName: name,
      });
      firebaseUid = created.uid;
      await db
        .collection(USERS)
        .doc(String(data.userId))
        .set({ firebaseUid, updatedAt: new Date() }, { merge: true });
      await db
        .collection(ONBOARDING)
        .doc(onboardingId)
        .set({ firebaseUid, updatedAt: new Date() }, { merge: true });
    }
    return {
      employeeDocId: String(data.employeeDocId),
      userId: String(data.userId),
      firebaseUid,
      tempPassword: null,
      alreadyProvisioned: true,
    };
  }

  // Duplicate checks (all scoped to the authenticated company, except
  // users.emailLower which is global per the existing auth rules).
  const [empById, empByEmail, userByEmail, userByEmpid] = await Promise.all([
    db.collection(EMPLOYEES)
      .where("companyId", "==", companyId)
      .where("empid", "==", empid)
      .limit(1)
      .get(),
    db.collection(EMPLOYEES)
      .where("companyId", "==", companyId)
      .where("emailLower", "==", email)
      .limit(1)
      .get(),
    db.collection(USERS).where("emailLower", "==", email).limit(1).get(),
    db.collection(USERS)
      .where("companyId", "==", companyId)
      .where("empid", "==", empid)
      .limit(1)
      .get(),
  ]);

  if (!empById.empty) {
    const existing = empById.docs[0].data() as any;
    if (existing.onboardingId === onboardingId) {
      // Same onboarding re-approved after a partial failure — reuse the
      // employee record and continue to ensure the users record exists.
    } else {
      throw new ProvisioningError(
        409,
        "Employee ID already exists for this company",
        "DUPLICATE_EMPID"
      );
    }
  }
  if (!empByEmail.empty) {
    const existing = empByEmail.docs[0].data() as any;
    if (existing.onboardingId !== onboardingId) {
      throw new ProvisioningError(
        409,
        "Email already exists for this company",
        "DUPLICATE_EMAIL"
      );
    }
  }
  if (!userByEmail.empty) {
    throw new ProvisioningError(
      409,
      "A login account already exists for this email",
      "DUPLICATE_LOGIN"
    );
  }
  if (!userByEmpid.empty) {
    throw new ProvisioningError(
      409,
      "A login account already exists for this employee ID",
      "DUPLICATE_LOGIN_EMPID"
    );
  }

  // Company entitlement / max-user enforcement (same rules as V1 create).
  const limit = await checkUserLimit(companyId);
  if (limit.lookupFailed) {
    throw new ProvisioningError(
      503,
      "Could not verify company entitlements. Please try again.",
      "ENTITLEMENT_UNAVAILABLE"
    );
  }
  if (!limit.companyExists || limit.companyStatus !== "active") {
    throw new ProvisioningError(
      403,
      "Company account is not active.",
      "COMPANY_NOT_ACTIVE"
    );
  }
  if (!limit.allowed) {
    throw new ProvisioningError(
      403,
      "Maximum user limit reached for this company.",
      "MAX_USERS_REACHED"
    );
  }

  // Employee password: supplied by HR at onboarding submission and stored
  // AES-256-GCM encrypted on the record — decrypted only here, hashed with
  // bcrypt for the users login record, and handed to Firebase Auth once.
  // Plaintext is never persisted, returned, or logged.
  const encCredential = String(data.initialPasswordEnc ?? "");
  if (!encCredential) {
    throw new ProvisioningError(
      400,
      "This onboarding request has no stored employee password — resubmit the onboarding form to set one.",
      "NO_STORED_CREDENTIAL"
    );
  }
  let initialPassword: string;
  try {
    initialPassword = decryptCredential(encCredential);
  } catch {
    throw new ProvisioningError(
      400,
      "The stored employee password could not be read — resubmit the onboarding form.",
      "BAD_STORED_CREDENTIAL"
    );
  }
  const hash = await bcrypt.hash(initialPassword, 10);

  // Resolve the shift selected during onboarding (companyDetails.shiftTime
  // carries the shift display name picked from the company shift dropdown)
  // to the canonical company shift document. A non-empty selection that
  // matches nothing is a configuration error — approving it would create
  // an employee who can never pass attendance shift validation.
  const shiftSel = norm(company.shiftTime);
  const shiftDocId = norm(company.shiftId);
  let shiftId: string | null = null;
  let shiftName: string | null = null;

  // The stable document id wins when present; fall back to the legacy
  // display-name match so records onboarded before shiftId existed still
  // resolve. Either way the shift must belong to this company.
  if (shiftDocId) {
    const d = await db.collection("shifts").doc(shiftDocId).get();
    if (d.exists && (d.data() as any)?.companyId === companyId) {
      const s = d.data() as any;
      shiftId = d.id;
      shiftName = norm(s.name) || norm(s.shiftname) || shiftSel || null;
    }
  }
  if (!shiftId && shiftSel) {
    const shiftSnap = await db
      .collection("shifts")
      .where("companyId", "==", companyId)
      .limit(200)
      .get();
    const want = shiftSel.toLowerCase();
    const match = shiftSnap.docs
      .map((d) => ({ id: d.id, ...(d.data() as any) }))
      .find(
        (s) =>
          norm(s.name).toLowerCase() === want ||
          norm(s.shiftname).toLowerCase() === want
      );
    if (match) {
      shiftId = match.id;
      shiftName = norm(match.name) || norm(match.shiftname) || shiftSel;
    }
  }
  if ((shiftDocId || shiftSel) && !shiftId) {
    throw new ProvisioningError(
      400,
      'The shift selected during onboarding no longer exists for this company — recreate the shift or update the onboarding request.',
      "SHIFT_NOT_FOUND"
    );
  }

  // Firebase Auth identity: create, or link an existing account by email
  // and sync its password to the HR-assigned one. Unexpected failures are
  // fatal — silently skipping Auth provisioning would leave an employee
  // who can never sign in.
  let firebaseUid: string | null = null;
  try {
    const created = await auth.createUser({
      email,
      password: initialPassword,
      displayName: name,
    });
    firebaseUid = created.uid;
  } catch (e: any) {
    if (e?.code === "auth/email-already-exists") {
      try {
        firebaseUid = (await auth.getUserByEmail(email)).uid;
        await auth.updateUser(firebaseUid, { password: initialPassword });
      } catch {
        throw new ProvisioningError(
          502,
          "Firebase Auth provisioning failed — could not link the existing identity.",
          "AUTH_PROVISION_FAILED"
        );
      }
    } else {
      throw new ProvisioningError(
        502,
        "Firebase Auth provisioning failed — the employee login could not be created.",
        "AUTH_PROVISION_FAILED"
      );
    }
  }

  const now = new Date();
  const employeeRef = db.collection(EMPLOYEES).doc();
  const userRef = db.collection(USERS).doc();
  const onboardingRef = db.collection(ONBOARDING).doc(onboardingId);

  // Reuse an existing employee doc when this onboarding already made one
  // (partial-failure retry); otherwise create a fresh master record.
  const employeeDocId =
    !empById.empty &&
    (empById.docs[0].data() as any).onboardingId === onboardingId
      ? empById.docs[0].id
      : employeeRef.id;

  const batch = db.batch();

  if (employeeDocId === employeeRef.id) {
    batch.set(employeeRef, {
      companyId,
      empid,
      name,
      email,
      emailLower: email,
      phone: norm(
        `${personal.mobileCountryCode ?? ""} ${personal.mobileNumber ?? ""}`
      ),
      location: norm(company.branchLocation),
      dept: norm(company.department),
      designation: norm(company.designation),
      // Canonical shift assignment: shiftGroup holds the display name the
      // attendance flow matches on; shiftId is the stable document link.
      shiftGroup: shiftName,
      shiftId,
      shiftName,
      role: "employee",
      status: "active",
      source: "onboarding",
      onboardingId,
      createdAt: now,
      updatedAt: now,
      createdBy: actorId,
      updatedBy: actorId,
    });
  }

  batch.set(userRef, {
    empid,
    empId: empid,
    name,
    email,
    emailLower: email,
    password: hash,
    passwordHash: hash,
    hashedPassword: hash,
    role: "employee",
    status: "active",
    companyId,
    mustChangePassword: false,
    employeeDocId,
    onboardingId,
    firebaseUid,
    authSource: "onboarding",
    createdAt: now,
    updatedAt: now,
  });

  // The onboarding doc is only marked approved after provisioning writes
  // succeed — a failed batch leaves status 'pending' for a safe retry.
  batch.set(
    onboardingRef,
    {
      status: "approved",
      employeeDocId,
      userId: userRef.id,
      firebaseUid,
      provisionedAt: now,
      provisionedBy: actorId,
      updatedAt: now,
    },
    { merge: true }
  );

  await batch.commit();

  return {
    employeeDocId,
    userId: userRef.id,
    firebaseUid,
    tempPassword: null,
    alreadyProvisioned: false,
  };
}
