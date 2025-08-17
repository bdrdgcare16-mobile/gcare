// // // // // // // // // middlewares/authMiddleware.js

// // // // // // // // const jwt = require('jsonwebtoken');
// // // // // // // // const JWT_SECRET = process.env.JWT_SECRET;

// // // // // // // // // Warn if secret is missing
// // // // // // // // if (!JWT_SECRET) {
// // // // // // // //   console.warn('⚠️  JWT_SECRET is not defined in environment variables');
// // // // // // // // }

// // // // // // // // /**
// // // // // // // //  * verifyToken
// // // // // // // //  * – Verifies the Bearer token in `Authorization` header.
// // // // // // // //  * – On success populates `req.user = { userId, email, role }`.
// // // // // // // //  * – On failure returns 401 or 403 with a JSON error.
// // // // // // // //  */
// // // // // // // // exports.verifyToken = (req, res, next) => {
// // // // // // // //   // 1. Grab header
// // // // // // // //   const authHeader = req.headers.authorization || req.headers.Authorization;
// // // // // // // //   if (!authHeader) {
// // // // // // // //     return res.status(401).json({ error: 'No authorization header provided' });
// // // // // // // //   }

// // // // // // // //   // 2. Split into “Bearer” & token
// // // // // // // //   const parts = authHeader.split(' ');
// // // // // // // //   if (parts.length !== 2) {
// // // // // // // //     return res.status(401).json({ error: 'Malformed authorization header' });
// // // // // // // //   }

// // // // // // // //   const [scheme, token] = parts;
// // // // // // // //   if (!/^Bearer$/i.test(scheme)) {
// // // // // // // //     return res.status(401).json({ error: 'Malformed authorization header' });
// // // // // // // //   }

// // // // // // // //   // 3. Verify JWT
// // // // // // // //   try {
// // // // // // // //     const payload = jwt.verify(token, JWT_SECRET);

// // // // // // // //       // ✅ NEW: Debug log for dev
// // // // // // // //     console.log('✅ Logged-in User:', payload); // ✅ NEW
// // // // // // // //     // ensure payload contains the fields you expect
// // // // // // // //     req.user = {
// // // // // // // //       userId: payload.userId,
// // // // // // // //       email:  payload.email,
// // // // // // // //       role:   payload.role
// // // // // // // //     };
// // // // // // // //     return next();
// // // // // // // //   } catch (err) {
// // // // // // // //     console.error('verifyToken error:', err);
// // // // // // // //     return res.status(401).json({ error: 'Invalid or expired token' });
// // // // // // // //   }
// // // // // // // // };

// // // // // // // // /**
// // // // // // // //  * isAdmin
// // // // // // // //  * – Allows only users whose `req.user.role === 'admin'`
// // // // // // // //  */
// // // // // // // // exports.isAdmin = (req, res, next) => {
// // // // // // // //   if (req.user && req.user.role === 'admin') {
// // // // // // // //     return next();
// // // // // // // //   }
// // // // // // // //   return res.status(403).json({ error: 'Forbidden: Admins only' });
// // // // // // // // };

// // // // // // // // /**
// // // // // // // //  * isUser
// // // // // // // //  * – Allows only users whose `req.user.role === 'user'`
// // // // // // // //  * (adjust if you wish to allow [ 'user', 'admin' ] here)
// // // // // // // //  */
// // // // // // // // exports.isUser = (req, res, next) => {
// // // // // // // //   if (req.user && req.user.role === 'user') {
// // // // // // // //     return next();
// // // // // // // //   }
// // // // // // // //   return res.status(403).json({ error: 'Forbidden: Users only' });
// // // // // // // // };

// // // // // // // // /**
// // // // // // // //  * isUserOrAdmin
// // // // // // // //  * – Allows users with role 'user' or 'admin'
// // // // // // // //  */
// // // // // // // // exports.isUserOrAdmin = (req, res, next) => {
// // // // // // // //   if (req.user && (req.user.role === 'user' || req.user.role === 'admin')) {
// // // // // // // //     return next();
// // // // // // // //   }
// // // // // // // //   return res.status(403).json({ error: 'Forbidden: Insufficient role' });
// // // // // // // // };
// // // // // // // const jwt = require('jsonwebtoken');
// // // // // // // const JWT_SECRET = process.env.JWT_SECRET;

