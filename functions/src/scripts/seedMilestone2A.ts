/**
 * Development-only seed script for Milestone 2A Employee Login and
 * Milestone 2B organization-policy testing.
 * Targets the local Firebase Auth, Functions and Firestore emulators.
 * Never run against production.
 */

import { createHash } from 'crypto';

const PROJECT_ID = 'serv-dev-f2557';

// Force all Firebase Admin SDKs to talk to the local emulators. These MUST
// be set before any firebase-admin module is imported.
process.env.APP_FIREBASE_PROJECT_ID = PROJECT_ID;
process.env.FUNCTIONS_EMULATOR = 'true';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

interface SeedCompany {
  id: string;
  code: string;
  status: 'active' | 'inactive' | 'suspended';
  companyName: string;
  adminEmail?: string;
  phone?: string;
  adminName?: string;
  designation?: string;
  website?: string;
  filled?: boolean;
}

interface SeedEmployee {
  email: string;
  companyId: string;
  status: 'active' | 'inactive';
  role: 'employee' | 'admin';
  empid: string;
  fullName: string;
  createAuthAccount?: boolean;
}

interface SeedPolicy {
  id: string;
  organizationId: string;
  policyId: string;
  type: string;
  title: string;
  description: string;
  version: number;
  content: string;
  required: boolean;
  requiresSeparateConsent: boolean;
}

const seedPassword = 'TestPass123!';

const companies: SeedCompany[] = [
  {
    id: 'test-company-001',
    code: 'SERVTEST01',
    status: 'active',
    companyName: 'SERV Test Organization',
  },
  {
    id: 'test-company-002',
    code: 'SERVTEST02',
    status: 'inactive',
    companyName: 'SERV Inactive Org',
  },
  {
    id: 'test-company-003',
    code: 'SERVTEST03',
    status: 'suspended',
    companyName: 'SERV Suspended Org',
  },
  {
    id: 'test-company-004',
    code: 'SERVTEST04',
    status: 'active',
    companyName: 'SERV Active Org With Inactive Employee',
  },
  {
    id: 'test-company-005',
    code: 'SERVTEST05',
    status: 'active',
    companyName: 'SERV Active Org With Admin User',
    // Complete profile so the seeded Admin is routed to AdminDashboard.
    adminEmail: 'test.admin@example.com',
    phone: '+1-555-TEST-ADMIN',
    adminName: 'Test Admin',
    designation: 'Administrator',
    website: 'https://example.com',
    filled: true,
  },
];

const employees: SeedEmployee[] = [
  {
    email: 'test.employee@example.com',
    companyId: 'test-company-001',
    status: 'active',
    role: 'employee',
    empid: 'TESTEMP001',
    fullName: 'Test Employee',
    createAuthAccount: true,
  },
  {
    email: 'test.inactiveorg@example.com',
    companyId: 'test-company-002',
    status: 'active',
    role: 'employee',
    empid: 'TESTEMP002',
    fullName: 'Inactive Org Employee',
  },
  {
    email: 'test.suspendedorg@example.com',
    companyId: 'test-company-003',
    status: 'active',
    role: 'employee',
    empid: 'TESTEMP003',
    fullName: 'Suspended Org Employee',
  },
  {
    email: 'test.inactiveemployee@example.com',
    companyId: 'test-company-004',
    status: 'inactive',
    role: 'employee',
    empid: 'TESTEMP004',
    fullName: 'Inactive Employee',
  },
  {
    email: 'test.admin@example.com',
    companyId: 'test-company-005',
    status: 'active',
    role: 'admin',
    empid: 'TESTADMIN001',
    fullName: 'Test Admin',
    createAuthAccount: true,
  },
];

