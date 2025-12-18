# Firestore Setup Guide

This guide walks you through setting up the Firestore → Slack integration system.

## Architecture Overview

```
Firestore (Source of Truth)
  └── clientMessages collection
       └── onCreate trigger
            └── Firebase Function
                 └── Post to Slack
```

**Key Principle:** Firestore is the source of truth. Creating a document in `clientMessages` triggers automatic Slack posting.

## Step 1: Firebase Project Setup

1. **Create/Select Firebase Project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select existing one
   - Enable Firestore Database

2. **Update `.firebaserc`:**
   ```json
   {
     "projects": {
       "default": "your-actual-project-id"
     }
   }
   ```

## Step 2: Firestore Collections

### Collection: `clientComms`

**Purpose:** Maps clients to their communication channels

**Document Structure:**
- Document ID: `{clientId}` (e.g., `femileasing`, `ibms`)
- Fields:
  - `clientId` (string): Client identifier
  - `displayName` (string): Human-readable name
  - `whatsappFromNumbers` (array): Array of WhatsApp phone numbers
  - `slackChannelId` (string): Slack channel ID (e.g., `C1234567890`)
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)

**Example Document:**
```
Collection: clientComms
Document ID: femileasing
Fields:
  clientId: "femileasing"
  displayName: "Femi Leasing"
  whatsappFromNumbers: ["+1234567890"]
  slackChannelId: "C1234567890"
  createdAt: [timestamp]
  updatedAt: [timestamp]
```

### Collection: `clientMessages`

**Purpose:** Event log of all client messages/actions

**Document Structure:**
- Document ID: Auto-generated
- Fields:
  - `clientId` (string | null): Client identifier (null for unmapped)
  - `source` (string): Source system (e.g., "whatsapp", "manual-test", "sms")
  - `channel` (string, optional): Channel type (e.g., "slack", "sms")
  - `slackChannel` (string, optional): Direct Slack channel override
  - `text` (string, optional): Message text (preferred for Slack)
  - `from` (string, optional): Sender identifier
  - `body` (string, optional): Message body (used if text not provided)
  - `timestamp` (string, optional): Original timestamp from source
  - `messageId` (string, optional): Original message ID
  - `raw` (object, optional): Raw data from source
  - `createdAt` (timestamp): Auto-set on creation
  - `slackPostedAt` (timestamp): Set by Cloud Function on success
  - `slackError` (string): Set by Cloud Function on failure
  - `slackErrorAt` (timestamp): Set by Cloud Function on failure

## Step 3: Manual Test (Before Functions)

### Create Test Document in Firestore Console

1. Go to Firebase Console → Firestore → Data
2. Click "Add collection" if `clientMessages` doesn't exist
3. Collection ID: `clientMessages`
4. Click "Add document" (use Auto-ID)
5. Add these fields:

| Field name     | Type      | Value                         |
| -------------- | --------- | ----------------------------- |
| `clientId`     | string    | `femileasing`                 |
| `source`       | string    | `manual-test`                 |
| `channel`      | string    | `slack`                       |
| `slackChannel` | string    | `client-femileasing`          |
| `text`         | string    | `Test message from Firestore` |
| `createdAt`    | timestamp | **now**                       |

6. Click **Save**

**Expected Result:** Document is created, but Slack won't post yet (functions not deployed).

## Step 4: Deploy Firebase Functions

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Install Function Dependencies:**
   ```bash
   cd functions
   npm install
   ```

3. **Set Environment Variables:**
   ```bash
   # Using secrets (recommended)
   firebase functions:secrets:set SLACK_BOT_TOKEN
   # Enter your Slack bot token when prompted
   
   firebase functions:secrets:set SLACK_FALLBACK_CHANNEL_ID
   # Enter your fallback channel ID when prompted
   ```

4. **Build and Deploy:**
   ```bash
   npm run build
   npm run deploy
   ```

## Step 5: Test the Full Flow

### Option A: Via Firestore Console

1. Create another test document (same as Step 3)
2. Check Firebase Functions logs: `firebase functions:log`
3. Check Slack channel - message should appear!

### Option B: Via API Endpoint

```bash
curl -X POST https://your-domain.com/api/admin/test/client-message \
  -H "Authorization: Bearer YOUR_ADMIN_SEED_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "femileasing",
    "source": "manual-test",
    "channel": "slack",
    "slackChannel": "client-femileasing",
    "text": "Test message from Firestore API"
  }'
```

### Option C: Via Code

```typescript
import { createClientMessage } from '@/lib/clientComms';

await createClientMessage({
  clientId: 'femileasing',
  source: 'manual-test',
  channel: 'slack',
  slackChannel: 'client-femileasing',
  text: 'Test message from code',
});
```

## Step 6: Verify It Works

✅ **Success Indicators:**
- Document appears in `clientMessages` collection
- `slackPostedAt` field is added to document
- Message appears in Slack channel
- No errors in Firebase Functions logs

❌ **If It Fails:**
- Check `slackError` field in document
- Check Firebase Functions logs: `firebase functions:log`
- Verify `SLACK_BOT_TOKEN` is set correctly
- Verify Slack channel ID/name is correct
- Verify bot has permission to post to channel

## Next Steps

Once this works:

1. **Update WhatsApp Webhook:** Optionally remove direct Slack posting, rely on Firestore trigger
2. **Add More Sources:** SMS, email, etc. all create `clientMessages` documents
3. **Add More Destinations:** Extend functions to post to other channels
4. **Add Work Requests:** Create `workRequests` collection with similar pattern

## Troubleshooting

### Function Not Triggering

- Verify function is deployed: `firebase functions:list`
- Check function logs: `firebase functions:log --only onClientMessageCreated`
- Verify Firestore rules allow writes

### Slack Posting Fails

- Verify `SLACK_BOT_TOKEN` is correct
- Verify bot is in the target channel
- Check Slack API rate limits
- Verify channel ID/name format (ID: `C1234567890`, name: `#channel-name`)

### Document Created But No Slack Message

- Check document for `slackError` field
- Verify `slackChannel` or `clientComms` lookup returns valid channel
- Check Firebase Functions logs for errors