// // // // // // // // ✅ NEW: Warn if secret is missing
// // // // // // // if (!JWT_SECRET) {
// // // // // // //   console.warn('⚠️  JWT_SECRET is not defined in environment variables');
// // // // // // // }

// // // // // // // /**
// // // // // // //  * verifyToken
// // // // // // //  * – Verifies the Bearer token in the `Authorization` header.
// // // // // // //  * – On success, populates `req.user = { userId, email, role }`.
// // // // // // //  * – On failure, returns 401 or 403 with a JSON error.
// // // // // // //  */
// // // // // // // exports.verifyToken = (req, res, next) => {
// // // // // // //   // 1. Grab the Authorization header
// // // // // // //   const authHeader = req.headers.authorization || req.headers.Authorization;
// // // // // // //   if (!authHeader) {
// // // // // // //     return res.status(401).json({ error: 'No authorization header provided' });
// // // // // // //   }

// // // // // // //   // 2. Split the header into "Bearer" and token
// // // // // // //   const parts = authHeader.split(' ');
// // // // // // //   if (parts.length !== 2) {
// // // // // // //     return res.status(401).json({ error: 'Malformed authorization header' });
// // // // // // //   }

// // // // // // //   const [scheme, token] = parts;
// // // // // // //   if (!/^Bearer$/i.test(scheme)) {
// // // // // // //     return res.status(401).json({ error: 'Malformed authorization header' });
// // // // // // //   }

// // // // // // //   // 3. Verify the JWT token
// // // // // // //   try {
// // // // // // //     const payload = jwt.verify(token, JWT_SECRET); // ✅ Verifies using secret

// // // // // // //     // ✅ NEW: Debug log for development
// // // // // // //     console.log('✅ Logged-in User:', payload); // ✅ NEW

// // // // // // //     // ✅ Store the decoded payload in req.user
// // // // // // //     req.user = {
// // // // // // //       userId: payload.userId,
// // // // // // //       email: payload.email,
// // // // // // //       role: payload.role
// // // // // // //     };
// // // // // // //     return next();
// // // // // // //   } catch (err) {
// // // // // // //     console.error('verifyToken error:', err);
// // // // // // //     return res.status(401).json({ error: 'Invalid or expired token' });
// // // // // // //   }
// // // // // // // };

// // // // // // // /**
// // // // // // //  * isAdmin
// // // // // // //  * – Allows only users whose `req.user.role === 'admin'`
// // // // // // //  */
// // // // // // // exports.isAdmin = (req, res, next) => {
// // // // // // //   if (req.user && req.user.role === 'admin') {
// // // // // // //     return next();
// // // // // // //   }
// // // // // // //   return res.status(403).json({ error: 'Forbidden: Admins only' });
// // // // // // // };

// // // // // // // /**
// // // // // // //  * isUser
// // // // // // //  * – Allows only users whose `req.user.role === 'user'`
// // // // // // //  * (adjust if you wish to allow [ 'user', 'admin' ] here)
// // // // // // //  */
// // // // // // // exports.isUser = (req, res, next) => {
// // // // // // //   if (req.user && req.user.role === 'user') {
// // // // // // //     return next();
// // // // // // //   }
// // // // // // //   return res.status(403).json({ error: 'Forbidden: Users only' });
// // // // // // // };

// // // // // // // /**
// // // // // // //  * isUserOrAdmin
// // // // // // //  * – Allows users with role 'user' or 'admin'
// // // // // // //  */
// // // // // // // exports.isUserOrAdmin = (req, res, next) => {
// // // // // // //   if (req.user && (req.user.role === 'user' || req.user.role === 'admin')) {
// // // // // // //     return next();
// // // // // // //   }
// // // // // // //   return res.status(403).json({ error: 'Forbidden: Insufficient role' });
// // // // // // // };
// // // // // // // authMiddleware.js
// // // // // // // const jwt = require('jsonwebtoken');
// // // // // // // const JWT_SECRET = process.env.JWT_SECRET; // The secret key for JWT (ensure this is set in your environment)

