// functions/src/services/registrationDeliveryService.ts

/**
 * Delivery providers for registration OTP codes.
 *
 * Email: real SMTP delivery via nodemailer when SMTP_* env config exists;
 * otherwise a DEV-emulator-only test delivery that exposes the code in a
 * `devCode` response field — only when FUNCTIONS_EMULATOR === 'true'.
 *
 * SMS: no real provider is configured. A simulated provider returns the
 * code via `devCode` in the emulator only. In production it is disabled.
 */

let nodemailer: any = null;
try {
  nodemailer = require('nodemailer');
} catch (_) {
  nodemailer = null;
}

export const isEmulator = (): boolean =>
  process.env.FUNCTIONS_EMULATOR === 'true';

export interface DeliveryResult {
  /** 'smtp' = real email sent; 'dev' = emulator-only test delivery. */
  mode: 'smtp' | 'dev' | 'unavailable';
  /** Only set in DEV emulator mode — never populate in production. */
  devCode?: string;
}

function makeTransport(): any | null {
  if (!nodemailer) return null;
  if (
    !process.env.SMTP_HOST ||
    !process.env.SMTP_USER ||
    !process.env.SMTP_PASS
  ) {
    return null;
  }
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
}

/** Delivers an email OTP — real SMTP if configured, else DEV fallback. */
export async function sendEmailOtp(
  to: string,
  code: string,
): Promise<DeliveryResult> {
  const mailer = makeTransport();
  if (mailer) {
    await mailer.sendMail({
      from:
        process.env.SMTP_FROM || `SERV App <${process.env.SMTP_USER}>`,
      to,
      subject: 'SERV Organization Registration — Verification Code',
      text:
        `Your SERV organization registration verification code is ${code}.\n\n` +
        `It expires in 10 minutes. If you did not request this, ignore this email.`,
    });
    return { mode: 'smtp' };
  }
  // DEV emulator-only test delivery — never reachable in production.
  if (isEmulator()) {
    return { mode: 'dev', devCode: code };
  }
  return { mode: 'unavailable' };
}

/**
 * SMS provider interface — a real provider (Twilio/Firebase Phone Auth)
 * plugs in here in a later milestone. Currently only the simulated
 * DEV provider exists.
 */
export interface SmsProvider {
  name: string;
  sendOtp(to: string, code: string): Promise<DeliveryResult>;
}

class SimulatedSmsProvider implements SmsProvider {
  name = 'simulated-dev';
  async sendOtp(_to: string, code: string): Promise<DeliveryResult> {
    return { mode: 'dev', devCode: code };
  }
}

let _simulated: SimulatedSmsProvider | null = null;

function getSmsProvider(): SmsProvider | null {
  // The simulated provider is resolvable ONLY under the Functions emulator —
  // it can never deliver (or pretend to deliver) in production.
  if (!isEmulator()) return null;
  return (_simulated ??= new SimulatedSmsProvider());
}

export async function sendSmsOtp(
  to: string,
  code: string,
): Promise<DeliveryResult> {
  const provider = getSmsProvider();
  if (!provider) return { mode: 'unavailable' };
  return provider.sendOtp(to, code);
}
