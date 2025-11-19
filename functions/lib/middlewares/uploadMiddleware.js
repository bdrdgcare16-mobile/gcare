"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadFields = exports.uploadMultiple = exports.uploadSingle = void 0;
const multer_1 = __importStar(require("multer"));
// Configure multer for memory storage (we'll handle the actual upload in the controller)
const storage = multer_1.default.memoryStorage();
// File filter to only allow certain file types
const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    }
    else {
        cb(new Error('Invalid file type. Only JPEG, PNG, JPG, and PDF files are allowed.'));
    }
};
// Configure multer with our storage and file filter
const upload = (0, multer_1.default)({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
    },
});
// Middleware for handling single file uploads
const uploadSingle = (fieldName) => {
    return (req, res, next) => {
        const uploadSingle = upload.single(fieldName);
        uploadSingle(req, res, (err) => {
            if (err) {
                if (err instanceof multer_1.MulterError) {
                    // A Multer error occurred when uploading
                    res.status(400).json({ error: err.message });
                    return;
                }
                else if (err instanceof Error) {
                    // An unknown error occurred
                    res.status(500).json({ error: err.message });
                    return;
                }
                res.status(500).json({ error: 'An unknown error occurred during file upload' });
                return;
            }
            next();
        });
        return; // Ensure the function always returns
    };
};
exports.uploadSingle = uploadSingle;
// Middleware for handling multiple file uploads
const uploadMultiple = (fieldName, maxCount = 5) => {
    return (req, res, next) => {
        const uploadMultiple = upload.array(fieldName, maxCount);
        uploadMultiple(req, res, (err) => {
            if (err) {
                if (err instanceof multer_1.MulterError) {
                    res.status(400).json({ error: err.message });
                    return;
                }
                else if (err instanceof Error) {
                    res.status(500).json({ error: err.message });
                    return;
                }
                res.status(500).json({ error: 'An unknown error occurred during file upload' });
                return;
            }
            next();
        });
        return; // Ensure the function always returns
    };
};
exports.uploadMultiple = uploadMultiple;
// Middleware for handling multiple fields with files
const uploadFields = (fields) => {
    return (req, res, next) => {
        const uploadFields = upload.fields(fields);
        uploadFields(req, res, (err) => {
            if (err) {
                if (err instanceof multer_1.MulterError) {
                    res.status(400).json({ error: err.message });
                    return;
                }
                else if (err instanceof Error) {
                    res.status(500).json({ error: err.message });
                    return;
                }
                res.status(500).json({ error: 'An unknown error occurred during file upload' });
                return;
            }
            next();
        });
        return; // Ensure the function always returns
    };
};
exports.uploadFields = uploadFields;
//# sourceMappingURL=uploadMiddleware.js.map