const path = require('path');
const fs = require('fs');
const db = require('../config/firebase'); // ✅ Firebase Firestore instance
const { FieldValue } = require('firebase-admin/firestore'); // ✅ For serverTimestamp

// ─────────────────────────────────────────────────────────────
// ✅ 1. Upload File & Save Metadata in Firestore
const uploadFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // ✅ Save metadata to Firestore
    await db.collection('files').add({
      fileName: req.file.filename,
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
      size: req.file.size,
      path: `/uploads/${req.file.filename}`,
      uploadedAt: FieldValue.serverTimestamp() // ✅ server timestamp
    });

    // ✅ Return response
    res.json({
      message: 'File uploaded successfully',
      fileName: req.file.filename,
      originalName: req.file.originalname,
      path: `/uploads/${req.file.filename}`
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ─────────────────────────────────────────────────────────────
// ✅ 2. View File Inline (image or PDF)
const viewFile = (req, res) => {
  const fileName = req.params.name;
  const filePath = path.join(__dirname, '../uploads', fileName);

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  const ext = path.extname(fileName).toLowerCase();
  const mime = ext === '.pdf' ? 'application/pdf' : `image/${ext.replace('.', '')}`;

  res.setHeader('Content-Type', mime);
  fs.createReadStream(filePath).pipe(res); // ✅ Stream to browser
};

// ─────────────────────────────────────────────────────────────
// ✅ 3. Download File
const downloadFile = (req, res) => {
  const fileName = req.params.name;
  const filePath = path.join(__dirname, '../uploads', fileName);

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  res.download(filePath); // ✅ Download prompt
};

// ─────────────────────────────────────────────────────────────
// ✅ Export all
module.exports = {
  uploadFile,
  viewFile,
  downloadFile
};
