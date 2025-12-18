/**
 * Admin route to create a test clientMessage document
 * Protected by ADMIN_SEED_KEY environment variable
 * 
 * This allows manual testing of the Firestore → Slack flow
 * 
 * Example usage:
 * curl -X POST http://localhost:3000/api/admin/test/client-message \
 *   -H "Authorization: Bearer YOUR_ADMIN_SEED_KEY" \
 *   -H "Content-Type: application/json" \
 *   -d '{
 *     "clientId": "femileasing",
 *     "source": "manual-test",
 *     "channel": "slack",
 *     "slackChannel": "client-femileasing",
 *     "text": "hello from firestore trigger",
 *     "status": "pending"
 *   }'
 */

import { NextRequest, NextResponse } from 'next/server';
import { createClientMessage } from '@/lib/clientComms';

/**
 * POST /api/admin/test/client-message
 * Creates a test clientMessage document in Firestore
 */
export async function POST(request: NextRequest) {
  try {
    // Verify admin key
    const authHeader = request.headers.get('authorization');
    const adminKey = process.env.ADMIN_SEED_KEY;

    if (!adminKey) {
      return new NextResponse(
        JSON.stringify({ error: 'ADMIN_SEED_KEY not configured' }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    if (!authHeader || authHeader !== `Bearer ${adminKey}`) {
      return new NextResponse(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    // Parse request body
    const body = await request.json();

    // Validate required fields
    if (!body.clientId && body.clientId !== null) {
      return new NextResponse(
        JSON.stringify({
          error: 'clientId is required (can be null)',
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    if (!body.source) {
      return new NextResponse(
        JSON.stringify({
          error: 'source is required',
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    // Create the message document
    // Default status to "pending" if not provided (required for webhook trigger)
    const messageId = await createClientMessage({
      clientId: body.clientId || null,
      source: body.source,
      channel: body.channel,
      slackChannel: body.slackChannel,
      text: body.text,
      from: body.from,
      body: body.body,
      timestamp: body.timestamp,
      messageId: body.messageId,
      raw: body.raw,
      status: body.status || 'pending',
    });

    return new NextResponse(
      JSON.stringify({
        success: true,
        message: 'Client message created',
        messageId,
        data: {
          ...body,
          messageId,
        },
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error creating test client message:', error);
    return new NextResponse(
      JSON.stringify({
        error: 'Failed to create client message',
        details: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}
