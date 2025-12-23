# Architecture Summary: WhatsApp → Slack Flow

## Current Implementation

**Firestore → Slack is NOT triggered via Cloud Function in the current flow.**

Instead, the webhook posts to Slack **directly** using the Slack Bot API, then writes to Firestore for record-keeping.

## The Flow

```
WhatsApp Message (from +14049739860)
  ↓
Meta WhatsApp Cloud API
  ↓
POST /webhooks/whatsapp (public endpoint, no auth)
  ↓
1. Verify signature (X-Hub-Signature-256) if META_APP_SECRET set
2. Respond 200 OK immediately (non-blocking)
  ↓
[Async processing - fire-and-forget]
  ├─→ Parse webhook payload
  ├─→ Extract: from (+14049739860), message text, etc.
  ├─→ Query Firestore: clientComms collection
  │   └─→ WHERE whatsappFromNumbers array-contains "+14049739860"
  │   └─→ Returns: { clientId, displayName, slackChannelId }
  │
  ├─→ Post to Slack (NON-BLOCKING, fire-and-forget)
  │   └─→ Uses: SLACK_BOT_TOKEN + Slack Web API (chat.postMessage)
  │   └─→ Channel: client.slackChannelId (or SLACK_FALLBACK_CHANNEL_ID)
  │   └─→ Format: Rich blocks with header, from, client, message
  │
  └─→ Write to Firestore (NON-BLOCKING, fire-and-forget)
      └─→ Collection: clientMessages
      └─→ Status: "received" (NOT "pending")
      └─→ Fields: clientId, channel, source, from, text, body, raw, etc.
```

## Why No Firestore Trigger?

There IS a Firebase Cloud Function (`postClientMessageToSlack`) that triggers on `clientMessages` onCreate, BUT:

1. **It only processes `status: "pending"` messages**
2. **The webhook writes messages with `status: "received"`**
3. **Therefore, the trigger never fires**

The function exists at `functions/src/index.ts` but is effectively inactive for this use case.

## Slack Posting Mechanism

**Current:** Direct Slack Bot API call
- Uses `SLACK_BOT_TOKEN` (starts with `xoxb-`)
- Calls `client.chat.postMessage()` via `@slack/web-api`
- Posts to specific channel ID (e.g., `C1234567890`)
- Non-blocking (fire-and-forget with `.catch()`)

**Alternative (not used):** Firebase Function + Webhook URL
- Would use `SLACK_WEBHOOK_URL` secret
- Would trigger on Firestore `onCreate`
- Currently inactive due to status mismatch

## Key Configuration Points

### 1. Client Mapping (Firestore `clientComms` collection)
```json
{
  "clientId": "test-client",
  "displayName": "Test Client",
  "whatsappFromNumbers": ["+14049739860"],  // E.164 format
  "slackChannelId": "C1234567890"  // Slack channel ID (not name)
}
```

### 2. Environment Variables (Vercel/Next.js)
- `SLACK_BOT_TOKEN` - Required for direct posting
- `SLACK_FALLBACK_CHANNEL_ID` - For unmapped numbers
- `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` - For Firestore
- `WHATSAPP_VERIFY_TOKEN` - For webhook verification
- `META_APP_SECRET` - Optional, for signature verification

### 3. Slack Bot Setup
- Bot must be added to the target Slack channel
- Bot needs `chat:write` permission
- Use channel ID (not name) in `slackChannelId`

## Testing the Flow

### Step 1: Verify Webhook is Public
```bash
curl "https://your-domain.com/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=TOKEN&hub.challenge=test"
# Should return: 200 OK with body "test"
```

### Step 2: Set Up Client Mapping
Create document in Firestore `clientComms` collection mapping phone number to Slack channel.

### Step 3: Send Test Message
Send WhatsApp message from `+14049739860` to your WhatsApp Business number.

### Step 4: Check Logs
Look for:
- `Message from +14049739860 mapped to client...`
- `posting to Slack channel...`
- `WhatsApp message saved to Firestore`

### Step 5: Verify Results
- ✅ Message appears in Slack channel
- ✅ Document created in Firestore `clientMessages` collection

## Common Failure Points

1. **Client lookup fails**
   - Phone number format wrong (needs E.164: `+14049739860`)
   - `clientComms` document missing or malformed
   - Firestore query permissions

2. **Slack posting fails**
   - `SLACK_BOT_TOKEN` missing/invalid
   - Bot not added to channel
   - Wrong channel ID format
   - Slack API errors

3. **Firestore write fails**
   - Firebase Admin credentials wrong
   - Firestore security rules blocking writes
   - Network/permission issues

## For Cursor Agent Integration

The WhatsApp messages will appear in Slack channels as formatted messages:
- Header: "📲 WhatsApp message"
- From: Phone number
- Client: Client name (if mapped)
- Message: Text body

A Cursor agent can:
1. Listen to Slack Events API for new messages
2. Parse the formatted message to extract WhatsApp data
3. Process and respond via WhatsApp API or back to Slack

The Firestore `clientMessages` collection serves as an audit log but is not required for the Slack → Agent flow.

