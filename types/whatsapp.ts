/**
 * TypeScript types for Meta WhatsApp Cloud API webhook payloads
 */

export interface WhatsAppWebhookVerification {
  'hub.mode': string;
  'hub.verify_token': string;
  'hub.challenge': string;
}

export interface WhatsAppProfile {
  name?: string;
}

export interface WhatsAppText {
  body: string;
}

export interface WhatsAppMessage {
  from: string;
  id: string;
  timestamp: string;
  type: string;
  text?: WhatsAppText;
  profile?: WhatsAppProfile;
}

export interface WhatsAppEntry {
  id: string;
  changes: WhatsAppChange[];
}

export interface WhatsAppChange {
  value: {
    messaging_product: string;
    metadata?: {
      display_phone_number?: string;
      phone_number_id?: string;
    };
    contacts?: Array<{
      profile?: WhatsAppProfile;
      wa_id: string;
    }>;
    messages?: WhatsAppMessage[];
    statuses?: unknown[];
  };
  field: string;
}

export interface WhatsAppWebhookPayload {
  object: string;
  entry: WhatsAppEntry[];
}




