# Deployment Checklist: Firestore → Slack Webhook

## ✅ Pre-Deployment Checklist

- [ ] Firebase project created/selected
- [ ] `.firebaserc` updated with your Firebase project ID
- [ ] Firebase CLI installed: `npm install -g firebase-tools`
- [ ] Logged into Firebase: `firebase login`
- [ ] Slack webhook URL obtained (see below)

## 📋 Step-by-Step Deployment

### 1. Get Slack Webhook URL

1. Go to [Slack Apps](https://api.slack.com/apps)
2. Click "Create New App" → "From scratch"
3. Name your app (e.g., "Firestore Notifications")
4. Select your workspace
5. Go to "Incoming Webhooks" in left sidebar
6. Toggle "Activate Incoming Webhooks" to ON
7. Click "Add New Webhook to Workspace"
8. Select the channel (e.g., `#client-femileasing`)
9. Click "Allow"
10. **Copy the webhook URL** (you'll get a URL from Slack - save it securely)

### 2. Set Secret

```bash
firebase functions:secrets:set SLACK_WEBHOOK_URL
```

When prompted, paste your webhook URL.

**Verify it's set:**
```bash
firebase functions:secrets:access SLACK_WEBHOOK_URL
```

### 3. Install Dependencies

```bash
cd functions
npm install
```

### 4. Build

```bash
npm run build
```

This compiles TypeScript to JavaScript in the `lib/` directory.

### 5. Deploy

```bash
firebase deploy --only functions
```

Or from the root directory:
```bash
firebase deploy --only functions
```

### 6. Verify Deployment

```bash
firebase functions:list
```

You should see `postClientMessageToSlack` in the list.

## 🧪 Test the Deployment

### Option 1: Via Firestore Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database
4. Click "Start collection" if `clientMessages` doesn't exist
5. Collection ID: `clientMessages`
6. Click "Add document" (use Auto-ID)
7. Add these fields:

| Field    | Type    | Value                        |
|----------|---------|------------------------------|
| clientId | string  | femileasing                  |
| slackChannel | string | client-femileasing       |
| text     | string  | hello from firestore trigger |
| status   | string  | pending                      |
| source   | string  | manual-test                  |
| channel  | string  | slack                        |

8. Click "Save"
9. **Check Slack** - message should appear!

### Option 2: Via API

```bash
curl -X POST http://localhost:3000/api/admin/test/client-message \
  -H "Authorization: Bearer YOUR_ADMIN_SEED_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "femileasing",
    "slackChannel": "client-femileasing",
    "text": "hello from firestore trigger",
    "status": "pending",
    "source": "manual-test",
    "channel": "slack"
  }'
```

### Option 3: Check Logs

```bash
firebase functions:log --only postClientMessageToSlack
```

Look for:
- `Posted message to Slack` (success)
- `Slack webhook failed` (error)

## 🐛 Troubleshooting

### Function Not Deploying

- Check Node version: `node --version` (should be 20)
- Verify Firebase CLI: `firebase --version`
- Check build errors: `cd functions && npm run build`

### Secret Not Found

- Verify secret is set: `firebase functions:secrets:access SLACK_WEBHOOK_URL`
- Re-set if needed: `firebase functions:secrets:set SLACK_WEBHOOK_URL`

### Webhook Not Working

- Test webhook URL directly:
  ```bash
  curl -X POST YOUR_WEBHOOK_URL \
    -H "Content-Type: application/json" \
    -d '{"text":"Test message"}'
  ```
- Verify webhook URL is correct
- Check Slack channel exists
- Verify app has permission to post

### Function Not Triggering

- Verify document has `status: "pending"`
- Check function logs: `firebase functions:log`
- Ensure document is created (not updated)
- Verify collection name is exactly `clientMessages`

## 📝 Next Steps

Once this works:

1. **Create more webhooks** for different channels
2. **Add more fields** to messages (metadata, attachments, etc.)
3. **Set up Slack Bot** (reverse direction: Slack → Firestore)
4. **Add error handling** and retries
5. **Monitor** function invocations and costs

## 🔒 Security Notes

- Webhook URLs are secrets - never commit them
- Use Firebase Secrets Manager (already configured)
- Consider adding authentication to webhook endpoints
- Monitor function logs for suspicious activity
