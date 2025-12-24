# Debugging WhatsApp Webhook: "No Outgoing Requests"

## The Problem

Vercel logs show:
- ✅ POST `/webhooks/whatsapp` received
- ✅ 200 response sent
- ❌ **"No outgoing requests"** - This means NO Slack API calls or Firestore writes happened

## Root Cause Analysis

**YES, you absolutely need `clientComms`!** 

The code does this:
```typescript
const client = await findClientByWhatsAppNumber(from);
```

If there's no `clientComms` document mapping your phone number to a Slack channel:
- `client` will be `null`
- It will only post to `SLACK_FALLBACK_CHANNEL_ID` (if set)
- If `SLACK_FALLBACK_CHANNEL_ID` is not set, nothing happens

## What to Check

### 1. Check Vercel Logs for Errors

After sending a WhatsApp message, look for these log messages (I just added them):

**Expected logs:**
```
Starting async webhook payload processing
Processing webhook payload, rawBody length: XXX
Parsed payload: { object: 'whatsapp_business_account', ... }
Processing change: { field: 'messages', ... }
Processing message: { from: '+14049739860', ... }
Looking up client for WhatsApp number: +14049739860
Client lookup result: { found: true/false, clientId: '...', ... }
```

**If you see:**
- `Invalid webhook payload structure` → Meta payload format issue
- `Error parsing webhook payload` → JSON parse error
- `Error processing WhatsApp message` → Error in processing
- `Error finding client by WhatsApp number` → Firestore query issue
- `Error posting to Slack` → Slack API issue
- `Error writing to Firestore` → Firestore write issue

### 2. Check if `clientComms` Document Exists

Go to Firestore Console:
- Collection: `clientComms`
- Look for a document with `whatsappFromNumbers` array containing your phone number

**Required format:**
```json
{
  "clientId": "femileasing",
  "displayName": "Femi Leasing",
  "whatsappFromNumbers": ["+14049739860"],  // MUST be E.164 format with +
  "slackChannelId": "C1234567890",  // Slack channel ID (not name)
  "createdAt": [timestamp],
  "updatedAt": [timestamp]
}
```

**Critical:** 
- Phone number MUST be in E.164 format: `+14049739860` (not `404-973-9860` or `14049739860`)
- `slackChannelId` must be the actual Slack channel ID (starts with `C`), not the channel name

### 3. Check Environment Variables

In Vercel dashboard, verify these are set:

**Required:**
- `SLACK_BOT_TOKEN` - Must start with `xoxb-`
- `SLACK_FALLBACK_CHANNEL_ID` - Channel ID for unmapped numbers (starts with `C`)
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `FIREBASE_CLIENT_EMAIL` - Service account email
- `FIREBASE_PRIVATE_KEY` - Service account private key

**Optional but recommended:**
- `META_APP_SECRET` - For webhook signature verification
- `WHATSAPP_VERIFY_TOKEN` - For webhook verification (defaults to `readyaimgo_whatsapp_verify_2025`)

### 4. Check Slack Channel ID

The `slackChannelId` in `clientComms` must match the actual Slack channel ID.

**How to get channel ID:**
1. Open Slack in browser
2. Click on `#client-femileasing` channel
3. Look at URL: `https://workspace.slack.com/archives/C1234567890`
4. The `C1234567890` part is your channel ID

**Common mistake:** Using channel name (`client-femileasing`) instead of channel ID (`C1234567890`)

### 5. Verify Slack Bot Permissions

- Bot must be added to the `#client-femileasing` channel
- Bot needs `chat:write` permission
- `SLACK_BOT_TOKEN` must be valid

## Quick Fix: Create `clientComms` Document

If the document doesn't exist, create it:

1. Go to Firestore Console
2. Navigate to `clientComms` collection
3. Click "Add document"
4. Use document ID: `femileasing` (or auto-ID)
5. Add fields:
   - `clientId`: `"femileasing"`
   - `displayName`: `"Femi Leasing"`
   - `whatsappFromNumbers`: `["+14049739860"]` (array with your number in E.164)
   - `slackChannelId`: `"C1234567890"` (actual channel ID from Slack URL)
   - `createdAt`: Current timestamp
   - `updatedAt`: Current timestamp

## Testing After Fix

1. Send a WhatsApp message from `+14049739860`
2. Check Vercel logs - you should see:
   - `Looking up client for WhatsApp number: +14049739860`
   - `Client lookup result: { found: true, clientId: 'femileasing', ... }`
   - `Message from +14049739860 mapped to client femileasing, posting to Slack channel...`
   - `WhatsApp message saved to Firestore`
3. Check Slack channel `#client-femileasing` - message should appear
4. Check Firestore `clientMessages` collection - new document should be created

## If Still Not Working

Check Vercel logs for:
1. **Payload structure issues** - Look for `Invalid webhook payload structure`
2. **Firestore query errors** - Look for `Error finding client by WhatsApp number`
3. **Slack API errors** - Look for `Error posting to Slack`
4. **Firestore write errors** - Look for `Error writing to Firestore`

The new logging I added will show exactly where the process is failing.