// // // // // // // module.exports.verifyToken = (req, res, next) => {
// // // // // // //   const token = req.headers.authorization?.split(' ')[1]; // Get the token from Authorization header

// // // // // // //   if (!token) {
// // // // // // //     return res.status(403).json({ message: 'No token provided' }); // If no token is found, reject the request
// // // // // // //   }

// // // // // // //   // Verify the token
// // // // // // //   jwt.verify(token, JWT_SECRET, (err, decoded) => {
// // // // // // //     if (err) {
// // // // // // //       return res.status(403).json({ message: 'Invalid token' }); // If token is invalid, reject
// // // // // // //     }

// // // // // // //     req.user = decoded; // Attach the decoded user data to `req.user`
// // // // // // //     next(); // Proceed to the next middleware or route
// // // // // // //   });
// // // // // // // };
// // // // // // const jwt = require('jsonwebtoken');
// // // // // // const JWT_SECRET = process.env.JWT_SECRET; // Ensure this is set in your environment variables

// // // // // // module.exports.verifyToken = (req, res, next) => {
// // // // // //   const token = req.headers.authorization?.split(' ')[1]; // Get token from Authorization header

// // // // // //   if (!token) {
// // // // // //     return res.status(403).json({ message: 'No token provided' }); // If no token is found, reject the request
// // // // // //   }

// // // // // //   // Verify the token
// // // // // //   jwt.verify(token, JWT_SECRET, (err, decoded) => {
// // // // // //     if (err) {
// // // // // //       return res.status(403).json({ message: 'Invalid token' }); // If token is invalid, reject
// // // // // //     }

// // // // // //     req.user = decoded; // Attach the decoded user data to `req.user`
// // // // // //     next(); // Proceed to the next middleware or route
// // // // // //   });
// // // // // // };
// // // // // const jwt = require('jsonwebtoken');
// // // // // const JWT_SECRET = process.env.JWT_SECRET; // Ensure your JWT_SECRET is in the environment variables

// // // // // // Verify JWT token
// // // // // exports.verifyToken = (req, res, next) => {
// // // // //   const token = req.headers.authorization?.split(' ')[1]; // Get token from Authorization header

// // // // //   if (!token) {
// // // // //     return res.status(403).json({ message: 'No token provided' }); // If no token is found, reject the request
// // // // //   }

// // // // //   jwt.verify(token, JWT_SECRET, (err, decoded) => {
// // // // //     if (err) {
// // // // //       return res.status(403).json({ message: 'Invalid token' }); // If token is invalid, reject
// // // // //     }

// // // // //     req.user = decoded; // Attach the decoded user data to `req.user`
// // // // //     next(); // Proceed to the next middleware or route
// // // // //   });
// // // // // };

// // // // // // Verify if the user is an admin
// // // // // exports.isAdmin = (req, res, next) => {
// // // // //   if (req.user.role !== 'admin') {  // Assuming `role` is part of the JWT payload
// // // // //     return res.status(403).json({ message: 'Forbidden: Admins only' });
// // // // //   }
// // // // //   next(); // Proceed if the user is an admin
// // // // // };

// // // // // // Verify if the user is a regular employee
// // // // // exports.isUser = (req, res, next) => {
// // // // //   if (req.user.role !== 'user') {  // Assuming `role` is part of the JWT payload
// // // // //     return res.status(403).json({ message: 'Forbidden: Employees only' });
// // // // //   }
// // // // //   next(); // Proceed if the user is a regular employee
// // // // // };
// // // // // const jwt = require('jsonwebtoken');
// // // // // const JWT_SECRET = process.env.JWT_SECRET; // Ensure your JWT_SECRET is in your environment variables

// // // // // // Verify JWT token
// // // // // exports.verifyToken = (req, res, next) => {
// // // // //   const token = req.headers.authorization?.split(' ')[1]; // Get token from Authorization header (e.g., "Bearer <token>")

// // // // //   if (!token) {
// // // // //     return res.status(403).json({ message: 'No token provided' }); // If no token is found, reject the request
// // // // //   }

