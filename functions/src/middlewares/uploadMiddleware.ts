import { Request, Response, NextFunction } from 'express';
import multer, { FileFilterCallback, MulterError } from 'multer';
import Busboy from 'busboy';

// Extend Express Request type to include file and files
declare module 'express' {
  interface Request {
    file?: Express.Multer.File;
    files?: Express.Multer.File[] | { [fieldname: string]: Express.Multer.File[] };
  }
}

// Configure multer for memory storage (we'll handle the actual upload in the controller)
const storage = multer.memoryStorage();

// File filter to only allow certain file types
const fileFilter = (req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
  
  // Check MIME type
  if (!allowedTypes.includes(file.mimetype)) {
    console.log('[Upload] Rejected file: invalid MIME type', file.mimetype);
    return cb(new Error('Invalid file type. Only JPEG, PNG, JPG, and PDF files are allowed.'));
  }
  
  // Check file extension
  const fileExtension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));
  if (!allowedExtensions.includes(fileExtension)) {
    console.log('[Upload] Rejected file: invalid extension', fileExtension);
    return cb(new Error('Invalid file extension. Only JPEG, PNG, JPG, and PDF files are allowed.'));
  }
  
  // Check for double extensions (potential security risk)
  if (file.originalname.includes('.') && file.originalname.substring(file.originalname.lastIndexOf('.')).toLowerCase() !== fileExtension) {
    console.log('[Upload] Rejected file: suspicious filename', file.originalname);
    return cb(new Error('Invalid filename. Files with multiple extensions are not allowed.'));
  }
  
  console.log('[Upload] File validation passed:', file.originalname, file.mimetype);
  cb(null, true);
};

// Configure multer with our storage and file filter
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

// Middleware for handling single file uploads
export const uploadSingle = (fieldName: string) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const uploadSingle = upload.single(fieldName);
    
    uploadSingle(req, res, (err: unknown) => {
      if (err) {
        if (err instanceof MulterError) {
          // A Multer error occurred when uploading
          res.status(400).json({ error: err.message });
          return;
        } else if (err instanceof Error) {
          // An unknown error occurred
          res.status(500).json({ error: err.message });
          return;
        }
        res.status(500).json({ error: 'An unknown error occurred during file upload' });
        return;
      }
      next();
    });
  };
};

// Middleware for handling optional single file uploads (supports both JSON and multipart)
export const uploadSingleOptional = (fieldName: string) => {
  return (req: Request, res: Response, next: NextFunction) => {
    // Check if the request is multipart
    const contentType = req.headers['content-type'] || '';
    const isMultipart = contentType.includes('multipart/form-data');
    
    console.log('[UploadOptional] Content-Type:', contentType);
    console.log('[UploadOptional] Is multipart:', isMultipart);
    
    if (!isMultipart) {
      // Not multipart - skip multer and proceed
      console.log('[UploadOptional] Skipping multer (JSON request)');
      return next();
    }
    
    // Is multipart - apply multer
    console.log('[UploadOptional] Applying multer (multipart request)');
    const uploadSingle = upload.single(fieldName);
    
    uploadSingle(req, res, (err: unknown) => {
      if (err) {
        if (err instanceof MulterError) {
          // A Multer error occurred when uploading
          console.log('[UploadOptional] Multer error:', err.message);
          res.status(400).json({ error: err.message });
          return;
        } else if (err instanceof Error) {
          // An unknown error occurred
          console.log('[UploadOptional] Error:', err.message);
          res.status(500).json({ error: err.message });
          return;
        }
        res.status(500).json({ error: 'An unknown error occurred during file upload' });
        return;
      }
      console.log('[UploadOptional] Multer processing complete');
      next();
    });
  };
};

// Task-specific upload middleware following onboarding pattern
export const uploadTaskProof = (fieldName: string) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const rawBody = (req as any).rawBody;
    const contentType = String(req.headers['content-type'] ?? '').toLowerCase();
    
    console.log('[TaskUpload] Content-Type:', contentType);
    console.log('[TaskUpload] Content-Length:', req.headers['content-length']);
    console.log('[TaskUpload] Has rawBody:', Boolean(rawBody));
    console.log('[TaskUpload] RawBody length:', rawBody?.length ?? 0);
    
    // Check if the request is multipart
    const isMultipart = contentType.includes('multipart/form-data');
    
    if (!isMultipart) {
      // Not multipart - skip multer and proceed
      console.log('[TaskUpload] Skipping upload (JSON request)');
      return next();
    }
    
    // If rawBody is available, use Busboy parsing (like onboarding)
    if (rawBody && rawBody.length > 0) {
      console.log('[TaskUpload] Using Busboy parser (rawBody mode)');
      return parseWithBusboy(req, res, next, fieldName, rawBody);
    }
    
    // Otherwise use regular multer
    console.log('[TaskUpload] Using multer parser');
    const uploadSingle = upload.single(fieldName);
    
    uploadSingle(req, res, (err: unknown) => {
      if (err) {
        if (err instanceof MulterError) {
          console.log('[TaskUpload] Multer error:', err.message);
          console.log('[TaskUpload] Multer error code:', err.code);
          res.status(400).json({ error: err.message });
          return;
        } else if (err instanceof Error) {
          console.log('[TaskUpload] Error:', err.message);
          console.log('[TaskUpload] Error stack:', err.stack);
          res.status(500).json({ error: err.message });
          return;
        }
        res.status(500).json({ error: 'An unknown error occurred during file upload' });
        return;
      }
      console.log('[TaskUpload] Multer processing complete');
      console.log('[TaskUpload] req.file:', req.file ? 'File present' : 'No file');
      if (req.file) {
        console.log('[TaskUpload] File details:', {
          fieldname: req.file.fieldname,
          originalname: req.file.originalname,
          mimetype: req.file.mimetype,
          size: req.file.size,
        });
      }
      next();
    });
  };
};

