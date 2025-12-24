/**
 * Meta WhatsApp Cloud API Webhook Handler
 * Production endpoint: https://<YOUR_DOMAIN>/webhooks/whatsapp
 * 
 * CRITICAL CONSTRAINTS:
 * - /webhooks/whatsapp must remain public (no auth)
 * - GET = verification only
 * - POST = async, fast 200, side effects only
 * - Slack posting must never block response
 * - Firestore writes must never block response
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
import {
  postToSlack,
  formatWhatsAppMessageForSlack,
} from '@/lib/slack';

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
 * CRITICAL CONSTRAINTS (stable public contract):
 * - Must remain public (no auth middleware)
 * - Must respond 200 immediately (before any processing)
 * - All side effects (Slack, Firestore) must be async/non-blocking
 * - Slack posting must never block response
 * - Firestore writes must never block response
 * 
 * Implementation:
 * - Verify X-Hub-Signature-256 header (if META_APP_SECRET configured)
 * - Respond 200 OK immediately
 * - Process payload asynchronously (fire-and-forget)
 * - Write to Firestore clientMessages collection
 * - Post to Slack channels (parallel with Firestore, non-blocking)
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
  console.log('Starting async webhook payload processing');
  processWebhookPayload(rawBody).catch((error) => {
    console.error('Error processing webhook payload:', error);
    console.error('Error stack:', error instanceof Error ? error.stack : 'No stack trace');
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
    console.log('Processing webhook payload, rawBody length:', rawBody.length);
    const body: WhatsAppWebhookPayload = JSON.parse(rawBody);
    console.log('Parsed payload:', {
      object: body.object,
      hasEntry: !!body.entry,
      entryCount: body.entry?.length || 0,
    });

    // Validate payload structure
    if (!body.object || !body.entry || !Array.isArray(body.entry)) {
      console.warn('Invalid webhook payload structure:', {
        hasObject: !!body.object,
        hasEntry: !!body.entry,
        entryIsArray: Array.isArray(body.entry),
        rawBodyPreview: rawBody.substring(0, 200),
      });
      return;
    }

    // Process each entry
    for (const entry of body.entry) {
      if (!entry.changes || !Array.isArray(entry.changes)) {
        continue;
      }

      for (const change of entry.changes) {
        console.log('Processing change:', {
          field: change.field,
          hasMessages: !!change.value?.messages,
          messageCount: change.value?.messages?.length || 0,
        });
        
        // Only process messages, ignore status updates
        if (change.field !== 'messages' || !change.value.messages) {
          console.log('Skipping change - not a message field or no messages');
          continue;
        }

        const messages = change.value.messages;
        const phoneNumberId = change.value.metadata?.phone_number_id;
        const displayPhoneNumber = change.value.metadata?.display_phone_number;

        console.log(`Processing ${messages.length} message(s)`);
        
        // Process each message
        for (const message of messages) {
          console.log('Processing message:', {
            from: message.from,
            type: message.type,
            messageId: message.id,
          });
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
    console.log(`Looking up client for WhatsApp number: ${from}`);
    const client = await findClientByWhatsAppNumber(from);
    const clientId = client?.clientId || null;
    console.log('Client lookup result:', {
      found: !!client,
      clientId: clientId,
      slackChannelId: client?.slackChannelId || 'none',
    });

    // Prepare Firestore document
    const messageData = {
      clientId,
      channel: 'whatsapp',
      source: 'whatsapp',
      status: 'received',
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

    // Fire Slack and Firestore operations in parallel (fire-and-forget)
    // Neither operation blocks the HTTP response (already sent)
    // They also don't block each other
    
    // Post to Slack (non-blocking)
    if (client) {
      // Client found - post to client's Slack channel
      const { text: slackText, blocks } = formatWhatsAppMessageForSlack({
        from,
        body: text || body || '',
        clientName: client.displayName,
      });

      postToSlack({
        channel: client.slackChannelId,
        text: slackText,
        blocks,
      }).catch((error) => {
        console.error(`Error posting to Slack channel ${client.slackChannelId}:`, error);
      });

      console.log(
        `Message from ${from} mapped to client ${client.clientId}, posting to Slack channel ${client.slackChannelId}`
      );
    } else {
      // Client not found - post to fallback channel
      const fallbackChannelId = process.env.SLACK_FALLBACK_CHANNEL_ID;

      if (fallbackChannelId) {
        const { text: slackText, blocks } = formatWhatsAppMessageForSlack({
          from,
          body: text || body || '',
        });

        const warningText = `⚠️ Unmapped WhatsApp sender\n${slackText}`;
        const warningBlocks = [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: '*⚠️ Unmapped WhatsApp sender*',
            },
          },
          ...blocks,
        ];

        postToSlack({
          channel: fallbackChannelId,
          text: warningText,
          blocks: warningBlocks,
        }).catch((error) => {
          console.error(`Error posting to Slack fallback channel:`, error);
        });

        console.log(`Unmapped message from ${from}, posting to fallback channel`);
      }
    }

    // Write to Firestore (non-blocking)
    createClientMessage(messageData).catch((error) => {
      console.error('Error writing to Firestore:', error);
    });

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
