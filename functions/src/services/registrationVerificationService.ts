// functions/src/services/registrationVerificationService.ts

import { createHash, randomInt } from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { getDb } from '../config/firebase';

/**
 * Registration contact-verification service.
 *
 * OTP lifecycle records live in `registrationOtps/{registrationId}_{channel}`.
 * Only the SHA-256 hash of `code + registrationId + channel` is stored —
 * a plaintext OTP never touches Firestore, and a code minted for one
 * registration cannot verify another.
 */

export const REGISTRATION_OTPS_COL = 'registrationOtps';

export type VerificationChannel = 'orgEmail' | 'adminEmail' | 'adminMobile';

export const VERIFICATION_CHANNELS: ReadonlySet<string> = new Set([
  'orgEmail',
  'adminEmail',
  'adminMobile',
]);

export const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes
export const OTP_MAX_ATTEMPTS = 5;
export const OTP_RESEND_COOLDOWN_MS = 60 * 1000; // 60 seconds

export interface VerificationState {
  verified: boolean;
  target: string;
  verifiedAt?: FirebaseFirestore.FieldValue | Date | null;
}

export interface RegistrationVerificationMap {
  orgEmail: VerificationState;
  adminEmail: VerificationState;
  adminMobile: VerificationState;
}

export const EMPTY_VERIFICATION: RegistrationVerificationMap = {
  orgEmail: { verified: false, target: '' },
  adminEmail: { verified: false, target: '' },
  adminMobile: { verified: false, target: '' },
};

interface OtpRecord {
  registrationId: string;
  channel: VerificationChannel;
  destination: string;
  codeHash: string;
  attempts: number;
  lastSentAt: Date;
  expiresAt: Date;
  verified: boolean;
}

function otpDocId(registrationId: string, channel: string): string {
  return `${registrationId}_${channel}`;
}

function hashCode(code: string, registrationId: string, channel: string) {
  // Binding registrationId + channel into the digest makes a captured code
  // useless against any other application or contact.
  return createHash('sha256')
    .update(`${registrationId}:${channel}:${code}`)
    .digest('hex');
}

export function generateOtp(): string {
  return randomInt(0, 1000000).toString().padStart(6, '0');
}

export class OtpError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly retryAfterSeconds?: number,
  ) {
    super(message);
  }
}

/**
 * Which channels must be verified for this registration.
 * The admin email only requires verification when it differs from the
 * organization official email.
 */
export function requiredChannels(reg: {
  organization?: { officialEmail?: string };
  adminContact?: { email?: string; mobile?: string };
}): VerificationChannel[] {
  const channels: VerificationChannel[] = ['orgEmail', 'adminMobile'];
  const orgEmail = (reg.organization?.officialEmail || '').trim().toLowerCase();
  const adminEmail = (reg.adminContact?.email || '').trim().toLowerCase();
  if (adminEmail && adminEmail !== orgEmail) channels.push('adminEmail');
  return channels;
}

/** Destination (email/phone) a channel currently points at. */
export function channelDestination(
  reg: {
    organization?: { officialEmail?: string };
    adminContact?: { email?: string; mobile?: string };
  },
  channel: VerificationChannel,
): string {
  switch (channel) {
    case 'orgEmail':
      return (reg.organization?.officialEmail || '').trim().toLowerCase();
    case 'adminEmail':
      return (reg.adminContact?.email || '').trim().toLowerCase();
    case 'adminMobile':
      return (reg.adminContact?.mobile || '').trim();
  }
}

/**
 * Issues a new OTP for a channel. Enforces the 60-second resend cooldown;
 * issuing a new OTP overwrites (invalidates) the previous one.
 * Returns the plaintext OTP — callers deliver it via the appropriate
 * provider and must never log it.
 */
export async function issueOtp(
  registrationId: string,
  channel: VerificationChannel,
  destination: string,
): Promise<{ code: string }> {
  if (!destination) {
    throw new OtpError('No contact on file for this verification channel', 400);
  }

  const ref = getDb().collection(REGISTRATION_OTPS_COL).doc(
    otpDocId(registrationId, channel),
  );
  const snap = await ref.get();
  if (snap.exists) {
    const lastSent = (snap.data() as OtpRecord).lastSentAt;
    const lastSentMs =
      lastSent instanceof Date ? lastSent.getTime() : (lastSent as any)?.toDate?.().getTime();
    if (lastSentMs) {
      const waitMs = OTP_RESEND_COOLDOWN_MS - (Date.now() - lastSentMs);
      if (waitMs > 0) {
        throw new OtpError(
          'Please wait before requesting a new code',
          429,
          Math.ceil(waitMs / 1000),
        );
      }
    }
  }

  const code = generateOtp();
  const now = new Date();
  const record: OtpRecord = {
    registrationId,
    channel,
    destination,
    codeHash: hashCode(code, registrationId, channel),
    attempts: 0,
    lastSentAt: now,
    expiresAt: new Date(now.getTime() + OTP_TTL_MS),
    verified: false,
  };
  await ref.set(record);
  return { code };
}

/** Deletes any outstanding OTP for a channel (contact changed). */
export async function clearOtp(
  registrationId: string,
  channel: VerificationChannel,
): Promise<void> {
  await getDb()
    .collection(REGISTRATION_OTPS_COL)
    .doc(otpDocId(registrationId, channel))
    .delete()
    .catch(() => {});
}

/**
 * Confirms an OTP. On success: marks the code verified (single-use) and
 * stamps the verification flag + target + server timestamp onto the
 * registration document.
 */
export async function confirmOtp(
  registrationId: string,
  channel: VerificationChannel,
  code: string,
): Promise<void> {
  const ref = getDb().collection(REGISTRATION_OTPS_COL).doc(
    otpDocId(registrationId, channel),
  );
  const snap = await ref.get();
  if (!snap.exists) {
    throw new OtpError('No verification code was requested', 400);
  }
  const rec = snap.data() as OtpRecord;

  if (rec.verified) {
    throw new OtpError('This code has already been used', 400);
  }
  const expiresMs =
    rec.expiresAt instanceof Date
      ? rec.expiresAt.getTime()
      : (rec.expiresAt as any)?.toDate?.().getTime();
  if (expiresMs && expiresMs < Date.now()) {
    throw new OtpError('This code has expired. Please request a new one', 400);
  }
  if (rec.attempts >= OTP_MAX_ATTEMPTS) {
    throw new OtpError(
      'Too many incorrect attempts. Please request a new code',
      429,
    );
  }

  const expected = hashCode(code, registrationId, channel);
  if (expected !== rec.codeHash) {
    await ref.update({ attempts: FieldValue.increment(1) });
    const remaining = OTP_MAX_ATTEMPTS - (rec.attempts + 1);
    throw new OtpError(
      `Incorrect code${remaining > 0 ? ` — ${remaining} attempt(s) remaining` : ''}`,
      400,
    );
  }

  const now = FieldValue.serverTimestamp();
  const batch = getDb().batch();
  batch.update(ref, { verified: true });
  batch.update(
    getDb().collection('organizationRegistrations').doc(registrationId),
    {
      [`verification.${channel}`]: {
        verified: true,
        target: rec.destination,
        verifiedAt: now,
      },
      updatedAt: now,
      auditTrail: FieldValue.arrayUnion({
        at: new Date(),
        action: `verified_${channel}`,
        actor: 'applicant',
      }),
    },
  );
  await batch.commit();
}
