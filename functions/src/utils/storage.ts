import { Storage } from '@google-cloud/storage';
import { v4 as uuidv4 } from 'uuid';

const storage = new Storage();
const bucketName = process.env.FIREBASE_STORAGE_BUCKET || '';

export interface UploadedFile {
  fieldname: string;
  originalname: string;
  mimetype: string;
  buffer: Buffer;
  size: number;
}

export interface UploadResult {
  url: string;
  name: string;
  contentType: string;
  size: number;
}

export const uploadFile = async (
  file: UploadedFile,
  folder: string = 'uploads'
): Promise<UploadResult> => {
  try {
    const fileName = `${folder}/${uuidv4()}-${file.originalname}`;
    const bucket = storage.bucket(bucketName);
    const blob = bucket.file(fileName);

    const blobStream = blob.createWriteStream({
      metadata: {
        contentType: file.mimetype,
      },
    });

    return new Promise((resolve, reject) => {
      blobStream.on('error', (error) => {
        console.error('Upload error:', error);
        reject(error);
      });

      blobStream.on('finish', () => {
        const publicUrl = `https://storage.googleapis.com/${bucketName}/${blob.name}`;
        resolve({
          url: publicUrl,
          name: blob.name,
          contentType: file.mimetype,
          size: file.size,
        });
      });

      blobStream.end(file.buffer);
    });
  } catch (error) {
    console.error('Upload error:', error);
    throw error;
  }
};

export const deleteFile = async (fileName: string): Promise<void> => {
  try {
    const bucket = storage.bucket(bucketName);
    await bucket.file(fileName).delete();
  } catch (error) {
    console.error('Error deleting file:', error);
    throw new Error('Failed to delete file');
  }
};
