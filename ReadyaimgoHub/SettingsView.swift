import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var openAIManager: OpenAIManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Supabase Configuration")
                    .font(.headline)
                
                TextField("Project URL", text: $supabaseManager.projectURL)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Anon Key", text: $supabaseManager.anonKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("OpenAI Configuration")
                    .font(.headline)
                
                SecureField("API Key", text: $openAIManager.apiKey)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            
            HStack {
                Button("Save") {
                    supabaseManager.saveConfiguration()
                    openAIManager.saveConfiguration()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
