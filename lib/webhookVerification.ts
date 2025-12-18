/**
 * Meta WhatsApp webhook signature verification
 * Validates X-Hub-Signature-256 header using HMAC SHA256
 */

import crypto from 'crypto';

/**
 * Verify Meta webhook signature
 * @param payload - Raw request body as string
 * @param signature - X-Hub-Signature-256 header value (format: "sha256=...")
 * @param secret - META_APP_SECRET from environment
 * @returns true if signature is valid
 */
export function verifyMetaWebhookSignature(
  payload: string,
  signature: string | null,
  secret: string
): boolean {
  if (!signature) {
    return false;
  }

  // Extract hash from signature header (format: "sha256=...")
  const hash = signature.replace('sha256=', '');

  // Calculate expected signature
  const expectedHash = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');

  // Compare hashes using constant-time comparison to prevent timing attacks
  return crypto.timingSafeEqual(
    Buffer.from(hash),
    Buffer.from(expectedHash)
  );
}
