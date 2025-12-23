# Quick Testing Checklist: WhatsApp → Slack

## Pre-Flight Checks

- [ ] Webhook endpoint is public: `https://your-domain.com/webhooks/whatsapp`
- [ ] GET verification works: `curl "https://your-domain.com/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=TOKEN&hub.challenge=test"`
- [ ] Environment variables set in Vercel/hosting platform:
  - [ ] `SLACK_BOT_TOKEN` (starts with `xoxb-`)
  - [ ] `SLACK_FALLBACK_CHANNEL_ID` (channel ID, starts with `C`)
  - [ ] `FIREBASE_PROJECT_ID`
  - [ ] `FIREBASE_CLIENT_EMAIL`
  - [ ] `FIREBASE_PRIVATE_KEY`
  - [ ] `WHATSAPP_VERIFY_TOKEN`
  - [ ] `META_APP_SECRET` (optional but recommended)

## Firestore Setup

- [ ] `clientComms` collection exists
- [ ] Document created with:
  - [ ] `clientId`: "test-client" (or your choice)
  - [ ] `displayName`: "Test Client"
  - [ ] `whatsappFromNumbers`: ["+14049739860"] (E.164 format, array)
  - [ ] `slackChannelId`: "C1234567890" (actual Slack channel ID)
  - [ ] `createdAt`: timestamp
  - [ ] `updatedAt`: timestamp

## Slack Setup

- [ ] Bot created in Slack workspace
- [ ] Bot token obtained (`xoxb-...`)
- [ ] Bot added to target channel
- [ ] Bot has `chat:write` permission
- [ ] Channel ID obtained (from URL: `.../archives/C1234567890`)

## Meta WhatsApp Setup

- [ ] Webhook URL configured: `https://your-domain.com/webhooks/whatsapp`
- [ ] Verify token matches: `WHATSAPP_VERIFY_TOKEN`
- [ ] Webhook verified (GET endpoint returns challenge)
- [ ] Subscribed to `messages` field
- [ ] App secret obtained (for signature verification)

## Test Execution

1. [ ] Send WhatsApp message from `+14049739860` to your WhatsApp Business number
2. [ ] Check Vercel/hosting logs for:
   - [ ] `Message from +14049739860 mapped to client...`
   - [ ] `posting to Slack channel...`
   - [ ] `WhatsApp message saved to Firestore`
   - [ ] No errors
3. [ ] Check Slack channel:
   - [ ] Message appears with "📲 WhatsApp message" header
   - [ ] Shows "From: +14049739860"
   - [ ] Shows "Client: Test Client"
   - [ ] Shows message text
4. [ ] Check Firestore:
   - [ ] New document in `clientMessages` collection
   - [ ] `from`: "+14049739860"
   - [ ] `clientId`: "test-client"
   - [ ] `status`: "received"
   - [ ] `channel`: "whatsapp"

## Troubleshooting

### No message in Slack
- [ ] Check logs for `Error posting to Slack`
- [ ] Verify `SLACK_BOT_TOKEN` is valid
- [ ] Verify bot is in channel
- [ ] Check channel ID is correct (not channel name)

### Client lookup fails
- [ ] Verify phone number in E.164 format: `+14049739860`
- [ ] Check `clientComms` document exists
- [ ] Verify `whatsappFromNumbers` is an array
- [ ] Check Firestore query permissions

### Webhook not receiving
- [ ] Verify webhook URL in Meta dashboard
- [ ] Check webhook is verified
- [ ] Ensure subscribed to `messages` field
- [ ] Test GET endpoint manually

### Firestore write fails
- [ ] Check Firebase Admin credentials
- [ ] Verify Firestore security rules allow writes
- [ ] Check `clientMessages` collection exists
- [ ] Look for errors in logs

## Success Criteria

✅ Message appears in Slack within 1-2 seconds
✅ Message is properly formatted with client info
✅ Firestore document created with correct data
✅ No errors in application logs


