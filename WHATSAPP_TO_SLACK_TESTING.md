# WhatsApp → Slack Testing Guide

## Architecture Overview

Your system has **TWO parallel paths** for Slack posting:

### Path 1: Direct Slack Posting (Currently Active)
```
WhatsApp Message
  ↓
Meta Webhook → POST /webhooks/whatsapp
  ↓
Signature Verification (if META_APP_SECRET set)
  ↓
Respond 200 OK immediately
  ↓
[Async Processing]
  ├─→ Lookup client in Firestore (clientComms collection)
  ├─→ Post to Slack directly (using SLACK_BOT_TOKEN + Slack Web API)
  └─→ Write to Firestore (clientMessages collection, status: "received")
```

### Path 2: Firestore Trigger (Currently Inactive)
```
WhatsApp Message
  ↓
Write to Firestore (clientMessages, status: "pending")
  ↓
Firebase Cloud Function onCreate trigger
  ↓
Post to Slack via webhook URL (SLACK_WEBHOOK_URL)
```

**Current Status:** Path 1 is active. Path 2 exists but won't trigger because:
- Webhook writes messages with `status: "received"`
- Firebase Function only processes `status: "pending"` messages

## Required Environment Variables

### For WhatsApp Webhook (Vercel/Next.js)
```bash
# Meta WhatsApp
WHATSAPP_VERIFY_TOKEN=readyaimgo_whatsapp_verify_2025
META_APP_SECRET=your_meta_app_secret  # Optional but recommended

# Firebase Admin (for Firestore)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Slack (for direct posting)
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_FALLBACK_CHANNEL_ID=C1234567890  # Channel for unmapped numbers
```

### For Firebase Functions (if using Path 2)
```bash
# Set via Firebase CLI
firebase functions:secrets:set SLACK_WEBHOOK_URL
```

## Step-by-Step Testing Guide

### Step 1: Verify Webhook Endpoint is Public

Test GET endpoint (verification):
```bash
curl "https://your-domain.com/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=readyaimgo_whatsapp_verify_2025&hub.challenge=test123"
```

**Expected:** `200 OK` with body `test123`

**If fails:**
- Check route is at `/webhooks/whatsapp` (not `/api/webhooks/whatsapp`)
- Verify no auth middleware blocking it
- Check `WHATSAPP_VERIFY_TOKEN` matches

### Step 2: Set Up Client Mapping in Firestore

You need a document in the `clientComms` collection mapping your phone number to a Slack channel.

**Collection:** `clientComms`
**Document ID:** (any, e.g., `test-client`)

**Document Fields:**
```json
{
  "clientId": "test-client",
  "displayName": "Test Client",
  "whatsappFromNumbers": ["+14049739860"],  // Your number in E.164 format
  "slackChannelId": "C1234567890",  // Your Slack channel ID
  "createdAt": [timestamp],
  "updatedAt": [timestamp]
}
```

**Important:** 
- Phone number must be in E.164 format: `+14049739860` (not `404-973-9860`)
- `slackChannelId` must be the actual Slack channel ID (starts with `C`), not the channel name

**How to get Slack Channel ID:**
1. Open Slack in browser
2. Click on the channel
3. Look at URL: `https://workspace.slack.com/archives/C1234567890`
4. The `C1234567890` part is your channel ID

### Step 3: Verify Environment Variables

Check that all required env vars are set in your deployment (Vercel/wherever):

```bash
# Check via your hosting platform's dashboard or CLI
# Vercel: vercel env ls
```

**Critical ones:**
- ✅ `SLACK_BOT_TOKEN` - Must start with `xoxb-`
- ✅ `SLACK_FALLBACK_CHANNEL_ID` - For unmapped numbers
- ✅ `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` - For Firestore access

### Step 4: Test with Real WhatsApp Message

1. **Send a test message** from your phone (`+14049739860`) to your WhatsApp Business number
2. **Check logs** in your hosting platform (Vercel logs, etc.)

**What to look for in logs:**
```
Message from +14049739860 mapped to client test-client, posting to Slack channel C1234567890
WhatsApp message saved to Firestore { messageId: '...', clientId: 'test-client', ... }
```

**If you see errors:**
- `Error finding client by WhatsApp number` → Check `clientComms` document format
- `Error posting to Slack` → Check `SLACK_BOT_TOKEN` and channel ID
- `Error writing to Firestore` → Check Firebase credentials

