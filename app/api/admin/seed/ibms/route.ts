/**
 * Admin route to seed IBMS client configuration
 * Protected by ADMIN_SEED_KEY environment variable
 */

import { NextRequest, NextResponse } from 'next/server';
import { getAdminDb } from '@/lib/firebaseAdmin';

/**
 * POST /api/admin/seed/ibms
 * Creates IBMS client configuration in Firestore
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

    // Validate required environment variables
    const slackChannelId = process.env.SLACK_CHANNEL_IBMS_ID;
    if (!slackChannelId) {
      return new NextResponse(
        JSON.stringify({
          error: 'SLACK_CHANNEL_IBMS_ID environment variable is required',
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    // Create IBMS client configuration
    const db = getAdminDb();
    const clientCommsRef = db.collection('clientComms');
    const ibmsRef = clientCommsRef.doc('ibms');

    // Check if document already exists
    const existingDoc = await ibmsRef.get();
    const now = new Date();

    const ibmsData = {
      clientId: 'ibms',
      displayName: 'IBMS',
      whatsappFromNumbers: [], // Empty initially - will be populated when client's number is known
      slackChannelId,
      createdAt: existingDoc.exists
        ? existingDoc.data()?.createdAt || now
        : now,
      updatedAt: now,
    };

    await ibmsRef.set(ibmsData, { merge: true });

    return new NextResponse(
      JSON.stringify({
        success: true,
        message: 'IBMS client configuration created/updated',
        data: ibmsData,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error seeding IBMS client:', error);
    return new NextResponse(
      JSON.stringify({
        error: 'Failed to seed IBMS client',
        details: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}








