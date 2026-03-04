"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUploadedFile = exports.uploadMultipleFiles = exports.uploadSingleFile = void 0;
const storage_1 = require("../utils/storage");
// Helper to convert Express.Multer.File to our UploadedFile
const toUploadedFile = (file) => ({
    fieldname: file.fieldname,
    originalname: file.originalname,
    mimetype: file.mimetype,
    buffer: file.buffer,
    size: file.size,
});
const uploadSingleFile = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }
        const uploadedFile = toUploadedFile(req.file);
        const result = await (0, storage_1.uploadFile)(uploadedFile, 'uploads');
        return res.status(200).json({
            message: 'File uploaded successfully',
            data: result,
        });
    }
    catch (error) {
        console.error('Upload error:', error);
        return res.status(500).json({ error: 'Failed to upload file' });
    }
};
exports.uploadSingleFile = uploadSingleFile;
const uploadMultipleFiles = async (req, res) => {
    try {
        if (!req.files || !Array.isArray(req.files) || req.files.length === 0) {
            return res.status(400).json({ error: 'No files uploaded' });
        }
        const uploadPromises = req.files.map(file => (0, storage_1.uploadFile)(toUploadedFile(file), 'uploads'));
        const results = await Promise.all(uploadPromises);
        return res.status(200).json({
            message: 'Files uploaded successfully',
            data: results,
        });
    }
    catch (error) {
        console.error('Upload error:', error);
        return res.status(500).json({ error: 'Failed to upload files' });
    }
};
exports.uploadMultipleFiles = uploadMultipleFiles;
const deleteUploadedFile = async (req, res) => {
    try {
        const { fileName } = req.params;
        if (!fileName) {
            return res.status(400).json({ error: 'File name is required' });
        }
        await (0, storage_1.deleteFile)(fileName);
        return res.status(200).json({ message: 'File deleted successfully' });
    }
    catch (error) {
        console.error('Delete error:', error);
        return res.status(500).json({ error: 'Failed to delete file' });
    }
};
exports.deleteUploadedFile = deleteUploadedFile;
//# sourceMappingURL=uploadController.js.map