### Step 5: Verify Firestore Document Created

Check Firestore Console:
1. Go to Firebase Console → Firestore
2. Navigate to `clientMessages` collection
3. Look for new document with:
   - `from: "+14049739860"`
   - `status: "received"`
   - `channel: "whatsapp"`
   - `clientId: "test-client"` (or `null` if unmapped)

### Step 6: Verify Slack Message

Check your Slack channel (`C1234567890`):
- Should see formatted message with header "📲 WhatsApp message"
- Shows "From: +14049739860"
- Shows "Client: Test Client"
- Shows message body

**If message doesn't appear:**
- Check `SLACK_BOT_TOKEN` is valid
- Verify bot is added to the channel
- Check Slack channel ID is correct
- Look for errors in logs: `Error posting to Slack channel...`

### Step 7: Test Unmapped Number (Fallback)

To test fallback behavior:
1. Send message from a number NOT in `clientComms`
2. Should post to `SLACK_FALLBACK_CHANNEL_ID` with warning "⚠️ Unmapped WhatsApp sender"
3. Firestore document should have `clientId: null`

## Debugging Checklist

### Webhook Not Receiving Messages
- [ ] Meta webhook URL configured correctly: `https://your-domain.com/webhooks/whatsapp`
- [ ] Webhook verified in Meta dashboard (GET endpoint works)
- [ ] Webhook subscribed to `messages` field in Meta dashboard
- [ ] WhatsApp Business number is active and receiving messages

### Messages Received But Not in Slack
- [ ] Check application logs for errors
- [ ] Verify `SLACK_BOT_TOKEN` is set and valid
- [ ] Verify bot is added to Slack channel
- [ ] Check `slackChannelId` in `clientComms` matches actual channel ID
- [ ] Verify `SLACK_FALLBACK_CHANNEL_ID` is set (for unmapped numbers)

### Client Lookup Failing
- [ ] Check `clientComms` collection has document
- [ ] Verify phone number format: E.164 (`+14049739860`)
- [ ] Check `whatsappFromNumbers` is an array containing your number
- [ ] Verify Firestore query permissions allow reads

### Firestore Write Failing
- [ ] Check Firebase Admin credentials (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`)
- [ ] Verify Firestore security rules allow writes to `clientMessages`
- [ ] Check `clientMessages` collection exists
- [ ] Look for errors in logs: `Error writing to Firestore`

## Testing Without Real WhatsApp Message

You can test the webhook directly with a curl command:

```bash
curl -X POST https://your-domain.com/webhooks/whatsapp \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=..." \
  -d '{
    "object": "whatsapp_business_account",
    "entry": [{
      "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
      "changes": [{
        "field": "messages",
        "value": {
          "messaging_product": "whatsapp",
          "metadata": {
            "display_phone_number": "15551234567",
            "phone_number_id": "PHONE_NUMBER_ID"
          },
          "contacts": [{
            "wa_id": "+14049739860",
            "profile": {
              "name": "Test User"
            }
          }],
          "messages": [{
            "from": "+14049739860",
            "id": "wamid.test123",
            "timestamp": "1234567890",
            "type": "text",
            "text": {
              "body": "Test message"
            }
          }]
        }
      }]
    }]
  }'
```

**Note:** You'll need to generate a valid `X-Hub-Signature-256` header if `META_APP_SECRET` is set. For testing, you can temporarily disable signature verification by not setting `META_APP_SECRET`.

## Architecture Decision: Why Direct Slack Posting?

The current implementation posts to Slack **directly from the webhook** rather than relying on Firestore triggers because:

1. **Faster**: No delay waiting for Firestore trigger
2. **More reliable**: Direct API call vs. trigger dependency
3. **Better error handling**: Can log errors immediately
4. **Non-blocking**: Already implemented as fire-and-forget

The Firestore write still happens (for record-keeping), but Slack posting doesn't depend on it.

## Next Steps for Cursor Agent Integration

Once WhatsApp → Slack is working, you can connect a Cursor agent to:
1. **Slack Events API**: Listen for messages in Slack channels
2. **Slack Socket Mode**: Real-time connection to Slack
3. **Poll Slack API**: Periodically check for new messages

The agent would:
- Listen for messages in the Slack channel
- Process incoming WhatsApp messages (already formatted)
- Respond via WhatsApp API (or back to Slack)


