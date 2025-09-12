// import { Storage } from '@google-cloud/storage';
// import { v4 as uuidv4 } from 'uuid';

// const storage = new Storage();
// const bucketName = process.env.FIREBASE_STORAGE_BUCKET || '';

// export interface UploadedFile {
//   fieldname: string;
//   originalname: string;
//   mimetype: string;
//   buffer: Buffer;
//   size: number;
// }

// export interface UploadResult {
//   url: string;
//   name: string;
//   contentType: string;
//   size: number;
// }

// export const uploadFile = async (
//   file: UploadedFile,
//   folder: string = 'uploads'
// ): Promise<UploadResult> => {
//   try {
//     const fileName = `${folder}/${uuidv4()}-${file.originalname}`;
//     const bucket = storage.bucket(bucketName);
//     const blob = bucket.file(fileName);

//     const blobStream = blob.createWriteStream({
//       metadata: {
//         contentType: file.mimetype,
//       },
//     });

//     return new Promise((resolve, reject) => {
//       blobStream.on('error', (error) => {
//         console.error('Upload error:', error);
//         reject(error);
//       });

//       blobStream.on('finish', () => {
//         const publicUrl = `https://storage.googleapis.com/${bucketName}/${blob.name}`;
//         resolve({
//           url: publicUrl,
//           name: blob.name,
//           contentType: file.mimetype,
//           size: file.size,
//         });
//       });

//       blobStream.end(file.buffer);
//     });
//   } catch (error) {
//     console.error('Upload error:', error);
//     throw error;
//   }
// };

// export const deleteFile = async (fileName: string): Promise<void> => {
//   try {
//     const bucket = storage.bucket(bucketName);
//     await bucket.file(fileName).delete();
//   } catch (error) {
//     console.error('Error deleting file:', error);
//     throw new Error('Failed to delete file');
//   }
// };
// src/utils/storage.ts
import { storage as adminStorage } from '../config/firebase';
import { v4 as uuidv4 } from 'uuid';

export interface UploadedFile {
  fieldname: string;
  originalname: string;
  mimetype: string;
  buffer: Buffer;
  size: number;
}

export interface UploadResult {
  url: string;        // public URL
  name: string;       // object path in bucket
  contentType: string;
  size: number;
}

/**
 * Upload a file to the project's default Firebase Storage bucket,
 * make it PUBLIC, and return its public URL.
 */
export const uploadFile = async (
  file: UploadedFile,
  folder: string = 'uploads'
): Promise<UploadResult> => {
  const bucket = adminStorage.bucket();           // uses the bucket you initialized in config/firebase.ts
  const objectPath = `${folder}/${uuidv4()}-${file.originalname}`;
  const blob = bucket.file(objectPath);

  // Upload the bytes
  await blob.save(file.buffer, {
    resumable: false,
    contentType: file.mimetype,
    metadata: { contentType: file.mimetype },
  });

  // Make the object public (readable by anyone with the URL)
  await blob.makePublic();

  const publicUrl = `https://storage.googleapis.com/${bucket.name}/${objectPath}`;
  return {
    url: publicUrl,
    name: objectPath,
    contentType: file.mimetype,
    size: file.size,
  };
};

export const deleteFile = async (objectPath: string): Promise<void> => {
  const bucket = adminStorage.bucket();
  await bucket.file(objectPath).delete({ ignoreNotFound: true });
};
