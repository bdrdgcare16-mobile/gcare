// utils/storage.js
const fs = require('fs');
const path = require('path');
const { bucket, storageBucket } = require('../config/firebase');

function buildTaskPath(taskId, originalName) {
  const safe = (originalName || 'file')
    .replace(/[^a-zA-Z0-9._-]/g, '_');
  return `tasks/${taskId}/${Date.now()}_${safe}`;
}

async function uploadBufferToStorage(file, destPath) {
  // If Storage bucket is not configured for any reason, write to local disk.
  if (!bucket || !storageBucket) {
    const localPath = path.join(__dirname, '..', 'uploads', destPath);
    await fs.promises.mkdir(path.dirname(localPath), { recursive: true });
    await fs.promises.writeFile(localPath, file.buffer);
    return `/uploads/${destPath.replace(/\\/g, '/')}`;
  }

  // Upload to GCS
  const gcsFile = bucket.file(destPath);
  await gcsFile.save(file.buffer, {
    contentType: file.mimetype || 'application/octet-stream',
    resumable: false,
    public: true,
    metadata: { cacheControl: 'public, max-age=31536000' },
  });

  // Make public (ignore if already public)
  try { await gcsFile.makePublic(); } catch (_) {}

  return `https://storage.googleapis.com/${storageBucket}/${destPath}`;
}

module.exports = { buildTaskPath, uploadBufferToStorage };
