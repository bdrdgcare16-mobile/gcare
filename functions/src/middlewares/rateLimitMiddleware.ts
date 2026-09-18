import { Request } from 'express';
import rateLimit, { Options } from 'express-rate-limit';

const EMULATOR_IP = '127.0.0.1';

export function getClientIp(req: Request): string {
  if (req.ip) {
    return req.ip;
  }

  const socketIp = req.socket?.remoteAddress;
  if (socketIp) {
    return socketIp;
  }

  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return EMULATOR_IP;
  }

  throw new Error('Unable to determine client IP for rate limiting');
}

export const safeKeyGenerator = (req: Request): string => {
  return getClientIp(req);
};

const baseOptions: Partial<Options> = {
  standardHeaders: true,
  legacyHeaders: false,
  validate: { ip: false },
  keyGenerator: safeKeyGenerator,
};

// General rate limiter for all API endpoints
export const generalRateLimit = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Limit each IP to 1000 requests per windowMs
  message: {
    status: 'error',
    message: 'Too many requests from this IP, please try again later.',
  },
});

// Rate limiter for authentication endpoints
export const authRateLimit = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Limit each IP to 300 auth requests per windowMs
  message: {
    status: 'error',
    message: 'Too many authentication attempts, please try again later.',
  },
  skip: () => false, // Apply to all auth requests for security
});

// Rate limiter for attendance endpoints
export const attendanceRateLimit = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 attendance requests per windowMs
  message: {
    status: 'error',
    message: 'Too many attendance requests, please try again later.',
  },
});

// Rate limiter for tracking endpoints
export const trackingRateLimit = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Limit each IP to 200 tracking requests per windowMs
  message: {
    status: 'error',
    message: 'Too many tracking requests, please try again later.',
  },
});

// Rate limiter for file uploads
export const uploadRateLimit = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Limit each IP to 20 upload requests per windowMs
  message: {
    status: 'error',
    message: 'Too many upload requests, please try again later.',
  },
});
