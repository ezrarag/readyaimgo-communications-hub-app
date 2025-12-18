/**
 * Slack integration utilities
 * Handles posting messages to Slack channels
 */

import { WebClient } from '@slack/web-api';

let slackClient: WebClient | null = null;

/**
 * Initialize Slack Web API client
 */
function getSlackClient(): WebClient {
  if (slackClient) {
    return slackClient;
  }

  const token = process.env.SLACK_BOT_TOKEN;
  if (!token) {
    throw new Error(
      'SLACK_BOT_TOKEN environment variable is required for Slack integration'
    );
  }

  slackClient = new WebClient(token);
  return slackClient;
}

/**
 * Post message to Slack channel
 */
export async function postToSlack({
  channel,
  text,
  blocks,
}: {
  channel: string;
  text: string;
  blocks?: unknown[];
}): Promise<void> {
  try {
    const client = getSlackClient();

    await client.chat.postMessage({
      channel,
      text,
      blocks,
    });
  } catch (error) {
    console.error('Error posting to Slack:', error);
    throw error;
  }
}

/**
 * Format WhatsApp message for Slack
 */
export function formatWhatsAppMessageForSlack({
  from,
  body,
  clientName,
}: {
  from: string;
  body: string;
  clientName?: string;
}): { text: string; blocks: unknown[] } {
  const header = '📲 WhatsApp message';
  const fromLine = `From: ${from}`;
  const clientLine = clientName ? `Client: ${clientName}` : null;

  const text = [header, fromLine, clientLine, body]
    .filter(Boolean)
    .join('\n');

  const blocks = [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: header,
        emoji: true,
      },
    },
    {
      type: 'section',
      fields: [
        {
          type: 'mrkdwn',
          text: `*From:*\n${from}`,
        },
        ...(clientName
          ? [
              {
                type: 'mrkdwn',
                text: `*Client:*\n${clientName}`,
              },
            ]
          : []),
      ],
    },
    {
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `*Message:*\n${body}`,
      },
    },
  ];

  return { text, blocks };
}




