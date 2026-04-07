import jwt, { Secret, SignOptions } from "jsonwebtoken";

const JWT_SECRET: Secret = process.env.JWT_SECRET || "local-dev-secret";
const JWT_EXPIRES = process.env.JWT_EXPIRES_IN || "24h";

export interface JwtPayload {
  userId: string;
  email: string;
  role: string;
  empid?: string | null;
  [key: string]: any;
}

export const issueToken = (payload: JwtPayload): string => {
  const options: SignOptions = {
    expiresIn: JWT_EXPIRES as any,
  };

  console.log('JWT_SECRET present in issueToken:', !!process.env.JWT_SECRET);
  console.log('JWT_SECRET length in issueToken:', (process.env.JWT_SECRET || '').length);

  return jwt.sign(payload, JWT_SECRET, options);
};

export const getJwtExpires = (): string => {
  return JWT_EXPIRES;
};