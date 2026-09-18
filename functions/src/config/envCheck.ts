/**
 * Controlled production configuration check.
 * Never prints secret values.
 */

export const REQUIRED_ENV_KEYS = [
  'APP_FIREBASE_PROJECT_ID',
  'APP_STORAGE_BUCKET',
  'RESET_CONTINUE_URL',
  'JWT_SECRET',
] as const;

export interface EnvCheckResult {
  ok: boolean;
  missing: string[];
}

export function checkRequiredEnv(): EnvCheckResult {
  const missing: string[] = [];

  for (const key of REQUIRED_ENV_KEYS) {
    const value = process.env[key];
    if (!value || (value.trim?.() ?? value) === '') {
      missing.push(key);
    }
  }

  return {
    ok: missing.length === 0,
    missing,
  };
}
