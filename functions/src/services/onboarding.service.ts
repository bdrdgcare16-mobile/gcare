import * as crypto from "crypto";
import * as fs from "fs";
import * as fsp from "fs/promises";
import * as path from "path";
import { db, bucket } from "../config/firebase";
import { EmployeeOnboarding } from "../models/onboarding.model";

const collection = db.collection("employee_onboarding_dev");

// True only inside the Functions emulator. There is no Storage emulator in
// the DEV suite and the configured bucket points at the production project
// (billing disabled) — uploads there hard-fail with a 403 GaxiosError. Under
// the emulator we therefore keep the same object-path references but store
// bytes on local disk and serve them back through a signed dev route.
const isEmulator = () => process.env.FUNCTIONS_EMULATOR === "true";

const DEV_STORAGE_ROOT = path.join(__dirname, "..", "..", ".local-storage");
const DEV_SIGNED_TTL_MS = 15 * 60 * 1000;

const devSigningSecret = () => process.env.JWT_SECRET || "serv-dev-doc-secret";

const devFileUrl = (storagePath: string): string => {
  const expires = Date.now() + DEV_SIGNED_TTL_MS;
  const sig = crypto
    .createHmac("sha256", devSigningSecret())
    .update(`${storagePath}|${expires}`)
    .digest("hex");
  const project =
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    "serv-dev-f2557";
  // Functions emulator host/port per firebase.json (0.0.0.0:5002).
  return (
    `http://127.0.0.1:5002/${project}/us-central1/api` +
    `/onboarding/documents/dev-file?path=${encodeURIComponent(storagePath)}` +
    `&e=${expires}&sig=${sig}`
  );
};

/**
 * Verifies a dev signed URL and resolves the local file it points to.
 * Returns the absolute path on success or an error string on failure.
 * Emulator only — never resolves when not running under FUNCTIONS_EMULATOR.
 */
export const resolveDevDocumentFile = (
  storagePath: string,
  expires: number,
  signature: string
): { absolutePath: string } | { error: string } => {
  if (!isEmulator()) return { error: "Not available" };
  if (!storagePath || !expires || expires < Date.now() || !signature) {
    return { error: "Invalid or expired link" };
  }
  const expected = crypto
    .createHmac("sha256", devSigningSecret())
    .update(`${storagePath}|${expires}`)
    .digest("hex");
  const a = Buffer.from(expected, "utf8");
  const b = Buffer.from(String(signature), "utf8");
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
    return { error: "Invalid or expired link" };
  }
  const normalized = storagePath.replace(/\\/g, "/");
  if (!normalized.startsWith("onboarding-dev/") || normalized.includes("..")) {
    return { error: "Invalid path" };
  }
  const absolutePath = path.join(DEV_STORAGE_ROOT, normalized);
  if (!absolutePath.startsWith(DEV_STORAGE_ROOT)) {
    return { error: "Invalid path" };
  }
  if (!fs.existsSync(absolutePath)) return { error: "Not found" };
  return { absolutePath };
};

export const uploadFileToFirebase = async (
  file: Express.Multer.File,
  employeeId: string,
  fieldName: string
): Promise<string> => {
  const safeName = String(file.originalname || "file")
    .replace(/[\\/]/g, "_")
    .replace(/\.\./g, "_");
  const filePath = `onboarding-dev/${employeeId}/${fieldName}-${Date.now()}-${safeName}`;

  if (isEmulator()) {
    // DEV: persist to local disk; the stored reference stays the same
    // object path so review/provisioning flows are unchanged.
    const dest = path.join(DEV_STORAGE_ROOT, filePath);
    await fsp.mkdir(path.dirname(dest), { recursive: true });
    await fsp.writeFile(dest, file.buffer);
    return filePath;
  }

  const fileRef = bucket.file(filePath);

  await fileRef.save(file.buffer, {
    metadata: {
      contentType: file.mimetype,
    },
  });

  // Keep files private - do NOT makePublic()
  // Return the file path for later signed URL generation
  return filePath;
};

