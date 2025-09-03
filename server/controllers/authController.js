
const { db } = require('../config/firebase');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');

/* ---------------- NEW (safe) imports for OTP/email ---------------- */
const crypto = require('crypto');
let nodemailer = null;
try { nodemailer = require('nodemailer'); } catch (e) { /* optional */ }
/* ------------------------------------------------------------------ */

const JWT_SECRET  = process.env.JWT_SECRET || 'your-default-jwt-secret';
const JWT_EXPIRES = '1d';
const USERS_COL   = 'users';
const EMPS_COL    = 'employees';

/* ---------------- NEW constants/helpers for OTP flow --------------- */
const OTP_COL = 'password_resets';
const genOtp = () => String(Math.floor(100000 + Math.random() * 900000)); // 6 digits
const sha256 = (s = '') => crypto.createHash('sha256').update(String(s)).digest('hex');
const plusMinutes = (mins) => new Date(Date.now() + mins * 60 * 1000);

function makeTransport() {
  if (!nodemailer) return null;
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) return null;
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: false,
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
}
const mailer = makeTransport();
/* ------------------------------------------------------------------ */

// ---------- helpers ----------
const okRoles = new Set(['employee', 'admin']);
const normEmail = (e = '') => String(e).trim().toLowerCase();

const issueToken = (payload) =>
  jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES });

const sanitizeUser = (id, data) => {
  const { password, passwordHash, hashedPassword, ...rest } = data || {};
  return { id, ...rest };
};

const isBcryptHash = (s = '') => /^\$2[aby]\$/.test(String(s));

// Small helper: try both emailLower and email (legacy)
async function getByEmail(colName, emailLower) {
  // 1) preferred: emailLower
  let snap = await db.collection(colName)
    .where('emailLower', '==', emailLower)
    .limit(1).get();
  if (!snap.empty) return snap;

  // 2) legacy fallback: email (may contain case)
  snap = await db.collection(colName)
    .where('email', '==', emailLower)
    .limit(1).get();
  if (!snap.empty) return snap;

  // 3) as a last resort, try the exact incoming mixed-case email if caller wants to pass it
  return null;
}

/* ---------- NEW: single helper used by OTP endpoints ---------- */
async function getUserDocByEmailAny(emailLower) {
  // Try emailLower first
  let snap = await db.collection(USERS_COL)
    .where('emailLower', '==', emailLower)
    .limit(1).get();
  if (!snap.empty) return snap.docs[0];

  // Fallback: some older docs only have 'email'
  snap = await db.collection(USERS_COL)
    .where('email', '==', emailLower)
    .limit(1).get();
  if (!snap.empty) return snap.docs[0];

  return null;
}

