import Busboy from "busboy";
import multer from "multer";
import path from "path";
import { NextFunction, Request, Response } from "express";

const storage = multer.memoryStorage();

const allowedMimeTypes = [
  "application/pdf",
  "image/jpeg",
  "image/jpg",
  "image/png",
  "application/octet-stream",
];

const allowedExtensions = [
  ".pdf",
  ".jpg",
  ".jpeg",
  ".png",
];

const fileFilter = (
  req: Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback
) => {
  try {
    const extension = path
      .extname(file.originalname)
      .toLowerCase();

    const isValidMime =
      allowedMimeTypes.includes(file.mimetype);

    const isValidExtension =
      allowedExtensions.includes(extension);

    if (isValidMime && isValidExtension) {
      cb(null, true);
    } else {
      cb(
        new Error(
          "Only PDF, JPG, JPEG, and PNG files are allowed"
        )
      );
    }
  } catch (error) {
    cb(
      new Error("File validation failed")
    );
  }
};

export const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
  fileFilter,
});

const onboardingFileFields = new Set([
  'resume',
  'offerLetter',
  'aadhaarCard',
  'panCard',
  'bankProof',
  'degreeCertificate',
  'passportPhoto',
  'experienceCertificate',
  'relievingLetter',
]);

const onboardingMimeTypes = new Set(allowedMimeTypes);

export const uploadOnboarding = (
  fields: { name: string; maxCount?: number }[],
) => {
  const multerUpload = upload.fields(fields);

  return (req: Request, res: Response, next: NextFunction) => {
    const rawBody = (req as any).rawBody;
    const contentType = String(req.headers['content-type'] ?? '').toLowerCase();

    if (!rawBody || rawBody.length === 0 || !contentType.startsWith('multipart/form-data')) {
      console.log('[onboarding-upload] parser mode: multer');
      return multerUpload(req, res, next);
    }

    console.log('[onboarding-upload] parser mode: rawBody');

    const parsedBody: Record<string, string> = {};
    const parsedFiles: Record<string, Express.Multer.File[]> = {};
    const fileCounts = new Map<string, number>();
    const fileTasks: Promise<void>[] = [];
    let parserError: Error | null = null;

    const busboy = Busboy({
      headers: req.headers,
      limits: {
        fileSize: 10 * 1024 * 1024,
        files: fields.length,
      },
    });

    busboy.on('field', (fieldName, value) => {
      parsedBody[fieldName] = value;
    });

    busboy.on('file', (fieldName, stream, info) => {
      const count = fileCounts.get(fieldName) ?? 0;
      const isAllowedField = onboardingFileFields.has(fieldName);
      const isAllowedMime = onboardingMimeTypes.has(info.mimeType);
      const extension = path.extname(info.filename).toLowerCase();
      const isAllowedExtension = allowedExtensions.includes(extension);

      if (!isAllowedField || count >= 1 || !isAllowedMime || !isAllowedExtension) {
        parserError ??= new Error(
          !isAllowedField
            ? 'Unexpected field'
            : count >= 1
                ? 'Unexpected duplicate file field'
                : 'Only PDF, JPG, JPEG, and PNG files are allowed',
        );
        stream.resume();
        return;
      }

      fileCounts.set(fieldName, count + 1);
      const chunks: Buffer[] = [];
      let size = 0;
      let fileLimited = false;

      const task = new Promise<void>((resolve) => {
        stream.on('data', (chunk: Buffer) => {
          chunks.push(chunk);
          size += chunk.length;
        });
        stream.on('limit', () => {
          fileLimited = true;
          parserError ??= new Error('File exceeds the 10 MB limit');
        });
        stream.on('error', (error: Error) => {
          parserError ??= error;
          resolve();
        });
        stream.on('close', () => {
          if (!fileLimited && !parserError) {
            const file = {
              fieldname: fieldName,
              originalname: info.filename,
              encoding: info.encoding,
              mimetype: info.mimeType,
              buffer: Buffer.concat(chunks),
              size,
            } as Express.Multer.File;
            parsedFiles[fieldName] = [file];
          }
          resolve();
        });
      });
      fileTasks.push(task);
    });

    busboy.on('error', (error: Error) => {
      parserError ??= error;
    });

    busboy.on('close', () => {
      void Promise.all(fileTasks).then(() => {
        if (parserError) return next(parserError);
        req.body = parsedBody;
        req.files = parsedFiles;
        console.log('[onboarding-upload] rawbody complete', {
          bodyFieldCount: Object.keys(parsedBody).length,
          fileFieldCount: Object.keys(parsedFiles).length,
        });
        next();
      });
    });

    busboy.end(rawBody);
  };
};
