"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const uploadMiddleware_1 = require("../middlewares/uploadMiddleware");
const uploadController_1 = require("../controllers/uploadController");
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
// Protected routes (require authentication)
router.use(authMiddleware_1.authMiddleware);
// Upload single file
router.post('/single', (0, uploadMiddleware_1.uploadSingle)('file'), uploadController_1.uploadSingleFile);
// Upload multiple files (max 5)
router.post('/multiple', (0, uploadMiddleware_1.uploadMultiple)('files', 5), uploadController_1.uploadMultipleFiles);
// Delete a file
router.delete('/:filePath', uploadController_1.deleteUploadedFile);
exports.default = router;
//# sourceMappingURL=upload.js.map