/**
 * TypeScript types for clientMessages Firestore collection
 */

import { Timestamp } from 'firebase-admin/firestore';

/**
 * ClientMessage document structure
 * This matches the schema described in the user's instructions
 */
export interface ClientMessage {
  /**
   * Client identifier (e.g., "femileasing", "ibms")
   * Can be null for unmapped messages
   */
  clientId: string | null;

  /**
   * Source of the message (e.g., "whatsapp", "manual-test", "sms", "email")
   */
  source: string;

  /**
   * Channel type (e.g., "slack", "sms", "whatsapp")
   * Optional - used for routing decisions
   */
  channel?: string;

  /**
   * Slack channel ID or name (e.g., "client-femileasing")
   * If provided, will be used directly instead of looking up clientComms
   */
  slackChannel?: string;

  /**
   * Message text (preferred field for Slack posting)
   * If not provided, will be formatted from body/from fields
   */
  text?: string;

  /**
   * Sender phone number (for WhatsApp/SMS)
   */
  from?: string;

  /**
   * Message body/content
   * Used if text field is not provided
   */
  body?: string;

  /**
   * Original timestamp from source system (string format)
   */
  timestamp?: string;

  /**
   * Original message ID from source system
   */
  messageId?: string;

  /**
   * Raw data from source system
   */
  raw?: unknown;

  /**
   * Timestamp when document was created in Firestore
   */
  createdAt: Timestamp | Date;

  /**
   * Timestamp when message was posted to Slack (set by Cloud Function)
   */
  slackPostedAt?: Timestamp | Date;

  /**
   * Error message if Slack posting failed (set by Cloud Function)
   */
  slackError?: string;

  /**
   * Timestamp when Slack error occurred (set by Cloud Function)
   */
  slackErrorAt?: Timestamp | Date;
}

/**
 * Input data for creating a new clientMessage
 * Omits fields that are set automatically (createdAt, slackPostedAt, etc.)
 */
export interface CreateClientMessageInput {
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
}
