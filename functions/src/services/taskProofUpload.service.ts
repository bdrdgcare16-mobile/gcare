import { bucket } from '../config/firebase';

/**
 * Uploads a task proof file to Firebase Storage.
 * This is a task-specific implementation following the onboarding upload pattern.
 * 
 * @param file - The multer file object
 * @param taskId - The task ID for organizing storage
 * @returns The Firebase Storage file path
 */
export const uploadTaskProofToFirebase = async (
  file: Express.Multer.File,
  taskId: string
): Promise<string> => {
  const filePath = `task-proofs/${taskId}/${Date.now()}-${file.originalname}`;
  const fileRef = bucket.file(filePath);

  console.log('[TaskProofUpload] Uploading file to Firebase Storage:', {
    filePath,
    originalname: file.originalname,
    mimetype: file.mimetype,
    size: file.size,
  });

  await fileRef.save(file.buffer, {
    metadata: {
      contentType: file.mimetype,
    },
  });

  console.log('[TaskProofUpload] Upload successful:', filePath);

  // Return the file path (not a public URL)
  // The path can be used to generate signed URLs later if needed
  return filePath;
};

/**
 * Generates a signed URL for a task proof file.
 * 
 * @param filePath - The Firebase Storage file path
 * @returns A signed URL valid for 15 minutes
 */
export const getTaskProofSignedUrl = async (filePath: string): Promise<string> => {
  const [signedUrl] = await bucket
    .file(filePath)
    .getSignedUrl({
      action: 'read',
      expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    });

  console.log('[TaskProofUpload] Generated signed URL for:', filePath);
  return signedUrl;
};