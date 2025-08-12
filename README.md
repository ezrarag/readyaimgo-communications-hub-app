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

## Support

For issues or questions, check the app's built-in help system or refer to the Supabase and OpenAI documentation.
