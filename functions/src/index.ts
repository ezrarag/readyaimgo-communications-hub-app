/**
 * Firebase Cloud Functions v2
 * Firestore → Slack webhook integration
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

const SLACK_WEBHOOK_URL = defineSecret("SLACK_WEBHOOK_URL");

/**
 * Firestore trigger: onCreate clientMessages
 * Posts new client messages to Slack via webhook
 */
export const postClientMessageToSlack = onDocumentCreated(
  {
    document: "clientMessages/{messageId}",
    secrets: [SLACK_WEBHOOK_URL],
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    // Only forward pending messages (optional safety)
    if (data.status && data.status !== "pending") return;

    const clientId = data.clientId ?? "unknown-client";
    const slackChannel = data.slackChannel ?? "";
    const text = data.text ?? "";
    const source = data.source ?? "unknown";
    const channel = data.channel ?? "unknown";

    const payload = {
      text: `📩 *New client message*\n*clientId:* ${clientId}\n*slackChannel:* ${slackChannel}\n*source:* ${source}\n*channel:* ${channel}\n*text:* ${text}`,
    };

    const webhookUrl = SLACK_WEBHOOK_URL.value();
    const res = await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const body = await res.text().catch(() => "");
      logger.error("Slack webhook failed", { status: res.status, body });
      throw new Error(`Slack webhook failed: ${res.status}`);
    }

    logger.info("Posted message to Slack", { messageId: event.params.messageId });
  }
);
