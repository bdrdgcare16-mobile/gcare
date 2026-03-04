"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildTaskPath = exports.uploadBufferToStorage = exports.deleteFile = exports.uploadFile = void 0;
const firebase_1 = require("../config/firebase");
const uuid_1 = require("uuid");
/**
 * Upload a file to the project's default Firebase Storage bucket,
 * make it PUBLIC, and return its public URL.
 */
const uploadFile = async (file, folder = 'uploads') => {
    const bucket = firebase_1.storage.bucket(); // uses the bucket you initialized in config/firebase.ts
    const objectPath = `${folder}/${(0, uuid_1.v4)()}-${file.originalname}`;
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
exports.uploadFile = uploadFile;
const deleteFile = async (objectPath) => {
    const bucket = firebase_1.storage.bucket();
    await bucket.file(objectPath).delete({ ignoreNotFound: true });
};
exports.deleteFile = deleteFile;
const uploadBufferToStorage = async (buffer, originalname, mimetype, folder = 'tasks') => {
    try {
        const fileName = `${folder}/${(0, uuid_1.v4)()}-${originalname}`;
        const bucket = firebase_1.storage.bucket();
        const file = bucket.file(fileName);
        await file.save(buffer, {
            metadata: {
                contentType: mimetype,
            },
        });
        // Make the file publicly accessible
        await file.makePublic();
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
        return {
            url: publicUrl,
            name: fileName,
            contentType: mimetype,
            size: buffer.length,
        };
    }
    catch (error) {
        console.error('Error uploading file:', error);
        throw new Error('Failed to upload file to storage');
    }
};
exports.uploadBufferToStorage = uploadBufferToStorage;
const buildTaskPath = (taskId, fileName) => {
    return `tasks/${taskId}/${fileName}`;
};
exports.buildTaskPath = buildTaskPath;
//# sourceMappingURL=storage.js.map