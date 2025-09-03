

const multer = require('multer');
const path  = require('path');
const fs    = require('fs');

// ─── Ensure base upload dirs exist ─────────────────────────────────────────────

const uploadBasePath  = path.join(__dirname, '../uploads');
const logoUploadPath  = path.join(uploadBasePath, 'company_logo');

// Create uploads/ and uploads/company_logo/ if missing
[uploadBasePath, logoUploadPath].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// ─── Multer Storage Engine ────────────────────────────────────────────────────

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // send files into uploads/company_logo/
    cb(null, logoUploadPath);
  },
  filename: (req, file, cb) => {
    const ext      = path.extname(file.originalname).toLowerCase();
    const basename = path.basename(file.originalname, ext);
    // e.g. logo-1616161616161.png
    cb(null, `${basename}-${Date.now()}${ext}`);
  }
});

// ─── File Filter & Limits ─────────────────────────────────────────────────────

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/jpg'];
  if (allowed.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only JPEG/JPG/PNG images are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 2 * 1024 * 1024 }, // 2 MB max
});

module.exports = upload;
