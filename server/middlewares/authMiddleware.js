
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your-default-jwt-secret';

// ---- helpers ----
function getToken(req) {
  const h = req.headers.authorization || req.headers.Authorization || '';
  if (typeof h === 'string') {
    const [scheme, token] = h.split(' ');
    if (scheme && token && /^Bearer$/i.test(scheme)) return token.trim();
  }
  if (req.headers['x-access-token']) return String(req.headers['x-access-token']).trim();
  if (req.cookies && req.cookies.token) return req.cookies.token; // if using cookie-parser
  return null;
}

function verifyToken(req, res, next) {
  const token = getToken(req);
  if (!token) {
    return res.status(401).json({ message: 'No token provided' });
  }

  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid or expired token' });
    }
    // Expect payload like: { userId, email, role, empid }
    req.user = decoded;
    next();
  });
}

// generic role gate
function requireRole(allowed = []) {
  return (req, res, next) => {
    const role = String(req.user?.role || '').toLowerCase();
    if (allowed.length === 0 || allowed.includes(role)) return next();
    return res.status(403).json({ message: 'Forbidden: insufficient role' });
  };
}

// Specific gates (keep your existing names)
const isAdmin       = requireRole(['admin']);
const isUser        = requireRole(['employee', 'user']);                 // employees/users only
const isUserOrAdmin = requireRole(['employee', 'user', 'admin']);        // either

module.exports = {
  verifyToken,
  isAdmin,
  isUser,
  isUserOrAdmin,
  requireRole, // exported in case you need a custom gate elsewhere
};
