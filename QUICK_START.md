# Quick Start: Firestore → Slack Integration (Webhook)

## ✅ What's Been Created

1. **Firebase Functions v2** (`/functions`)
   - Firestore trigger that listens for new `clientMessages` documents
   - Automatically posts to Slack via webhook when documents are created

2. **TypeScript Types** (`/types/clientMessages.ts`)
   - Complete type definitions for `clientMessages` schema

3. **Utility Functions** (`/lib/clientComms.ts`)
   - `createClientMessage()` - Create messages programmatically

4. **Test API Endpoint** (`/app/api/admin/test/client-message`)
   - HTTP endpoint for manual testing

5. **Documentation**
   - `FIRESTORE_SETUP.md` - Complete setup guide
   - `functions/README.md` - Functions-specific docs

## 🚀 Quick Test (3 Steps)

### Step 1: Set Slack Webhook Secret

```bash
firebase functions:secrets:set SLACK_WEBHOOK_URL
```
When prompted, paste your Slack webhook URL.

**Don't have a webhook URL?**
1. Go to [Slack Apps](https://api.slack.com/apps)
2. Create app → Incoming Webhooks → Activate
3. Add webhook to workspace → Select channel
4. Copy the webhook URL

### Step 2: Deploy Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### Step 3: Create Test Document

**Option A: Via Firestore Console**
1. Firebase Console → Firestore → `clientMessages`
2. Add document with:
   - `clientId`: "femileasing"
   - `slackChannel`: "client-femileasing"
   - `text`: "hello from firestore trigger"
   - `status`: "pending"
   - `source`: "manual-test"
   - `channel`: "slack"

**Option B: Via API**
```bash
curl -X POST http://localhost:3000/api/admin/test/client-message \
  -H "Authorization: Bearer YOUR_ADMIN_SEED_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "femileasing",
    "source": "manual-test",
    "slackChannel": "client-femileasing",
    "text": "hello from firestore trigger",
    "status": "pending",
    "channel": "slack"
  }'
```

### Step 4: Verify

✅ Check Slack channel - message should appear!
✅ Check function logs: `firebase functions:log`

## 📋 Document Schema

When creating a `clientMessages` document, include:

**Required for webhook trigger:**
- `status`: "pending" (optional safety check - function only processes pending messages)

**Recommended:**
- `clientId` (string): Client identifier
- `slackChannel` (string): Slack channel identifier
- `text` (string): Message text
- `source` (string): Source of message
- `channel` (string): Channel type

## 🔍 How It Works

```
1. Document created in clientMessages with status="pending"
   ↓
2. Firebase Function v2 triggers (onDocumentCreated)
   ↓
3. Function formats message payload
   ↓
4. Posts to Slack via webhook URL
   ↓
5. Logs success/failure
```

## 🐛 Troubleshooting

**No Slack message?**
- Verify document has `status: "pending"`
- Check function logs: `firebase functions:log`
- Verify `SLACK_WEBHOOK_URL` secret is set: `firebase functions:secrets:access SLACK_WEBHOOK_URL`
- Test webhook URL directly with curl

**Function not triggering?**
- Verify deployment: `firebase functions:list`
- Check logs: `firebase functions:log --only postClientMessageToSlack`
- Ensure document is created (not updated)

## 📚 Full Documentation

See `FIRESTORE_SETUP.md` for complete setup instructions.
