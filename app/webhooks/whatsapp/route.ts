/**
 * Meta WhatsApp Cloud API Webhook Handler
 * Production endpoint: https://<YOUR_DOMAIN>/webhooks/whatsapp
 * 
 * Handles:
 * - GET: Webhook verification (Meta subscription)
 * - POST: Message receiving and Firestore storage
 */

import { NextRequest, NextResponse } from 'next/server';
import type {
  WhatsAppWebhookPayload,
  WhatsAppMessage,
} from '@/types/whatsapp';
import { findClientByWhatsAppNumber, createClientMessage } from '@/lib/clientComms';
import { verifyMetaWebhookSignature } from '@/lib/webhookVerification';

/**
 * GET /webhooks/whatsapp
 * Webhook verification endpoint for Meta WhatsApp Cloud API
 * 
 * Meta sends: ?hub.mode=subscribe&hub.verify_token=TOKEN&hub.challenge=CHALLENGE
 * We respond: 200 with challenge if token matches, else 403
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const mode = searchParams.get('hub.mode');
    const verifyToken = searchParams.get('hub.verify_token');
    const challenge = searchParams.get('hub.challenge');

    // Validate verification request
    const expectedToken = process.env.WHATSAPP_VERIFY_TOKEN || 'readyaimgo_whatsapp_verify_2025';
    
    if (mode === 'subscribe' && verifyToken === expectedToken) {
      // Return challenge as plain text (Meta requirement)
      return new NextResponse(challenge || '', {
        status: 200,
        headers: {
          'Content-Type': 'text/plain',
        },
      });
    }

    // Invalid verification request
    console.warn('Invalid webhook verification attempt', {
      mode,
      tokenMatch: verifyToken === expectedToken,
    });
    
    return new NextResponse('Forbidden', {
      status: 403,
    });
  } catch (error) {
    console.error('Error in WhatsApp webhook verification:', error);
    return new NextResponse('Internal Server Error', {
      status: 500,
    });
  }
}

/**
 * POST /webhooks/whatsapp
 * Message receive endpoint for Meta WhatsApp Cloud API
 * 
 * Requirements:
 * - Respond 200 quickly (before processing)
 * - Verify X-Hub-Signature-256 header
 * - Parse payload and write to Firestore clientMessages collection
 * - Include: clientId, channel: "whatsapp", createdAt, status: "received", raw, text/body
 */
export async function POST(request: NextRequest) {
  // Get raw body for signature verification
  const rawBody = await request.text();
  
  // Verify signature if META_APP_SECRET is configured
  const appSecret = process.env.META_APP_SECRET;
  if (appSecret) {
    const signature = request.headers.get('X-Hub-Signature-256');
    const isValid = verifyMetaWebhookSignature(rawBody, signature, appSecret);
    
    if (!isValid) {
      console.error('Invalid webhook signature', {
        signature: signature?.substring(0, 20) + '...',
        hasSecret: !!appSecret,
      });
      return new NextResponse('Unauthorized', {
        status: 401,
      });
    }
  } else {
    console.warn('META_APP_SECRET not configured - skipping signature verification');
  }

  // Respond quickly to Meta (200 OK) before processing
  // This prevents Meta from retrying if processing takes time
  const response = new NextResponse('OK', {
    status: 200,
  });

  // Process payload asynchronously (don't await)
  processWebhookPayload(rawBody).catch((error) => {
    console.error('Error processing webhook payload:', error);
    // Log error but don't retry (we already responded 200)
  });

  return response;
}

/**
 * Process webhook payload and write to Firestore
 * Called asynchronously after responding to Meta
 */
async function processWebhookPayload(rawBody: string): Promise<void> {
  try {
    const body: WhatsAppWebhookPayload = JSON.parse(rawBody);

    // Validate payload structure
    if (!body.object || !body.entry || !Array.isArray(body.entry)) {
      console.warn('Invalid webhook payload structure:', {
        hasObject: !!body.object,
        hasEntry: !!body.entry,
        entryIsArray: Array.isArray(body.entry),
      });
      return;
    }

    // Process each entry
    for (const entry of body.entry) {
      if (!entry.changes || !Array.isArray(entry.changes)) {
        continue;
      }

      for (const change of entry.changes) {
        // Only process messages, ignore status updates
        if (change.field !== 'messages' || !change.value.messages) {
          continue;
        }

        const messages = change.value.messages;
        const phoneNumberId = change.value.metadata?.phone_number_id;
        const displayPhoneNumber = change.value.metadata?.display_phone_number;

        // Process each message
        for (const message of messages) {
          await processWhatsAppMessage(message, {
            phoneNumberId,
            displayPhoneNumber,
            contacts: change.value.contacts,
            rawPayload: body,
          });
        }
      }
    }
  } catch (error) {
    console.error('Error parsing webhook payload:', error);
    throw error;
  }
}

/**
 * Process a single WhatsApp message and write to Firestore
 */
async function processWhatsAppMessage(
  message: WhatsAppMessage,
  context: {
    phoneNumberId?: string;
    displayPhoneNumber?: string;
    contacts?: Array<{ profile?: { name?: string }; wa_id: string }>;
    rawPayload: WhatsAppWebhookPayload;
  }
): Promise<void> {
  try {
    const from = message.from;
    const messageId = message.id;
    const timestamp = message.timestamp;
    
    // Extract message text/body
    let text: string | undefined;
    let body: string | undefined;
    
    if (message.type === 'text' && message.text?.body) {
      text = message.text.body;
      body = message.text.body;
    } else {
      // Handle other message types (image, document, etc.)
      body = `[${message.type} message]`;
      text = body;
    }

    // Extract profile name if available
    const profileName =
      context.contacts?.find((c) => c.wa_id === from)?.profile?.name ||
      message.profile?.name;

    // Look up client by WhatsApp number
    const client = await findClientByWhatsAppNumber(from);
    const clientId = client?.clientId || null;

    // Prepare Firestore document
    // Note: Using status: "received" per requirements
    // To enable automatic Slack posting, either:
    // 1. Change this to status: "pending" (triggers Firestore function)
    // 2. Update Firestore trigger to accept "received" status
    // 3. Add a separate process to update status to "pending"
    const messageData = {
      clientId,
      channel: 'whatsapp',
      source: 'whatsapp',
      status: 'received', // Per requirements - change to "pending" for auto Slack posting
      from,
      text,
      body,
      timestamp,
      messageId,
      raw: {
        phoneNumberId: context.phoneNumberId,
        displayPhoneNumber: context.displayPhoneNumber,
        profileName,
        messageType: message.type,
        fullPayload: context.rawPayload,
      },
    };

    // Write to Firestore
    await createClientMessage(messageData);

    console.log('WhatsApp message saved to Firestore', {
      messageId,
      clientId,
      from,
      hasText: !!text,
    });
  } catch (error) {
    console.error('Error processing WhatsApp message:', error);
    // Don't throw - we want to continue processing other messages
  }
}
