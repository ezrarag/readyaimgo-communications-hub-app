import SwiftUI

@main
struct ReadyaimgoHubApp: App {
    @StateObject private var supabaseManager = SupabaseManager()
    @StateObject private var openAIManager = OpenAIManager()
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseManager)
                .environmentObject(openAIManager)
                .environmentObject(authManager)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            SettingsView()
                .environmentObject(supabaseManager)
                .environmentObject(openAIManager)
        }
    }
}


