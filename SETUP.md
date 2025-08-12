# Readyaimgo Hub Setup Guide

This guide will walk you through setting up your Readyaimgo Communications Hub app with your own Supabase database and OpenAI API access.

## Prerequisites

- macOS 12.0 or later
- Xcode 14.0 or later
- A Supabase account (free at [supabase.com](https://supabase.com))
- An OpenAI API key (get one at [platform.openai.com](https://platform.openai.com/api-keys))

## Step 1: Set Up Supabase

### 1.1 Create a New Project
1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Choose your organization
4. Enter a project name (e.g., "Readyaimgo Hub")
5. Enter a database password (save this securely)
6. Choose a region close to you
7. Click "Create new project"

### 1.2 Set Up the Database Schema
1. In your Supabase project dashboard, go to the "SQL Editor" tab
2. Copy the entire contents of `supabase/schema.sql`
3. Paste it into the SQL editor and click "Run"
4. This will create all the necessary tables and security policies

### 1.3 Get Your Project Credentials
1. Go to "Settings" → "API" in your Supabase dashboard
2. Copy your "Project URL" (looks like `https://abc123.supabase.co`)
3. Copy your "anon public" key (starts with `eyJ...`)

## Step 2: Get Your OpenAI API Key

### 2.1 Create an OpenAI Account
1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign up or sign in
3. Go to "API Keys" in your dashboard
4. Click "Create new secret key"
5. Give it a name (e.g., "Readyaimgo Hub")
6. Copy the API key (starts with `sk-...`)

## Step 3: Build and Run the App

### 3.1 Open in Xcode
1. Open `ReadyaimgoHub.xcodeproj` in Xcode
2. Select your development team in the project settings
3. Build the project (⌘+B)

### 3.2 Configure the App
1. Run the app (⌘+R)
2. You'll see the authentication screen
3. Click the gear icon (⚙️) in the toolbar to open Settings
4. Enter your Supabase credentials:
   - Project URL: `https://your-project-id.supabase.co`
   - Anon Key: `your-anon-key-here`
5. Enter your OpenAI API key
6. Click "Save"

### 3.3 Create Your First Account
1. In the authentication screen, click "Need an account? Sign Up"
2. Enter your email and create a password
3. Click "Create Account"
4. You'll be signed in and see the main app interface

## Step 4: Start Using Your Hub

### 4.1 Master Index
- Add your first project chat
- Include links to existing chat platforms
- Track project status and notes

### 4.2 Communication Matrix
- Define your communication strategies
- Set audience, purpose, and tone
- Use AI analysis for insights

### 4.3 Template Library
- Create message templates for different audiences
- Use AI to generate new templates
- Organize by category (Clients, Investors, etc.)

### 4.4 Priority Board
- Manage your communications tasks
- Drag and drop between Now/Next/Later
- Set priorities and deadlines

### 4.5 Narrative Library
- Define your core messaging
- Mission, vision, origin story, pitch
- Quick copy-to-clipboard functionality

### 4.6 Confidential Playbook
- Password: `readyaimgo2024`
- Store sensitive strategic notes
- Secure access to confidential information

## Step 5: Customize and Scale

### 5.1 Add Real Data
- Import existing communications data
- Connect with your team members
- Set up real-time collaboration

### 5.2 AI Integration
- Use AI to analyze communication strategies
- Generate message templates
- Get strategic insights

### 5.3 Cross-Platform Access
- The app is designed to work on Mac, iPad, and iPhone
- Data syncs automatically via Supabase
- Access your communications hub anywhere

## Troubleshooting

### Common Issues

**App won't build:**
- Make sure you're using Xcode 14.0 or later
- Check that your development team is selected
- Verify macOS deployment target is set to 12.0+

**Can't connect to Supabase:**
- Verify your project URL and anon key
- Check that the schema was created successfully
- Ensure your project is active and not paused

**OpenAI API errors:**
- Verify your API key is correct
- Check your OpenAI account has credits
- Ensure the API key has the right permissions

**Authentication issues:**
- Try signing out and back in
- Check that your Supabase project has auth enabled
- Verify the database schema includes auth tables

### Getting Help

- Check the Supabase documentation: [supabase.com/docs](https://supabase.com/docs)
- OpenAI API documentation: [platform.openai.com/docs](https://platform.openai.com/docs)
- SwiftUI documentation: [developer.apple.com/documentation/swiftui](https://developer.apple.com/documentation/swiftui)

## Security Notes

- Never commit API keys to version control
- The app stores credentials securely in macOS Keychain
- Use Row Level Security (RLS) in Supabase for production
- Consider using environment variables for deployment

## Next Steps

Once you have the basic app running:

1. **Import your data** - Start adding your existing communications
2. **Set up your team** - Invite team members to collaborate
3. **Customize workflows** - Adapt the app to your specific needs
4. **Scale up** - Add more features and integrations as needed

## Support

For issues or questions:
- Check the app's built-in help system
- Review the README.md file
- Check the Supabase and OpenAI documentation
- Consider joining the Readyaimgo community

---

**Welcome to your new communications command center! 🚀**
