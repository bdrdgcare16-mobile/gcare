import rateLimit, { ipKeyGenerator } from 'express-rate-limit';

// General rate limiter for all API endpoints
export const generalRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Limit each IP to 1000 requests per windowMs
  message: {
    status: 'error',
    message: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiter for authentication endpoints
export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Limit each IP to 300 auth requests per windowMs (reasonable for testing/normal usage)
  message: {
    status: 'error',
    message: 'Too many authentication attempts, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Use ipKeyGenerator for IPv6 compatibility
    return ipKeyGenerator(req.ip || req.socket.remoteAddress || 'unknown');
  },
  skip: (req) => {
    // Skip rate limiting for successful requests (optional optimization)
    return false; // Apply to all auth requests for security
  }
});

// Rate limiter for attendance endpoints
export const attendanceRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 attendance requests per windowMs
  message: {
    status: 'error',
    message: 'Too many attendance requests, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiter for tracking endpoints
export const trackingRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Limit each IP to 200 tracking requests per windowMs
  message: {
    status: 'error',
    message: 'Too many tracking requests, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiter for file uploads
export const uploadRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Limit each IP to 20 upload requests per windowMs
  message: {
    status: 'error',
    message: 'Too many upload requests, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});