// Fictional test policies for the local emulator only (test-company-001 /
// SERVTEST01). Do not seed real company policy text.
const policies: SeedPolicy[] = [
  {
    id: 'test-company-001_attendance-policy_v1',
    organizationId: 'test-company-001',
    policyId: 'attendance-policy',
    type: 'attendance',
    title: 'Attendance Policy',
    description:
      'TEST ONLY — fictional attendance policy for local emulator testing.',
    version: 1,
    content:
      'TEST POLICY — NOT REAL CONTENT.\n\n' +
      '1. Employees are expected to check in within the configured geofence.\n' +
      '2. Late arrivals must be explained through the attendance request flow.\n' +
      '3. This text exists solely to test the organization policy screen.',
    required: true,
    requiresSeparateConsent: false,
  },
  {
    id: 'test-company-001_leave-policy_v1',
    organizationId: 'test-company-001',
    policyId: 'leave-policy',
    type: 'leave',
    title: 'Leave Policy',
    description:
      'TEST ONLY — optional fictional leave policy for local emulator testing.',
    version: 1,
    content:
      'TEST POLICY — NOT REAL CONTENT.\n\n' +
      '1. Annual leave requests require manager approval.\n' +
      '2. This optional policy does not block dashboard access.',
    required: false,
    requiresSeparateConsent: false,
  },
  {
    id: 'test-company-001_location-tracking-consent_v1',
    organizationId: 'test-company-001',
    policyId: 'location-tracking-consent',
    type: 'location_tracking_consent',
    title: 'Location Tracking Consent',
    description:
      'TEST ONLY — fictional location-tracking consent for local emulator testing.',
    version: 1,
    content:
      'TEST POLICY — NOT REAL CONTENT.\n\n' +
      '1. This consent covers collection of location data during work hours.\n' +
      '2. It must be acknowledged separately from other policies.',
    required: true,
    requiresSeparateConsent: true,
  },
];

async function seed() {
  // Dynamic import guarantees env vars are set before firebase-admin loads.
  const { getDb, getAdminAuth } = await import('../config/firebase');

  console.log(`[SEED] Target project: ${PROJECT_ID}`);
  console.log(`[SEED] Firestore emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`);
  console.log(`[SEED] Auth emulator: ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);

  const db = getDb();
  const auth = getAdminAuth();

  const batch = db.batch();

  for (const c of companies) {
    const ref = db.collection('companyProfile').doc(c.id);
    const emailLower = c.adminEmail ? c.adminEmail.toLowerCase() : undefined;
    batch.set(
      ref,
      {
        code: c.code,
        status: c.status,
        companyName: c.companyName,
        ...(c.adminEmail ? { adminEmail: c.adminEmail, adminEmailLower: emailLower } : {}),
        ...(c.adminEmail ? { email: c.adminEmail, emailLower } : {}),
        ...(c.phone ? { phone: c.phone } : {}),
        ...(c.adminName ? { adminName: c.adminName } : {}),
        ...(c.designation ? { designation: c.designation } : {}),
        ...(c.website ? { website: c.website } : {}),
        ...(c.filled !== undefined ? { filled: c.filled } : {}),
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      { merge: true }
    );
    console.log(`[SEED] companyProfile/${c.id} code=${c.code} status=${c.status}`);
  }

  for (const e of employees) {
    const emailLower = e.email.toLowerCase();
    const empRef = db.collection('employees').doc();
    batch.set(
      empRef,
      {
        email: e.email,
        emailLower,
        fullName: e.fullName,
        companyId: e.companyId,
        role: e.role,
        status: e.status,
        empid: e.empid,
        employeeId: e.empid,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      { merge: true }
    );

    const userRef = db.collection('users').doc();
    batch.set(
      userRef,
      {
        email: e.email,
        emailLower,
        name: e.fullName,
        fullName: e.fullName,
        companyId: e.companyId,
        role: e.role,
        status: e.status,
        empid: e.empid,
        empId: e.empid,
        employeeId: e.empid,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      { merge: true }
    );

    console.log(`[SEED] employees/${empRef.id} and matching users/${userRef.id} for ${e.email}`);
  }

  for (const p of policies) {
    const ref = db.collection('organizationPolicies').doc(p.id);
    batch.set(
      ref,
      {
        organizationId: p.organizationId,
        policyId: p.policyId,
        type: p.type,
        title: p.title,
        description: p.description,
        version: p.version,
        content: p.content,
        publishedAt: new Date(),
        active: true,
        required: p.required,
        requiresSeparateConsent: p.requiresSeparateConsent,
        contentHash: createHash('sha256').update(p.content).digest('hex'),
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      { merge: true }
    );
    console.log(
      `[SEED] organizationPolicies/${p.id} type=${p.type} required=${p.required}`
    );
  }

  await batch.commit();

  for (const e of employees) {
    if (e.createAuthAccount) {
      try {
        await auth.createUser({
          email: e.email,
          password: seedPassword,
          displayName: e.fullName,
        });
        console.log(`[SEED] Auth account created: ${e.email}`);
      } catch (err: any) {
        if (err.code === 'auth/email-already-exists') {
          console.log(`[SEED] Auth account already exists: ${e.email}`);
        } else {
          throw err;
        }
      }
    }
  }

  console.log('[SEED] Done.');
}

seed().catch((err) => {
  console.error('[SEED] FAILED:', err);
  process.exit(1);
});
