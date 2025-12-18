# Readyaimgo Communications Hub App

A native macOS application for managing communications, project chats, and strategic messaging across all your business channels.

## Features

### 🎯 Master Index
- List all project chats with title, number, status, and direct links
- Add new chats manually or import from Supabase
- Quick search and filtering

### 📊 Communication Matrix
- Table view with filters: Audience, Purpose, Tone, Key Points, Risks
- Editable inline in app, stored in Supabase
- Real-time collaboration

### 📝 Message Template Library
- Store reusable drafts (email, SMS, press release, proposal)
- Categories: Clients, Investors, Public, Partners, Lobbyists
- Quick copy-to-clipboard functionality

### 📋 Status & Priority Board
- Kanban view: Now / Next / Later
- Drag-and-drop task management
- Visual priority tracking

### 🎭 Core Narrative Library
- Mission statement, origin story, vision, pitch
- Quick "Copy to Clipboard" buttons for each
- Centralized messaging consistency

### 🔒 Confidential Playbook Section
- Password-protected area for sensitive strategy notes
- Secure storage with Keychain integration

## Tech Stack

- **Frontend**: SwiftUI (macOS native)
- **Backend**: Supabase (PostgreSQL + Auth)
- **AI Integration**: OpenAI API for ChatGPT prompts
- **Authentication**: Supabase Auth with email/password
- **Sync**: Real-time updates across all devices

## Setup Instructions

### Prerequisites
- macOS 12.0 or later
- Xcode 14.0 or later
- Supabase account
- OpenAI API key

### 1. Supabase Setup
1. Create a new Supabase project
2. Run the SQL schema provided in `supabase/schema.sql`
3. Get your project URL and anon key

### 2. Environment Configuration
1. Copy `Config.example.swift` to `Config.swift`
2. Add your Supabase and OpenAI credentials

### 3. Build and Run
1. Open `ReadyaimgoHub.xcodeproj` in Xcode
2. Select your development team
3. Build and run the app

## Data Structure

The app uses the following Supabase tables:
- `chats` - Project chat management
- `communications` - Communication matrix data
- `templates` - Message templates
- `narratives` - Core messaging content
- `tasks` - Priority board items

## Security Features

- API keys stored securely in macOS Keychain
- Password-protected confidential sections
- Supabase Row Level Security (RLS) enabled
- Encrypted data transmission

## Cross-Platform Support

While this is built as a macOS app, the architecture supports future expansion to:
- iPadOS (SwiftUI adaptation)
- iOS (SwiftUI adaptation)
- Web dashboard (optional)

## Getting Started

1. Set up your Supabase project
2. Configure your API keys
3. Build and run the app
4. Start adding your communications data
5. Connect with OpenAI for AI-powered messaging assistance

## WhatsApp Webhook Integration

This project includes a Next.js backend for handling WhatsApp webhooks via Meta WhatsApp Cloud API.

### WhatsApp Webhook Setup

#### 1. Environment Configuration

Copy `.env.example` to `.env` and configure the following variables:

- `WHATSAPP_VERIFY_TOKEN`: Token for webhook verification (set in Meta dashboard)
- `SLACK_BOT_TOKEN`: Slack bot token (starts with `xoxb-`)
- `SLACK_FALLBACK_CHANNEL_ID`: Channel ID for unmapped messages
- `SLACK_CHANNEL_IBMS_ID`: Channel ID for IBMS client messages
- `FIREBASE_PROJECT_ID`: Firebase project ID
- `FIREBASE_CLIENT_EMAIL`: Firebase service account email
- `FIREBASE_PRIVATE_KEY`: Firebase service account private key (with escaped newlines)
- `ADMIN_SEED_KEY`: Secret key for admin seed endpoint

#### 2. Meta WhatsApp Cloud API Configuration

1. Go to [Meta for Developers](https://developers.facebook.com/)
2. Create or select your app
3. Add WhatsApp product to your app
4. Navigate to WhatsApp > Configuration
5. Set webhook URL: `https://your-domain.com/api/webhooks/whatsapp`
6. Set verify token (must match `WHATSAPP_VERIFY_TOKEN` in `.env`)
7. Subscribe to `messages` webhook field

#### 3. Firebase Firestore Setup

The webhook expects the following Firestore collections:

**`clientComms` collection:**
- Document ID: `{clientId}` (e.g., `ibms`)
- Fields:
  - `clientId` (string)
  - `displayName` (string)
  - `whatsappFromNumbers` (array of E.164 phone numbers)
  - `slackChannelId` (string)
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)

**`clientMessages` collection:**
- Auto-generated document IDs
- Fields:
  - `clientId` (string | null)
  - `source` (string, e.g., "whatsapp")
  - `from` (string, phone number)
  - `body` (string, message text)
  - `timestamp` (string)
  - `messageId` (string)
  - `raw` (object, optional)
  - `createdAt` (timestamp)

#### 4. Seed IBMS Client Configuration

After setting up environment variables, seed the IBMS client:

```bash
curl -X POST https://your-domain.com/api/admin/seed/ibms \
  -H "Authorization: Bearer YOUR_ADMIN_SEED_KEY"
```

Or locally:

```bash
curl -X POST http://localhost:3000/api/admin/seed/ibms \
  -H "Authorization: Bearer YOUR_ADMIN_SEED_KEY"
```

#### 5. Testing the Webhook

**Verification (GET):**
```bash
curl "http://localhost:3000/api/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=YOUR_TOKEN&hub.challenge=test123"
```

**Message (POST) - Sample payload:**
```bash
curl -X POST http://localhost:3000/api/webhooks/whatsapp \
  -H "Content-Type: application/json" \
  -d '{
    "object": "whatsapp_business_account",
    "entry": [{
      "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
      "changes": [{
        "value": {
          "messaging_product": "whatsapp",
          "metadata": {
            "display_phone_number": "15550551234",
            "phone_number_id": "PHONE_NUMBER_ID"
          },
          "contacts": [{
            "profile": {
              "name": "John Doe"
            },
            "wa_id": "15551234567"
          }],
          "messages": [{
            "from": "15551234567",
            "id": "wamid.xxx",
            "timestamp": "1234567890",
            "type": "text",
            "text": {
              "body": "Hello, this is a test message"
            }
          }]
        },
        "field": "messages"
      }]
    }]
  }'
```

#### 6. Local Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Run development server:
   ```bash
   npm run dev
   ```

3. Use a tunneling service (e.g., ngrok) to expose localhost:
   ```bash
   ngrok http 3000
   ```

4. Update Meta webhook URL to your ngrok URL: `https://your-ngrok-url.ngrok.io/api/webhooks/whatsapp`

### Webhook Flow

1. Client sends WhatsApp message → Meta WhatsApp Cloud API
2. Meta sends webhook POST to `/api/webhooks/whatsapp`
3. System looks up client by phone number in `clientComms` collection
4. If found:
   - Saves message to `clientMessages` collection
   - Posts formatted message to client's Slack channel
5. If not found:
   - Saves message with `clientId: null`
   - Posts warning to fallback Slack channel

## Support

For issues or questions, check the app's built-in help system or refer to the Supabase and OpenAI documentation.
