# Firebase Functions v2

This directory contains Firebase Cloud Functions v2 that listen to Firestore events and post to Slack via webhooks.

## Setup

1. **Install dependencies:**
   ```bash
   cd functions
   npm install
   ```

2. **Configure Firebase project:**
   - Update `.firebaserc` in the root directory with your Firebase project ID
   - Ensure you have Firebase CLI installed: `npm install -g firebase-tools`
   - Login: `firebase login`

3. **Set Slack webhook secret:**
   ```bash
   firebase functions:secrets:set SLACK_WEBHOOK_URL
   ```
   When prompted, paste your Slack webhook URL (obtained from Slack app settings)

4. **Build:**
   ```bash
   npm run build
   ```

5. **Deploy:**
   ```bash
   firebase deploy --only functions
   ```

## Local Development

Run the Firebase emulator:
```bash
npm run serve
```

This will start the Firebase emulator suite, allowing you to test functions locally.

## Functions

### `postClientMessageToSlack`

**Trigger:** Firestore `clientMessages` collection `onCreate` event

**What it does:**
- Listens for new documents in the `clientMessages` collection
- Only processes documents with `status: "pending"` (optional safety check)
- Posts formatted message to Slack via webhook URL
- Logs success/failure

**Message Schema:**
- `clientId` (string): Client identifier (defaults to "unknown-client")
- `source` (string): Source of message (defaults to "unknown")
- `slackChannel` (string, optional): Slack channel identifier
- `text` (string, optional): Message text
- `channel` (string, optional): Channel type (defaults to "unknown")
- `status` (string, optional): Must be "pending" to trigger (optional safety)

## Testing

After deploying, test by creating a document in Firestore:

1. Go to Firebase Console → Firestore
2. Navigate to `clientMessages` collection
3. Click "Add document"
4. Use Auto-ID
5. Add fields:
   - `clientId`: "femileasing"
   - `slackChannel`: "client-femileasing"
   - `text`: "hello from firestore trigger"
   - `status`: "pending"
   - `source`: "manual-test"
   - `channel`: "slack"

**Expected Result:** Message appears in Slack channel via webhook!

## Getting a Slack Webhook URL

1. Go to [Slack Apps](https://api.slack.com/apps)
2. Create a new app or select existing
3. Go to "Incoming Webhooks"
4. Activate Incoming Webhooks
5. Click "Add New Webhook to Workspace"
6. Select the channel (e.g., `#client-femileasing`)
7. Copy the webhook URL
8. Set it as secret: `firebase functions:secrets:set SLACK_WEBHOOK_URL`