// // // // //   // Verify the token using the secret key
// // // // //   jwt.verify(token, JWT_SECRET, (err, decoded) => {
// // // // //     if (err) {
// // // // //       return res.status(403).json({ message: 'Invalid token' }); // If token is invalid, reject
// // // // //     }

// // // // //     req.user = decoded; // Attach decoded user data to `req.user`
// // // // //     next(); // Proceed to the next middleware or route handler
// // // // //   });
// // // // // };

// // // // // // Check if the user is an admin
// // // // // exports.isAdmin = (req, res, next) => {
// // // // //   if (req.user.role !== 'admin') {  // Assuming `role` is part of the JWT payload
// // // // //     return res.status(403).json({ message: 'Forbidden: Admins only' });
// // // // //   }
// // // // //   next(); // Proceed if the user is an admin
// // // // // };

// // // // // // Check if the user is a regular employee
// // // // // exports.isUser = (req, res, next) => {
// // // // //   if (req.user.role !== 'user') {  // Assuming `role` is part of the JWT payload
// // // // //     return res.status(403).json({ message: 'Forbidden: Employees only' });
// // // // //   }
// // // // //   next(); // Proceed if the user is a regular employee
// // // // // };
// // // // const jwt = require('jsonwebtoken');
// // // // const JWT_SECRET = process.env.JWT_SECRET; // Ensure this is set

// // // // // Verify JWT token
// // // // exports.verifyToken = (req, res, next) => {
// // // //   const token = req.headers.authorization?.split(' ')[1];
// // // //   if (!token) {
// // // //     return res.status(403).json({ message: 'No token provided' });
// // // //   }
// // // //   jwt.verify(token, JWT_SECRET, (err, decoded) => {
// // // //     if (err) {
// // // //       return res.status(403).json({ message: 'Invalid token' });
// // // //     }
// // // //     req.user = decoded;
// // // //     next();
// // // //   });
// // // // };

// // // // // Check if the user is an admin
// // // // exports.isAdmin = (req, res, next) => {
// // // //   if (req.user.role !== 'admin') {
// // // //     return res.status(403).json({ message: 'Forbidden: Admins only' });
// // // //   }
// // // //   next();
// // // // };

// // // // // Check if the user is a regular employee
// // // // exports.isUser = (req, res, next) => {
// // // //   if (req.user.role !== 'user') {
// // // //     return res.status(403).json({ message: 'Forbidden: Employees only' });
// // // //   }
// // // //   next();
// // // // };

// // // // // ——— New: allow either a user *or* an admin ———
// // // // exports.isUserOrAdmin = (req, res, next) => {
// // // //   const role = req.user.role;
// // // //   if (role === 'user' || role === 'admin') {
// // // //     return next();
// // // //   }
// // // //   res.status(403).json({ message: 'Forbidden: User or Admin only' });
// // // // };
// // // // middlewares/authMiddleware.js

// // // const jwt = require('jsonwebtoken');
// // // const JWT_SECRET = process.env.JWT_SECRET; // Ensure this is set in your .env

// // // /**
// // //  * Middleware to verify a JWT and populate req.user
// // //  */
// // // function verifyToken(req, res, next) {
// // //   const authHeader = req.headers.authorization || '';
// // //   const token = authHeader.split(' ')[1];
// // //   if (!token) {
// // //     return res.status(403).json({ message: 'No token provided' });
// // //   }

// // //   jwt.verify(token, JWT_SECRET, (err, decoded) => {
// // //     if (err) {
// // //       return res.status(403).json({ message: 'Invalid token' });
// // //     }
// // //     req.user = decoded;
// // //     next();
// // //   });
// // // }

// // // /**
// // //  * Only allow admins
// // //  */
// // // function isAdmin(req, res, next) {
// // //   if (req.user.role !== 'admin') {
// // //     return res.status(403).json({ message: 'Forbidden: Admins only' });
// // //   }
// // //   next();
// // // }

// // // /**
// // //  * Only allow regular employees
// // //  */
// // // function isUser(req, res, next) {
// // //   if (req.user.role !== 'employee') {
// // //     return res.status(403).json({ message: 'Forbidden: Employees only' });
// // //   }
// // //   next();
// // // }

