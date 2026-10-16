import * as crypto from "crypto";

/**
 * HR-supplied employee passwords are captured at onboarding submission but
 * only materialize into Firebase Auth at Company Admin approval. A one-way
 * hash cannot be used for auth.createUser(), so the value is stored
 * AES-256-GCM encrypted in the onboarding document and decrypted only
 * inside provisioning (or Auth-identity repair). It is scrubbed from all
 * API read paths.
 *
 * The key derives from ONBOARDING_CREDENTIAL_KEY (falling back to the
 * service JWT secret) — never from any value stored next to the ciphertext.
 */

const VERSION = "v1";
const IV_BYTES = 12;

const key = (): Buffer =>
  crypto
    .createHash("sha256")
    .update(
      process.env.ONBOARDING_CREDENTIAL_KEY ||
        process.env.JWT_SECRET ||
        "serv-dev-credential-key"
    )
    .digest();

export const encryptCredential = (plain: string): string => {
  const iv = crypto.randomBytes(IV_BYTES);
  const cipher = crypto.createCipheriv("aes-256-gcm", key(), iv);
  const ciphertext = Buffer.concat([
    cipher.update(plain, "utf8"),
    cipher.final(),
  ]);
  return [
    VERSION,
    iv.toString("base64"),
    cipher.getAuthTag().toString("base64"),
    ciphertext.toString("base64"),
  ].join(".");
};

export const decryptCredential = (payload: string): string => {
  const [version, ivB64, tagB64, ctB64] = String(payload).split(".");
  if (version !== VERSION || !ivB64 || !tagB64 || !ctB64) {
    throw new Error("Invalid credential payload");
  }
  const decipher = crypto.createDecipheriv(
    "aes-256-gcm",
    key(),
    Buffer.from(ivB64, "base64")
  );
  decipher.setAuthTag(Buffer.from(tagB64, "base64"));
  return Buffer.concat([
    decipher.update(Buffer.from(ctB64, "base64")),
    decipher.final(),
  ]).toString("utf8");
};
