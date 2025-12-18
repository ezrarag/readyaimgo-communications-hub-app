/**
 * Client communications mapping utilities
 * Handles lookup of clients by WhatsApp number
 */

import { getAdminDb } from './firebaseAdmin';
import { Timestamp } from 'firebase-admin/firestore';

export interface ClientComms {
  clientId: string;
  displayName: string;
  whatsappFromNumbers: string[];
  slackChannelId: string;
  createdAt: Timestamp | Date;
  updatedAt: Timestamp | Date;
}

/**
 * Find client by WhatsApp phone number
 * Searches clientComms collection for documents where whatsappFromNumbers array contains the number
 */
export async function findClientByWhatsAppNumber(
  from: string
): Promise<ClientComms | null> {
  try {
    const db = getAdminDb();
    const clientCommsRef = db.collection('clientComms');

    // Query for documents where whatsappFromNumbers array contains the phone number
    const snapshot = await clientCommsRef
      .where('whatsappFromNumbers', 'array-contains', from)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return null;
    }

    const doc = snapshot.docs[0];
    const data = doc.data();

    return {
      clientId: data.clientId,
      displayName: data.displayName,
      whatsappFromNumbers: data.whatsappFromNumbers || [],
      slackChannelId: data.slackChannelId,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    };
  } catch (error) {
    console.error('Error finding client by WhatsApp number:', error);
    throw error;
  }
}

/**
 * Save inbound message to Firestore
 */
export async function saveInboundMessage(data: {
  clientId: string | null;
  source: string;
  from: string;
  body: string;
  timestamp: string;
  messageId: string;
  raw?: unknown;
}): Promise<void> {
  try {
    const db = getAdminDb();
    const messagesRef = db.collection('clientMessages');

    await messagesRef.add({
      ...data,
      createdAt: new Date(),
    });
  } catch (error) {
    console.error('Error saving inbound message:', error);
    throw error;
  }
}

/**
 * Create a clientMessage document in Firestore
 * This is the canonical way to create messages that will trigger Slack posting
 * 
 * @param data - Message data following the clientMessages schema
 * @returns Document reference ID
 */
export async function createClientMessage(data: {
  clientId: string | null;
  source: string;
  channel?: string;
  slackChannel?: string;
  text?: string;
  from?: string;
  body?: string;
  timestamp?: string;
  messageId?: string;
  raw?: unknown;
  status?: string;
}): Promise<string> {
  try {
    const db = getAdminDb();
    const messagesRef = db.collection('clientMessages');

    const docRef = await messagesRef.add({
      ...data,
      createdAt: new Date(),
    });

    return docRef.id;
  } catch (error) {
    console.error('Error creating client message:', error);
    throw error;
  }
}