/* ====================== LOGIN ====================== */
exports.login = async (req, res) => {
  const incoming = String(req.body.email || '');
  const email = normEmail(incoming);
  const { password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    // ---------- 1) USERS collection (preferred path) ----------
    let userSnap = await getByEmail(USERS_COL, email);

    if (userSnap && !userSnap.empty) {
      const doc  = userSnap.docs[0];
      const user = doc.data();

      const storedHash = user.password || user.passwordHash || user.hashedPassword || '';
      const match = await bcrypt.compare(password, storedHash);
      if (!match) return res.status(401).json({ error: 'Invalid email or password' });

      if (user.status && user.status !== 'active') {
        return res.status(403).json({ error: 'Account is not active' });
      }

      const role = String(user.role || 'employee').toLowerCase();
      if (!okRoles.has(role)) {
        return res.status(403).json({ error: 'Invalid role on account' });
      }

      const payload = {
        userId: doc.id,
        email:  user.email || incoming.trim(),
        role,
        empid:  user.empid || null,
      };
      const token = issueToken(payload);

      return res.json({
        message: 'Login successful',
        token,
        tokenType: 'Bearer',
        expiresIn: JWT_EXPIRES,
        role,
        uid: doc.id,
        empid: user.empid || null,
        name: user.name || user.fullName || '',
        user: {
          id:    doc.id,
          name:  user.name || user.fullName || '',
          email: user.email || incoming.trim(),
          role,
          empid: user.empid || null,
          status: user.status || 'active',
        },
      });
    }

    // ---------- 2) EMPLOYEES fallback (admin created employees) ----------
    const empSnap = await getByEmail(EMPS_COL, email);
    if (!empSnap || empSnap.empty) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const empDoc = empSnap.docs[0];
    const emp    = empDoc.data();

    // Accept either plaintext or bcrypt in employees.password
    const stored = emp.password || '';
    let passOK = false;
    if (stored) {
      passOK = isBcryptHash(stored) ? await bcrypt.compare(password, stored) : (stored === password);
    }
    if (!passOK) return res.status(401).json({ error: 'Invalid email or password' });

    if (emp.status && emp.status !== 'active') {
      return res.status(403).json({ error: 'Account is not active' });
    }

    // Ensure a mirror doc in USERS so future logins use normal flow
    let mirrorUserDoc = null;
    let mirrorSnap = await getByEmail(USERS_COL, email);

    if (mirrorSnap && !mirrorSnap.empty) {
      mirrorUserDoc = mirrorSnap.docs[0];
    } else {
      const hash = isBcryptHash(stored) ? stored : await bcrypt.hash(password, 10);
      const now  = new Date();
      const ref = await db.collection(USERS_COL).add({
        empid:  emp.empid || emp.employeeId || null,
        name:   emp.name || emp.fullName || '',
        email:  emp.email || incoming.trim(),
        emailLower: email,             // <<— normalized
        password: hash,
        passwordHash: hash,
        hashedPassword: hash,
        role: 'employee',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      });
      mirrorUserDoc = await ref.get();
    }

    const mirrorUser = mirrorUserDoc.data() || {};
    const payload = {
      userId: mirrorUserDoc.id,
      email: mirrorUser.email || incoming.trim(),
      role: 'employee',
      empid: mirrorUser.empid || emp.empid || null,
    };
    const token = issueToken(payload);

    return res.json({
      message: 'Login successful',
      token,
      tokenType: 'Bearer',
      expiresIn: JWT_EXPIRES,
      role: 'employee',
      uid: mirrorUserDoc.id,
      empid: mirrorUser.empid || emp.empid || null,
      name: mirrorUser.name || emp.name || '',
      user: {
        id: mirrorUserDoc.id,
        name: mirrorUser.name || emp.name || '',
        email: mirrorUser.email || incoming.trim(),
        role: 'employee',
        empid: mirrorUser.empid || emp.empid || null,
        status: mirrorUser.status || emp.status || 'active',
      },
    });
  } catch (err) {
    console.error('login error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/* ====================== REGISTER ====================== */
exports.register = async (req, res) => {
  let { empid, name, email, password, role, status } = req.body;

  email  = normEmail(email);
  empid  = String(empid || '').trim();
  name   = String(name || '').trim();
  role   = String(role || 'employee').trim().toLowerCase();
  status = String(status || 'active').trim().toLowerCase();

  if (!empid || !name || !email || !password || !role) {
    return res.status(400).json({ error: 'All fields are required' });
  }
  if (!okRoles.has(role)) {
    return res.status(400).json({ error: 'Role must be "employee" or "admin"' });
  }

  try {
    const byEmp = await db.collection(USERS_COL)
      .where('empid','==',empid).limit(1).get();
    if (!byEmp.empty) return res.status(400).json({ error: 'Employee ID already exists' });

    const byEmail = await db.collection(USERS_COL)
      .where('emailLower','==',email).limit(1).get();
    if (!byEmail.empty) return res.status(400).json({ error: 'Email is already in use' });

    const hash = await bcrypt.hash(password, 10);
    const now  = new Date();

    const newUser = {
      empid,
      name,
      email,                 // human-readable
      emailLower: email,     // normalized for queries
      password: hash,
      passwordHash: hash,
      hashedPassword: hash,
      role,
      status,
      createdAt: now,
      updatedAt: now,
    };

    const ref = await db.collection(USERS_COL).add(newUser);
    return res.status(201).json({ message: 'User registered', userId: ref.id });
  } catch (err) {
    console.error('register error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/* ====================== CHANGE PASSWORD ====================== */
exports.changePassword = async (req, res) => {
  const email = normEmail(req.body.email);
  const { newPassword } = req.body;

  if (!email || !newPassword) {
    return res.status(400).json({ error: 'Email and new password are required' });
  }

  try {
    const snap = await db.collection(USERS_COL)
      .where('emailLower','==',email).limit(1).get();
    if (snap.empty) return res.status(404).json({ error: 'User not found' });

    const userDoc = snap.docs[0];
    const hash    = await bcrypt.hash(newPassword, 10);

    await db.collection(USERS_COL).doc(userDoc.id).update({
      password:  hash,
      passwordHash: hash,
      hashedPassword: hash,
      updatedAt: new Date(),
    });

    return res.json({ message: 'Password changed successfully' });
  } catch (err) {
    console.error('changePassword error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/* ====================== FORGOT PASSWORD ====================== */
exports.forgotPassword = async (req, res) => {
  return exports.changePassword(req, res);
};

/* ====================== GET ME ====================== */
exports.getMe = async (req, res) => {
  try {
    const userId = req.user?.userId; // from verifyToken
    const email  = normEmail(req.user?.email || '');
    if (!userId && !email) return res.status(401).json({ error: 'Unauthorized' });

    // Try USERS by id
    let doc = null;
    if (userId) {
      const d = await db.collection(USERS_COL).doc(userId).get();
      if (d.exists) doc = d;
    }
    // Fallback: USERS by emailLower
    if (!doc && email) {
      const q = await db.collection(USERS_COL).where('emailLower','==',email).limit(1).get();
      if (!q.empty) doc = q.docs[0];
    }

    if (doc) {
      const user = sanitizeUser(doc.id, doc.data());
      if (user.empid) {
        const empSnap = await db.collection(EMPS_COL)
          .where('empid', '==', user.empid)
          .limit(1)
          .get();
        if (!empSnap.empty) {
          const emp = empSnap.docs[0].data();
          delete emp.password;
          user.employeeProfile = emp;
        }
      }
      return res.json(user);
    }

    // Last resort: employees by emailLower
    if (email) {
      const empSnap = await db.collection(EMPS_COL)
        .where('emailLower','==',email).limit(1).get();
      if (!empSnap.empty) {
        const eDoc = empSnap.docs[0];
        const emp  = eDoc.data();
        delete emp.password;
        return res.json({
          id: eDoc.id,
          email,
          role: 'employee',
          empid: emp.empid || null,
          name: emp.name || emp.fullName || '',
          employeeProfile: emp,
        });
      }
    }

    return res.status(404).json({ error: 'User not found' });
  } catch (err) {
    console.error('getMe error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/* ======================================================================
   ADMIN HELPERS: enable logins for employees
   ====================================================================== */

// POST /api/auth/admin/create-employee-login
// body: { empid, email?, password? }
exports.createEmployeeLogin = async (req, res) => {
  try {
    let { empid, email, password } = req.body || {};
    empid = String(empid || '').trim();
    email = normEmail(email || '');

    if (!empid) return res.status(400).json({ error: 'empid is required' });

    // fetch employee to fill missing fields
    const empQ = await db.collection(EMPS_COL).where('empid', '==', empid).limit(1).get();
    if (empQ.empty) return res.status(404).json({ error: 'Employee not found' });
    const emp = empQ.docs[0].data();

    const name = String(emp.name || emp.fullName || '').trim();
    if (!email) email = normEmail(emp.email || '');
    if (!email) return res.status(400).json({ error: 'email is required (not found on employee record)' });

    // already has a login?
    const existsByEmail = await db.collection(USERS_COL).where('emailLower', '==', email).limit(1).get();
    if (!existsByEmail.empty) return res.status(409).json({ error: 'Login already exists for this email' });

    const existsByEmpid = await db.collection(USERS_COL).where('empid', '==', empid).limit(1).get();
    if (!existsByEmpid.empty) return res.status(409).json({ error: 'Login already exists for this empid' });

    const tempPassword = `${empid}@123`;
    const finalPassword = String(password || tempPassword);
    const hash = await bcrypt.hash(finalPassword, 10);
    const now = new Date();

    const docRef = await db.collection(USERS_COL).add({
      empid,
      name,
      email,
      emailLower: email,     // <<— normalized
      password: hash,
      passwordHash: hash,
      hashedPassword: hash,
      role: 'employee',
      status: 'active',
      mustChangePassword: !password,
      createdAt: now,
      updatedAt: now,
    });

    return res.json({
      message: 'Login enabled for employee',
      userId: docRef.id,
      tempPassword: !password ? tempPassword : undefined,
    });
  } catch (err) {
    console.error('createEmployeeLogin error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/auth/admin/backfill-employee-logins
exports.backfillEmployeesToUsers = async (req, res) => {
  try {
    const empSnap = await db.collection(EMPS_COL).get();
    const created = [];
    const updatedEmp = [];

    for (const d of empSnap.docs) {
      const e = d.data();
      const empid = String(e.empid || '').trim();
      const emailLower = normEmail(e.email || '');
      const name  = String(e.name || e.fullName || '').trim();
      if (!empid || !emailLower) {
        // also normalize employees collection for future queries
        await d.ref.set({ emailLower }, { merge: true });
        continue;
      }

      // ensure employees have emailLower
      if (!e.emailLower || e.emailLower !== emailLower) {
        await d.ref.set({ emailLower }, { merge: true });
        updatedEmp.push({ empid, emailLower });
      }

      const exists = await db.collection(USERS_COL)
        .where('emailLower', '==', emailLower)
        .limit(1)
        .get();
      if (!exists.empty) continue;

      const existsEmp = await db.collection(USERS_COL)
        .where('empid', '==', empid)
        .limit(1)
        .get();
      if (!existsEmp.empty) continue;

      const temp = `${empid}@123`;
      const hash = await bcrypt.hash(temp, 10);
      const now  = new Date();

      const ref = await db.collection(USERS_COL).add({
        empid,
        name,
        email: e.email || emailLower,
        emailLower,
        password: hash,
        passwordHash: hash,
        hashedPassword: hash,
        role: 'employee',
        status: 'active',
        mustChangePassword: true,
        createdAt: now,
        updatedAt: now,
      });

      created.push({ userId: ref.id, empid, email: e.email || emailLower, tempPassword: temp });
    }

    return res.json({ message: 'Backfill complete', createdCount: created.length, normalizedEmployees: updatedEmp.length, created });
  } catch (err) {
    console.error('backfillEmployeesToUsers error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/* ====================== NEW: FORGOT-PASSWORD OTP ENDPOINTS ====================== */

// POST /api/auth/forgot-password/request-otp   { email }
exports.requestOtp = async (req, res) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    if (!email) return res.status(400).json({ error: 'Email is required' });

    // Ensure user exists (supports both emailLower and legacy email)
    const userDoc = await getUserDocByEmailAny(email);
    if (!userDoc) return res.status(404).json({ error: 'User not found' });

    const otp = genOtp();
    const hash = sha256(otp);

    // Invalidate any previous active OTPs for this email
    // (only equality filters -> no composite index required)
    const prev = await db.collection(OTP_COL)
      .where('emailLower', '==', email)
      .where('used', '==', false)
      .get();
    for (const d of prev.docs) {
      await d.ref.set({ used: true }, { merge: true });
    }

    // WRITE A DOC -> this auto-creates the collection if it doesn't exist
    await db.collection(OTP_COL).add({
      emailLower: email,
      otpHash: hash,
      used: false,
      createdAt: new Date(),
      expiresAt: plusMinutes(10), // 10 minutes validity
      attempts: 0,
    });

    /* ---------- ADDED: send the OTP email via SMTP ---------- */
    if (mailer) {
      const from = process.env.SMTP_FROM || `SERV App <${process.env.SMTP_USER}>`;
      try {
        await mailer.sendMail({
          from,
          to: email,
          subject: 'Password Reset OTP',
          text: `Your OTP code is: ${otp}. Valid for 10 minutes.`,
          html: `<h3>Password Reset OTP</h3>
                 <p>Your OTP code is <b>${otp}</b>.</p>
                 <p>This code is valid for 10 minutes.</p>`,
        });
      } catch (e) {
        console.error('sendMail error:', e);
        // You can still return success to avoid leaking SMTP errors to users.
      }
    } else {
      console.warn('Mailer not configured. Check SMTP_* env vars.');
    }
    /* -------------------------------------------------------- */

    // Keep this log for dev
    console.log(`[DEV] OTP for ${email}: ${otp}`);

    return res.json({ message: 'OTP sent', otpSent: true });
  } catch (err) {
    console.error('requestOtp error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};

/**
 * POST /api/auth/forgot-password/verify-otp
 * body: { email, otp }
 */
exports.verifyOtp = async (req, res) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const otp   = String(req.body.otp || '').trim();
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP are required' });

    // Fetch recent OTP docs WITHOUT orderBy (avoid composite index).
    const q = await db.collection(OTP_COL)
      .where('emailLower', '==', email)
      .limit(20)
      .get();

    // Sort in memory by createdAt desc and pick first unused
    const list = q.docs
      .map(d => ({ d, data: d.data() }))
      .sort((a, b) => {
        const ad = a.data.createdAt?.toDate ? a.data.createdAt.toDate() : a.data.createdAt;
        const bd = b.data.createdAt?.toDate ? b.data.createdAt.toDate() : b.data.createdAt;
        return (bd?.getTime?.() || 0) - (ad?.getTime?.() || 0);
      });

    let doc = null, rec = null;
    for (const it of list) {
      if (!it.data.used) { doc = it.d; rec = it.data; break; }
    }
    if (!doc) return res.status(400).json({ error: 'OTP not found. Please request again.' });

    // Check expiry
    const now = new Date();
    const exp = rec.expiresAt?.toDate ? rec.expiresAt.toDate() : rec.expiresAt;
    if (exp < now) {
      await doc.ref.set({ used: true }, { merge: true });
      return res.status(400).json({ error: 'OTP expired. Please request again.' });
    }

    // Check value
    if (sha256(otp) !== rec.otpHash) {
      const attempts = (rec.attempts || 0) + 1;
      await doc.ref.set({ attempts }, { merge: true });
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    await doc.ref.set({ verifiedAt: now }, { merge: true });
    return res.json({ message: 'OTP verified', ok: true });
  } catch (err) {
    console.error('verifyOtp error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};

/**
 * POST /api/auth/forgot-password/reset
 * body: { email, otp, newPassword }
 */
exports.resetPasswordWithOtp = async (req, res) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const otp   = String(req.body.otp || '').trim();
    const newPassword = String(req.body.newPassword || '');
    if (!email || !otp || !newPassword) {
      return res.status(400).json({ error: 'Email, OTP and newPassword are required' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Fetch OTP docs WITHOUT orderBy (avoid composite index)
    const q = await db.collection(OTP_COL)
      .where('emailLower', '==', email)
      .limit(20)
      .get();

    const list = q.docs
      .map(d => ({ d, data: d.data() }))
      .sort((a, b) => {
        const ad = a.data.createdAt?.toDate ? a.data.createdAt.toDate() : a.data.createdAt;
        const bd = b.data.createdAt?.toDate ? b.data.createdAt.toDate() : b.data.createdAt;
        return (bd?.getTime?.() || 0) - (ad?.getTime?.() || 0);
      });

    let doc = null, rec = null;
    for (const it of list) {
      if (!it.data.used) { doc = it.d; rec = it.data; break; }
    }
    if (!doc) return res.status(400).json({ error: 'OTP not found. Please request again.' });

    const now = new Date();
    const exp = rec.expiresAt?.toDate ? rec.expiresAt.toDate() : rec.expiresAt;
    if (exp < now) {
      await doc.ref.set({ used: true }, { merge: true });
      return res.status(400).json({ error: 'OTP expired. Please request again.' });
    }
    if (sha256(otp) !== rec.otpHash) {
      const attempts = (rec.attempts || 0) + 1;
      await doc.ref.set({ attempts }, { merge: true });
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    // Update password in users collection (supports emailLower/email)
    const userDoc = await getUserDocByEmailAny(email);
    if (!userDoc) return res.status(404).json({ error: 'User not found' });

    const hash = await bcrypt.hash(newPassword, 10);
    await userDoc.ref.set({
      password: hash,
      passwordHash: hash,
      hashedPassword: hash,
      mustChangePassword: false,
      updatedAt: now,
    }, { merge: true });

    // Consume the OTP
    await doc.ref.set({ used: true, resetAt: now }, { merge: true });

    return res.json({ message: 'Password reset successful' });
  } catch (err) {
    console.error('resetPasswordWithOtp error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};
