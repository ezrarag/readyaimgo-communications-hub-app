// Configuration Example for Readyaimgo Hub
// Copy this file to Config.swift and add your actual credentials

import Foundation

// MARK: - Supabase Configuration
// Get these from your Supabase project dashboard
let SUPABASE_URL = "https://your-project-id.supabase.co"
let SUPABASE_ANON_KEY = "your-anon-key-here"

// MARK: - OpenAI Configuration
// Get this from your OpenAI account dashboard
let OPENAI_API_KEY = "your-openai-api-key-here"

// MARK: - Security Notes
// - Never commit your actual API keys to version control
// - Use environment variables or secure key storage in production
// - The app stores these securely in macOS Keychain when you configure them in Settings

// MARK: - Setup Instructions
// 1. Create a Supabase project at https://supabase.com
// 2. Run the SQL schema from supabase/schema.sql in your project's SQL editor
// 3. Get your project URL and anon key from the project settings
// 4. Get your OpenAI API key from https://platform.openai.com/api-keys
// 5. Configure these in the app's Settings menu
// 6. Start using your communications hub!
