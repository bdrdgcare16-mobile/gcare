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
exports.isAdmin = exports.isAdminOrSuperAdmin = exports.verifyToken = exports.roleMiddleware = exports.authMiddleware = void 0;
const jwt = __importStar(require("jsonwebtoken"));
const params_1 = require("firebase-functions/params");
const firebase_1 = require("../config/firebase");
const jwtSecret = (0, params_1.defineString)('JWT_SECRET', { default: 'your-default-jwt-secret' });
function getToken(req) {
    const h = (req.headers.authorization || req.headers.Authorization || '');
    if (typeof h === 'string') {
        const [scheme, token] = h.split(' ');
        if (scheme && token && /^Bearer$/i.test(scheme))
            return token.trim();
    }
    if (req.headers['x-access-token'])
        return String(req.headers['x-access-token']).trim();
    return null;
}
const authMiddleware = async (req, res, next) => {
    try {
        const token = getToken(req);
        if (!token)
            return res.status(401).json({ message: 'No token provided' });
        return new Promise((resolve) => {
            jwt.verify(token, jwtSecret.value(), async (err, decoded) => {
                if (err) {
                    res.status(403).json({ message: 'Invalid or expired token' });
                    return resolve();
                }
                const jwtPayload = decoded;
                try {
                    const userDoc = await firebase_1.db.collection('users').doc(jwtPayload.userId).get();
                    if (!userDoc.exists) {
                        res.status(401).json({ message: 'User not found' });
                        return resolve();
                    }
                    // ⬇️ include empid, if present in token
                    req.user = {
                        userId: jwtPayload.userId,
                        email: jwtPayload.email,
                        role: jwtPayload.role,
                        empid: jwtPayload.empid ?? null,
                    };
                    next();
                    resolve();
                }
                catch (error) {
                    console.error('Error checking user existence:', error);
                    res.status(500).json({ message: 'Internal server error' });
                    resolve();
                }
            });
        });
    }
    catch (error) {
        console.error('Auth middleware error:', error);
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
    }
};
exports.authMiddleware = authMiddleware;
const roleMiddleware = (roles) => {
    return (req, res, next) => {
        if (!req.user)
            return res.status(401).json({ error: 'Not authenticated' });
        if (!roles.includes(req.user.role))
            return res.status(403).json({ error: 'Not authorized' });
        next();
    };
};
exports.roleMiddleware = roleMiddleware;
exports.verifyToken = exports.authMiddleware;
const isAdminOrSuperAdmin = (req, res, next) => (0, exports.roleMiddleware)(['admin', 'super_admin'])(req, res, next);
exports.isAdminOrSuperAdmin = isAdminOrSuperAdmin;
exports.isAdmin = (0, exports.roleMiddleware)(['admin', 'super_admin']);
//# sourceMappingURL=authMiddleware.js.map