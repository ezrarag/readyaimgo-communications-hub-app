# Endpoint Readiness Checklist

## ✅ Ready Endpoints

### 1. GET /health
- **Status**: ✅ Ready
- **Purpose**: Health check endpoint
- **Response**: `{ status: 'ok', timestamp: '...' }`
- **Test**: `curl https://api.readyaimgo.biz/health`

### 2. GET /webhooks/whatsapp
- **Status**: ✅ Ready
- **Purpose**: WhatsApp webhook verification (Meta subscription)
- **Query Params**: 
  - `hub.mode=subscribe`
  - `hub.verify_token=<WHATSAPP_VERIFY_TOKEN>`
  - `hub.challenge=<challenge_string>`
- **Response**: Returns challenge string (200) or "Forbidden" (403)
- **Environment Variable**: `WHATSAPP_VERIFY_TOKEN`
- **Meta Configuration**: Set this URL in Meta WhatsApp Cloud API dashboard

### 3. POST /webhooks/whatsapp
- **Status**: ✅ Ready
- **Purpose**: Receive WhatsApp messages and post to Slack
- **Flow**:
  1. Verifies webhook signature (if `META_APP_SECRET` is set)
  2. Responds 200 OK immediately (to prevent Meta retries)
  3. Processes message asynchronously:
     - Looks up client by WhatsApp phone number in `clientComms` collection
     - Posts formatted message to Slack channel (client's channel or fallback)
     - Saves message to Firestore `clientMessages` collection
- **Environment Variables**:
  - `META_APP_SECRET` (optional, for signature verification)
  - `SLACK_BOT_TOKEN` (required for Slack posting)
  - `SLACK_FALLBACK_CHANNEL_ID` (required for unmapped messages)
- **Firestore Collections Required**:
  - `clientComms`: Maps WhatsApp numbers to Slack channels
  - `clientMessages`: Stores all incoming messages

### 4. POST /api/admin/test/client-message
- **Status**: ✅ Ready
- **Purpose**: Test endpoint for creating client messages
- **Auth**: Bearer token (`ADMIN_SEED_KEY`)
- **Use Case**: Manual testing of message flow

### 5. POST /api/admin/seed/ibms
- **Status**: ✅ Ready
- **Purpose**: Seed IBMS client configuration
- **Auth**: Bearer token (`ADMIN_SEED_KEY`)

## 🔧 Required Environment Variables

Set these in Vercel project settings:

```
WHATSAPP_VERIFY_TOKEN=<your-verify-token>
SLACK_BOT_TOKEN=xoxb-...
SLACK_FALLBACK_CHANNEL_ID=C...
SLACK_CHANNEL_IBMS_ID=C... (optional, for IBMS client)
FIREBASE_PROJECT_ID=<your-project-id>
FIREBASE_CLIENT_EMAIL=<service-account-email>
FIREBASE_PRIVATE_KEY=<service-account-private-key>
META_APP_SECRET=<meta-app-secret> (optional, for webhook signature verification)
ADMIN_SEED_KEY=<admin-secret-key>
```

## 📋 Deployment Checklist

### Vercel Setup
- [x] Repository connected to Vercel
- [ ] Domain `api.readyaimgo.biz` added to Vercel project
- [ ] All environment variables configured in Vercel
- [ ] Build successful (verified ✅)

### DNS Setup (Namecheap)
- [ ] Add CNAME record: `api` → `cname.vercel-dns.com` (or A record as per Vercel instructions)
- [ ] Wait for DNS propagation

### Meta WhatsApp Cloud API Setup
- [ ] Go to [Meta for Developers](https://developers.facebook.com/)
- [ ] Navigate to WhatsApp > Configuration
- [ ] Set webhook URL: `https://api.readyaimgo.biz/webhooks/whatsapp`
- [ ] Set verify token: (match `WHATSAPP_VERIFY_TOKEN` env var)
- [ ] Subscribe to `messages` webhook field
- [ ] Click "Verify and save"

### Firestore Setup
- [ ] Create `clientComms` collection
- [ ] Add client documents with:
  - `clientId` (string)
  - `displayName` (string)
  - `whatsappFromNumbers` (array of E.164 phone numbers)
  - `slackChannelId` (string)
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)
- [ ] Create `clientMessages` collection (will be auto-created on first message)

### Slack Setup
- [ ] Create Slack app at [api.slack.com/apps](https://api.slack.com/apps)
- [ ] Add `chat:write` OAuth scope
- [ ] Install app to workspace
- [ ] Copy bot token (`xoxb-...`) → `SLACK_BOT_TOKEN`
- [ ] Get channel IDs for:
  - Fallback channel → `SLACK_FALLBACK_CHANNEL_ID`
  - IBMS channel → `SLACK_CHANNEL_IBMS_ID` (optional)

## 🧪 Testing Flow

1. **Test Health Endpoint**:
   ```bash
   curl https://api.readyaimgo.biz/health
   ```

2. **Test Webhook Verification** (Meta will do this automatically):
   ```bash
   curl "https://api.readyaimgo.biz/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=YOUR_TOKEN&hub.challenge=test123"
   ```

3. **Send Test WhatsApp Message**:
   - Send a WhatsApp message to your Meta WhatsApp Business number
   - Check Slack channel for formatted message
   - Check Firestore `clientMessages` collection for saved message

## 🔄 Message Flow

```
WhatsApp Message
    ↓
Meta WhatsApp Cloud API
    ↓
POST /webhooks/whatsapp
    ↓
[Verify Signature] → [Respond 200 OK]
    ↓
[Async Processing]
    ├─→ Lookup client in Firestore (clientComms)
    ├─→ Post to Slack (client channel or fallback)
    └─→ Save to Firestore (clientMessages)
```

## 📝 Notes

- Messages are posted to Slack **immediately** (before saving to Firestore)
- Messages are saved to Firestore with `status: 'received'`
- Unmapped WhatsApp numbers post to fallback Slack channel
- All messages are logged to console for debugging
- Webhook signature verification is optional but recommended

## 🐛 Troubleshooting

- **Webhook verification fails**: Check `WHATSAPP_VERIFY_TOKEN` matches Meta dashboard
- **Messages not appearing in Slack**: Check `SLACK_BOT_TOKEN` and channel IDs
- **Client not found**: Verify `clientComms` collection has correct phone numbers (E.164 format)
- **Firestore errors**: Check Firebase credentials and project ID








