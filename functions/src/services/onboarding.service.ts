import { db, bucket } from "../config/firebase";
import { EmployeeOnboarding } from "../models/onboarding.model";

const collection = db.collection("employee_onboarding_dev");

export const uploadFileToFirebase = async (
  file: Express.Multer.File,
  employeeId: string,
  fieldName: string
): Promise<string> => {
  const filePath = `onboarding-dev/${employeeId}/${fieldName}-${Date.now()}-${file.originalname}`;
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
}) => {
  let query: any = collection;

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