export const createOnboarding = async (
  data: EmployeeOnboarding
): Promise<string> => {
  const docRef = await collection.add(data);
  return docRef.id;
};

export const getAllOnboardings = async (filters?: {
  search?: string;
  status?: string;
  department?: string;
  branch?: string;
  companyId?: string;
}) => {
  let query: any = collection;

  // Tenant scoping: callers (Company Admin review) only ever see their
  // own company's requests.
  if (filters?.companyId) {
    query = query.where(
      "companyDetails.companyId",
      "==",
      filters.companyId
    );
  }

  // If status filter is provided, add where clause
  if (filters?.status) {
    query = query.where("status", "==", filters.status);
  }

  const snapshot = await query.get();
  let onboardings = snapshot.docs.map((doc: any) => ({
    id: doc.id,
    ...doc.data(),
  }));

  // Apply client-side filtering for search, department, and branch
  if (filters?.search || filters?.department || filters?.branch) {
    onboardings = onboardings.filter((onboarding: EmployeeOnboarding & { id: string }) => {
      const search = filters?.search?.toLowerCase() || '';
      const department = filters?.department?.toLowerCase() || '';
      const branch = filters?.branch?.toLowerCase() || '';
      
      const data = onboarding as EmployeeOnboarding & { id: string };
      
      // Search in multiple fields
      const matchesSearch = !search ||
        data.personalDetails?.fullName?.toLowerCase().includes(search) ||
        data.companyDetails?.employeeId?.toLowerCase().includes(search) ||
        data.companyDetails?.department?.toLowerCase().includes(search) ||
        data.companyDetails?.designation?.toLowerCase().includes(search) ||
        data.companyDetails?.branchLocation?.toLowerCase().includes(search);
      
      // Department filter
      const matchesDepartment = !department ||
        data.companyDetails?.department?.toLowerCase() === department;
      
      // Branch filter
      const matchesBranch = !branch ||
        data.companyDetails?.branchLocation?.toLowerCase() === branch;
      
      return matchesSearch && matchesDepartment && matchesBranch;
    });
  }

  // Sort by createdAt on client side instead of Firestore
  onboardings.sort((a: EmployeeOnboarding & { id: string }, b: EmployeeOnboarding & { id: string }) => {
    const aDate = a.createdAt;
    const bDate = b.createdAt;
    
    if (aDate && bDate) {
      // Handle Firestore Timestamp format
      if (typeof aDate === 'object' && '_seconds' in aDate && typeof bDate === 'object' && '_seconds' in bDate) {
        return (bDate as any)._seconds - (aDate as any)._seconds; // Descending order
      }
      
      // Handle Date objects
      if (aDate instanceof Date && bDate instanceof Date) {
        return bDate.getTime() - aDate.getTime(); // Descending order
      }
      
      // Handle string dates
      if (typeof aDate === 'string' && typeof bDate === 'string') {
        return new Date(bDate).getTime() - new Date(aDate).getTime();
      }
    }
    
    return 0;
  });

  // Convert document paths to signed URLs for all onboardings
  const processedOnboardings = await Promise.all(
    onboardings.map(async (onboarding: EmployeeOnboarding & { id: string }) => {
      const data = onboarding as EmployeeOnboarding & { id: string };
      
      // Create a copy to avoid mutating the original data
      const processedData = { ...data };
      // Never expose the encrypted employee credential to clients.
      delete (processedData as any).initialPasswordEnc;

      // Convert document paths to signed URLs before response
      const signedDocuments: Record<string, string> = {};

      try {
        // Check if documents exist and is an object
        if (data.documents && typeof data.documents === 'object') {
          for (const [key, value] of Object.entries(data.documents)) {
            if (value && typeof value === 'string') {
              try {
                signedDocuments[key] = await getSignedUrl(value);
              } catch (error) {
                console.error(`Failed to generate signed URL for ${key}:`, error);
                // Keep original path if URL generation fails
                signedDocuments[key] = value;
              }
            }
          }
        }
        
        processedData.documents = signedDocuments;
      } catch (error) {
        console.error('Error processing documents for onboarding:', error);
        // Keep original documents if processing fails
        processedData.documents = data.documents || {};
      }
      
      return processedData;
    })
  );

  return processedOnboardings;
};