// Busboy parser for task proof upload (following onboarding pattern)
const parseWithBusboy = (
  req: Request,
  res: Response,
  next: NextFunction,
  fieldName: string,
  rawBody: Buffer
) => {
  const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf', 'application/octet-stream'];
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
  
  const parsedBody: Record<string, string> = {};
  let parsedFile: Express.Multer.File | null = null;
  let parserError: Error | null = null;
  
  const busboy = Busboy({
    headers: req.headers,
    limits: {
      fileSize: 5 * 1024 * 1024, // 5MB limit
      files: 1,
    },
  });
  
  busboy.on('field', (name, value) => {
    console.log('[TaskUpload Busboy] Field:', name);
    parsedBody[name] = value;
  });
  
  busboy.on('file', (name, stream, info) => {
    console.log('[TaskUpload Busboy] File field:', name);
    console.log('[TaskUpload Busboy] File info:', info);
    
    if (name !== fieldName) {
      console.log('[TaskUpload Busboy] Unexpected field name:', name, 'expected:', fieldName);
      parserError = new Error(`Unexpected field name: ${name}`);
      stream.resume();
      return;
    }
    
    const extension = info.filename.toLowerCase().substring(info.filename.lastIndexOf('.'));
    const isAllowedExtension = allowedExtensions.includes(extension);
    const isAllowedMime = allowedMimeTypes.includes(info.mimeType);
    
    if (!isAllowedExtension) {
      console.log('[TaskUpload Busboy] Invalid extension:', extension);
      parserError = new Error('Invalid file extension. Only JPEG, PNG, JPG, and PDF files are allowed.');
      stream.resume();
      return;
    }
    
    if (!isAllowedMime) {
      console.log('[TaskUpload Busboy] Warning: unusual MIME type:', info.mimeType, 'but allowing based on extension');
    }
    
    const chunks: Buffer[] = [];
    let size = 0;
    let fileLimited = false;
    
    stream.on('data', (chunk: Buffer) => {
      chunks.push(chunk);
      size += chunk.length;
    });
    
    stream.on('limit', () => {
      fileLimited = true;
      parserError = new Error('File exceeds the 5 MB limit');
    });
    
    stream.on('error', (error: Error) => {
      parserError = parserError || error;
    });
    
    stream.on('close', () => {
      if (!fileLimited && !parserError) {
        parsedFile = {
          fieldname: name,
          originalname: info.filename,
          encoding: info.encoding,
          mimetype: info.mimeType,
          buffer: Buffer.concat(chunks),
          size,
        } as Express.Multer.File;
        console.log('[TaskUpload Busboy] File parsed successfully:', {
          originalname: info.filename,
          mimetype: info.mimeType,
          size,
        });
      }
    });
  });
  
  busboy.on('error', (error: Error) => {
    parserError = parserError || error;
    console.error('[TaskUpload Busboy] Parser error:', error);
  });
  
  busboy.on('close', () => {
    if (parserError) {
      console.error('[TaskUpload Busboy] Parser error on close:', parserError.message);
      return next(parserError);
    }
    
    req.body = parsedBody;
    req.file = parsedFile || undefined;
    
    console.log('[TaskUpload Busboy] Parsing complete:', {
      bodyFieldCount: Object.keys(parsedBody).length,
      hasFile: Boolean(parsedFile),
    });
    
    if (parsedFile) {
      console.log('[TaskUpload Busboy] File details:', {
        fieldname: parsedFile.fieldname,
        originalname: parsedFile.originalname,
        mimetype: parsedFile.mimetype,
        size: parsedFile.size,
      });
    }
    
    next();
  });
  
  busboy.end(rawBody);
};

// Middleware for handling multiple file uploads
export const uploadMultiple = (fieldName: string, maxCount: number = 5) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const uploadMultiple = upload.array(fieldName, maxCount);
    
    uploadMultiple(req, res, (err: unknown) => {
      if (err) {
        if (err instanceof MulterError) {
          res.status(400).json({ error: err.message });
          return;
        } else if (err instanceof Error) {
          res.status(500).json({ error: err.message });
          return;
        }
        res.status(500).json({ error: 'An unknown error occurred during file upload' });
        return;
      }
      next();
    });
  };
};

// Middleware for handling multiple fields with files
export const uploadFields = (fields: { name: string; maxCount?: number }[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const uploadFields = upload.fields(fields);
    
    uploadFields(req, res, (err: unknown) => {
      if (err) {
        if (err instanceof MulterError) {
          res.status(400).json({ error: err.message });
          return;
        } else if (err instanceof Error) {
          res.status(500).json({ error: err.message });
          return;
        }
        res.status(500).json({ error: 'An unknown error occurred during file upload' });
        return;
      }
      next();
    });
  };
};
