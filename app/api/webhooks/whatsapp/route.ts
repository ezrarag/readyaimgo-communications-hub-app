/**
 * WhatsApp Cloud API Webhook Handler
 * Handles both verification (GET) and message receiving (POST)
 */

import { NextRequest, NextResponse } from 'next/server';
import type {
  WhatsAppWebhookPayload,
  WhatsAppWebhookVerification,
  WhatsAppMessage,
} from '@/types/whatsapp';
import { findClientByWhatsAppNumber, saveInboundMessage } from '@/lib/clientComms';
import {
  postToSlack,
  formatWhatsAppMessageForSlack,
} from '@/lib/slack';

/**
 * GET /api/webhooks/whatsapp
 * Webhook verification endpoint for Meta WhatsApp Cloud API
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const mode = searchParams.get('hub.mode');
    const verifyToken = searchParams.get('hub.verify_token');
    const challenge = searchParams.get('hub.challenge');

    // Validate verification request
    if (
      mode === 'subscribe' &&
      verifyToken === process.env.WHATSAPP_VERIFY_TOKEN
    ) {
      // Return challenge as plain text
      return new NextResponse(challenge || '', {
        status: 200,
        headers: {
          'Content-Type': 'text/plain',
        },
      });
    }

    // Invalid verification request
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
 * POST /api/webhooks/whatsapp
 * Message receive endpoint for Meta WhatsApp Cloud API
 */
export async function POST(request: NextRequest) {
  try {
    const body: WhatsAppWebhookPayload = await request.json();

    // Validate payload structure
    if (!body.object || !body.entry || !Array.isArray(body.entry)) {
      if (process.env.NODE_ENV === 'development') {
        console.log('Invalid webhook payload structure:', body);
      }
      return new NextResponse('Invalid payload', {
        status: 400,
      });
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

        // Process each message
        for (const message of messages) {
          // Only process text messages for now
          if (message.type !== 'text' || !message.text) {
            if (process.env.NODE_ENV === 'development') {
              console.log('Ignoring non-text message:', message.type);
            }
            continue;
          }

          await processWhatsAppMessage(message, change.value.contacts);
        }
      }
    }

    // Respond quickly to Meta (200 OK)
    return new NextResponse('OK', {
      status: 200,
    });
  } catch (error) {
    console.error('Error processing WhatsApp webhook:', error);
    // Still return 200 to Meta to prevent retries for malformed payloads
    return new NextResponse('OK', {
      status: 200,
    });
  }
}

/**
 * Process a single WhatsApp message
 */
async function processWhatsAppMessage(
  message: WhatsAppMessage,
  contacts?: Array<{ profile?: { name?: string }; wa_id: string }>
): Promise<void> {
  try {
    const from = message.from;
    const body = message.text?.body || '';
    const timestamp = message.timestamp;
    const messageId = message.id;

    // Extract profile name if available
    const profileName =
      contacts?.find((c) => c.wa_id === from)?.profile?.name ||
      message.profile?.name;

    // Look up client by WhatsApp number
    const client = await findClientByWhatsAppNumber(from);

    if (client) {
      // Client found - save message and post to Slack
      await saveInboundMessage({
        clientId: client.clientId,
        source: 'whatsapp',
        from,
        body,
        timestamp,
        messageId,
        raw: {
          profileName,
        },
      });

      // Post to client's Slack channel
      const { text, blocks } = formatWhatsAppMessageForSlack({
        from,
        body,
        clientName: client.displayName,
      });

      await postToSlack({
        channel: client.slackChannelId,
        text,
        blocks,
      });

      if (process.env.NODE_ENV === 'development') {
        console.log(
          `Message from ${from} mapped to client ${client.clientId}, posted to Slack`
        );
      }
    } else {
      // Client not found - post to fallback channel and save with null clientId
      const fallbackChannelId = process.env.SLACK_FALLBACK_CHANNEL_ID;

      if (fallbackChannelId) {
        const { text, blocks } = formatWhatsAppMessageForSlack({
          from,
          body,
        });

        const warningText = `⚠️ Unmapped WhatsApp sender\n${text}`;
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

        await postToSlack({
          channel: fallbackChannelId,
          text: warningText,
          blocks: warningBlocks,
        });
      }

      // Save message with null clientId
      await saveInboundMessage({
        clientId: null,
        source: 'whatsapp',
        from,
        body,
        timestamp,
        messageId,
        raw: {
          profileName,
        },
      });

      if (process.env.NODE_ENV === 'development') {
        console.log(`Unmapped message from ${from}, posted to fallback channel`);
      }
    }
  } catch (error) {
    console.error('Error processing WhatsApp message:', error);
    // Don't throw - we want to continue processing other messages
  }
}




