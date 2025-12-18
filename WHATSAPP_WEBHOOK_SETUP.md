# WhatsApp Webhook Setup Guide

## Endpoints

### Production URLs

- **Webhook:** `https://<YOUR_DOMAIN>/webhooks/whatsapp`
- **Health Check:** `https://<YOUR_DOMAIN>/health`

## Environment Variables

Required environment variables (set in `.env` or your hosting platform):

```bash
# Meta WhatsApp Configuration
WHATSAPP_VERIFY_TOKEN=readyaimgo_whatsapp_verify_2025
META_APP_SECRET=your_meta_app_secret_here

# Firebase Configuration (for Firestore)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

## Implementation Details

### GET /webhooks/whatsapp (Verification)

Meta sends a GET request during webhook setup:
```
GET /webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=TOKEN&hub.challenge=CHALLENGE
```

**Response:**
- `200 OK` with challenge text if token matches `WHATSAPP_VERIFY_TOKEN`
- `403 Forbidden` if token doesn't match

### POST /webhooks/whatsapp (Message Receiving)

**Security:**
- Verifies `X-Hub-Signature-256` header using `META_APP_SECRET`
- Returns `401 Unauthorized` if signature is invalid
- If `META_APP_SECRET` is not set, verification is skipped (with warning)

**Processing Flow:**
1. Verify signature (if `META_APP_SECRET` configured)
2. Respond `200 OK` immediately (before processing)
3. Parse payload asynchronously
4. Extract message data
5. Look up client by WhatsApp number (`clientComms` collection)
6. Write to Firestore `clientMessages` collection

**Firestore Document Schema:**
```typescript
{
  clientId: string | null,           // From clientComms lookup
  channel: "whatsapp",               // Always "whatsapp"
  source: "whatsapp",                 // Always "whatsapp"
  status: "received",                // Always "received"
  from: string,                      // WhatsApp phone number
  text: string,                      // Message text (if text message)
  body: string,                      // Message body
  timestamp: string,                  // WhatsApp timestamp
  messageId: string,                  // WhatsApp message ID
  createdAt: Timestamp,              // Server timestamp
  raw: {
    phoneNumberId?: string,
    displayPhoneNumber?: string,
    profileName?: string,
    messageType: string,
    fullPayload: object,             // Complete webhook payload
  }
}
```

**Note:** The Firestore trigger (`postClientMessageToSlack`) will automatically post to Slack when documents are created with `status: "pending"`. Since we're using `status: "received"`, you may want to update the trigger or change this to `"pending"` if you want automatic Slack posting.

### GET /health (Health Check)

Simple health check endpoint:
- Returns `200 OK` with JSON: `{"status": "ok", "timestamp": "..."}`

## Meta Configuration

### 1. Set Webhook URL

In [Meta for Developers](https://developers.facebook.com/):

1. Go to your app → WhatsApp → Configuration
2. Set **Callback URL:** `https://<YOUR_DOMAIN>/webhooks/whatsapp`
3. Set **Verify token:** `readyaimgo_whatsapp_verify_2025`
4. Click **Verify and Save**

### 2. Subscribe to Webhooks

Subscribe to the `messages` field:
- WhatsApp → Configuration → Webhook fields
- Check `messages`
- Click **Save**

### 3. Get App Secret

1. Go to Settings → Basic
2. Find **App Secret**
3. Click **Show** and copy it
4. Set as `META_APP_SECRET` in your environment

## Testing

### Test Verification (GET)

```bash
curl "https://your-domain.com/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=readyaimgo_whatsapp_verify_2025&hub.challenge=test123"
```

Expected: `200 OK` with body `test123`

### Test Health Check

```bash
curl https://your-domain.com/health
```

Expected: `200 OK` with JSON response

### Test Webhook (POST)

Send a test message from WhatsApp to your configured number. Check:
1. Firestore `clientMessages` collection for new document
2. Function logs: `firebase functions:log`
3. Application logs for any errors

## Troubleshooting

### Signature Verification Failing

- Verify `META_APP_SECRET` is set correctly
- Check that `X-Hub-Signature-256` header is present
- Ensure raw body is used for signature (not parsed JSON)

### Messages Not Appearing in Firestore

- Check application logs for errors
- Verify Firebase credentials are correct
- Check Firestore security rules allow writes
- Verify `clientMessages` collection exists

### Verification Failing

- Ensure `WHATSAPP_VERIFY_TOKEN` matches Meta dashboard
- Check query parameters are correct (`hub.mode`, `hub.verify_token`, `hub.challenge`)
- Verify endpoint is publicly accessible

### Client Lookup Not Working

- Ensure `clientComms` collection has documents
- Verify `whatsappFromNumbers` array contains the phone number
- Phone numbers should be in E.164 format (e.g., `+1234567890`)

## Architecture

```
WhatsApp → Meta Webhook → /webhooks/whatsapp
                              ↓
                    Signature Verification
                              ↓
                    Respond 200 OK (quick)
                              ↓
                    Parse Payload (async)
                              ↓
                    Lookup Client (clientComms)
                              ↓
                    Write to Firestore (clientMessages)
                              ↓
                    Firestore Trigger (if status="pending")
                              ↓
                    Post to Slack
```

## Next Steps

1. **Deploy to production**
2. **Configure Meta webhook** with your production URL
3. **Test with real WhatsApp messages**
4. **Monitor Firestore** for incoming messages
5. **Set up alerts** for webhook failures