// // // /**
// // //  * Allow either a user OR an admin
// // //  */
// // // function isUserOrAdmin(req, res, next) {
// // //   const role = req.user.role;
// // //   if (role === 'employee' || role === 'admin') {
// // //     return next();
// // //   }
// // //   return res.status(403).json({ message: 'Forbidden: Employee or Admin only' });
// // // }

// // // module.exports = {
// // //   verifyToken,
// // //   isAdmin,
// // //   isUser,
// // //   isUserOrAdmin,
// // // };
// // // middlewares/authMiddleware.js

// // const jwt = require('jsonwebtoken');
// // const JWT_SECRET = process.env.JWT_SECRET; // Ensure this is set in your .env

// // /**
// //  * Middleware to verify a JWT and populate req.user
// //  */
// // function verifyToken(req, res, next) {
// //   const authHeader = req.headers.authorization || '';
// //   const token = authHeader.split(' ')[1];
// //   if (!token) {
// //     return res.status(403).json({ message: 'No token provided' });
// //   }

// //   jwt.verify(token, JWT_SECRET, (err, decoded) => {
// //     if (err) {
// //       return res.status(403).json({ message: 'Invalid token' });
// //     }
// //     req.user = decoded;
// //     next();
// //   });
// // }

// // /**
// //  * Only allow admins
// //  */
// // function isAdmin(req, res, next) {
// //   if (req.user.role !== 'admin') {
// //     return res.status(403).json({ message: 'Forbidden: Admins only' });
// //   }
// //   next();
// // }

// // /**
// //  * Only allow regular employees
// //  */
// // function isUser(req, res, next) {
// //   // Allow both "employee" and "user" roles
// //   if (req.user.role !== 'employee' && req.user.role !== 'user') {
// //     return res.status(403).json({ message: 'Forbidden: Employees only' });
// //   }
// //   next();
// // }

// // /**
// //  * Allow either a user OR an admin
// //  */
// // function isUserOrAdmin(req, res, next) {
// //   const role = req.user.role;
// //   if (role === 'employee' || role === 'admin' || role === 'user') {
// //     return next();
// //   }
// //   return res.status(403).json({ message: 'Forbidden: Employee or Admin only' });
// // }

// // module.exports = {
// //   verifyToken,
// //   isAdmin,
// //   isUser,
// //   isUserOrAdmin,
// // };
// // middlewares/authMiddleware.js

// const jwt = require('jsonwebtoken');
// const JWT_SECRET = process.env.JWT_SECRET; // Make sure you have this in your .env

// /**
//  * Middleware to verify a JWT and populate req.user
//  */
// function verifyToken(req, res, next) {
//   const authHeader = req.headers.authorization || '';
//   const parts = authHeader.split(' ');
//   if (parts.length !== 2 || parts[0] !== 'Bearer') {
//     return res.status(401).json({ message: 'No token provided or bad format' });
//   }

//   const token = parts[1];
//   jwt.verify(token, JWT_SECRET, (err, decoded) => {
//     if (err) {
//       return res.status(403).json({ message: 'Invalid or expired token' });
//     }
//     req.user = decoded;
//     next();
//   });
// }

// /**
//  * Only allow admins
//  */
// function isAdmin(req, res, next) {
//   if ((req.user.role || '').toLowerCase() !== 'admin') {
//     return res.status(403).json({ message: 'Forbidden: Admins only' });
//   }
//   next();
// }

// /**
//  * Only allow regular employees
//  */
// function isUser(req, res, next) {
//   const role = (req.user.role || '').toLowerCase();
//   if (role !== 'employee' && role !== 'user') {
//     return res.status(403).json({ message: 'Forbidden: Employees only' });
//   }
//   next();
// }

// /**
//  * Allow either a user OR an admin
//  */
// function isUserOrAdmin(req, res, next) {
//   const role = (req.user.role || '').toLowerCase();
//   if (role === 'admin' || role === 'employee' || role === 'user') {
//     return next();
//   }
//   return res.status(403).json({ message: 'Forbidden: Employee or Admin only' });
// }

// module.exports = {
//   verifyToken,
//   isAdmin,
//   isUser,
//   isUserOrAdmin,
// };
// middleware/auth.js
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