const normalizeFilePath = (value: string) => {
  if (!value) return value;

  let path = value;

  if (path.includes('?')) {
    path = path.split('?')[0];
  }

  if (path.includes('storage.googleapis.com/')) {
    path = path.split('storage.googleapis.com/')[1];
  }

  if (path.startsWith(`${bucket.name}/`)) {
    path = path.replace(`${bucket.name}/`, '');
  }

  return decodeURIComponent(path);
};

const getSignedUrl = async (filePath: string): Promise<string> => {
  const normalizedPath = normalizeFilePath(filePath);

  if (isEmulator()) {
    return devFileUrl(normalizedPath);
  }

  const [signedUrl] = await bucket
    .file(normalizedPath)
    .getSignedUrl({
      action: "read",
      expires: Date.now() + 15 * 60 * 1000,
    });

  return signedUrl;
};

export const generateSignedUrl = async (filePath: string): Promise<string> => {
  return getSignedUrl(filePath);
};

// Resolves a raw Firebase Storage object path (as stored in Firestore, e.g.
// "onboarding-dev/EMP001/offerLetter-....png") to a short-lived signed URL.
// Also tolerates being passed an already-public/legacy storage.googleapis.com
// URL by normalizing it back down to an object path first.
export const resolveDocumentStoragePath = async (
  storagePath: string
): Promise<string> => {
  const normalizedPath = normalizeFilePath(storagePath);
  return getSignedUrl(normalizedPath);
};

export const getOnboardingByEmpId = async (empid: string) => {
  const normalizedEmpId = String(empid ?? '').trim().toLowerCase();
  if (!normalizedEmpId) return null;

  // Query by top-level empid, top-level employeeId, and nested companyDetails.employeeId
  const [empidSnap, employeeIdSnap, nestedSnap] = await Promise.all([
    collection.where('empid', '==', empid).limit(1).get(),
    collection.where('employeeId', '==', empid).limit(1).get(),
    collection.where('companyDetails.employeeId', '==', empid).limit(1).get(),
  ]);

  const doc =
    empidSnap.docs[0] ??
    employeeIdSnap.docs[0] ??
    nestedSnap.docs[0];

  if (!doc) return null;

  const data = {
    id: doc.id,
    ...doc.data(),
  } as any;
  delete data.initialPasswordEnc;

  return data;
};

export const getOnboardingById = async (id: string) => {
  const doc = await collection.doc(id).get();

  if (!doc.exists) {
    return null;
  }

  const data = {
    id: doc.id,
    ...doc.data(),
  } as any;
  delete data.initialPasswordEnc;

  // Convert document paths to signed URLs before response
  const signedDocuments: Record<string, string> = {};

  for (const [key, value] of Object.entries(data.documents || {})) {
    if (value) {
      try {
        signedDocuments[key] = await getSignedUrl(normalizeFilePath(value as string));
      } catch (error) {
        console.error(`Failed to generate signed URL for ${key}:`, error);
        // Skip this document if URL generation fails
      }
    }
  }

  data.documents = signedDocuments;
  return data;
};

export const updateOnboardingStatus = async (
  id: string,
  status: "pending" | "approved" | "rejected" | "completed"
) => {
  await collection.doc(id).update({
    status,
    updatedAt: new Date(),
  });
};

// Raw document fetch used by the review/status endpoints — returns the
// stored data without signed-URL processing so callers can check
// companyId and provisioning linkage.
export const getOnboardingDoc = async (id: string) => {
  const doc = await collection.doc(id).get();
  return doc.exists ? ({ id: doc.id, ...doc.data() } as any) : null;
};
