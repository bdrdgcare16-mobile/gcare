// Reserved for future file upload features (SERV 2.0)
import { Request, Response } from 'express';
import { uploadFile, deleteFile, UploadedFile } from '../utils/storage';
import { trackUsage } from '../services/usageService';

// Extend Express Request type to include file and files
declare module 'express' {
  interface Request {
    file?: Express.Multer.File;
    files?: Express.Multer.File[] | { [fieldname: string]: Express.Multer.File[] };
  }
}

// Helper to convert Express.Multer.File to our UploadedFile
const toUploadedFile = (file: Express.Multer.File): UploadedFile => ({
  fieldname: file.fieldname,
  originalname: file.originalname,
  mimetype: file.mimetype,
  buffer: file.buffer,
  size: file.size,
});

/* ============================== Usage Tracking Helper ============================== */

async function trackUploadUsage(
  req: Request,
  updates: Record<string, number>
) {
  try {
    const user = (req as any).user;
    await trackUsage({
      companyId: user?.companyId || '',
      companyName: user?.companyName || '',
      plan: user?.plan || '',
      updates,
    });
  } catch (trackingError) {
    console.error('Usage tracking failed in upload:', trackingError);
  }
}

export const uploadSingleFile = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const uploadedFile = toUploadedFile(req.file);
    const result = await uploadFile(uploadedFile, 'uploads');

    // Track usage after successful file upload
    const storageUsedMb = uploadedFile.size / (1024 * 1024); // Convert bytes to MB
    await trackUploadUsage(req, {
      writeCount: 1,
      apiCalls: 1,
      fileUploadCount: 1,
      storageUsedMb: Math.round(storageUsedMb * 100) / 100, // Round to 2 decimal places
    });
    
    return res.status(200).json({
      message: 'File uploaded successfully',
      data: result,
    });
  } catch (error) {
    console.error('Upload error:', error);
    return res.status(500).json({ error: 'Failed to upload file' });
  }
};

export const uploadMultipleFiles = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    if (!req.files || !Array.isArray(req.files) || req.files.length === 0) {
      return res.status(400).json({ error: 'No files uploaded' });
    }

    const uploadPromises = (req.files as Express.Multer.File[]).map(file => 
      uploadFile(toUploadedFile(file), 'uploads')
    );

    const results = await Promise.all(uploadPromises);

    // Track usage after successful multiple file uploads
    const totalSize = (req.files as Express.Multer.File[]).reduce((sum, file) => sum + file.size, 0);
    const storageUsedMb = totalSize / (1024 * 1024); // Convert bytes to MB
    await trackUploadUsage(req, {
      writeCount: 1,
      apiCalls: 1,
      fileUploadCount: (req.files as Express.Multer.File[]).length,
      storageUsedMb: Math.round(storageUsedMb * 100) / 100, // Round to 2 decimal places
    });
    
    return res.status(200).json({
      message: 'Files uploaded successfully',
      data: results,
    });
  } catch (error) {
    console.error('Upload error:', error);
    return res.status(500).json({ error: 'Failed to upload files' });
  }
};

export const deleteUploadedFile = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const { fileName } = req.params;
    if (!fileName) {
      return res.status(400).json({ error: 'File name is required' });
    }

    await deleteFile(fileName);

    // Track usage after successful file deletion
    await trackUploadUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });
    
    return res.status(200).json({ message: 'File deleted successfully' });
  } catch (error) {
    console.error('Delete error:', error);
    return res.status(500).json({ error: 'Failed to delete file' });
  }
};
