import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var openAIManager: OpenAIManager
    
    @State private var selectedTab: Int? = 0
    @State private var showSettings = false
    @State private var isHovering = false
    
    var body: some View {
        if authManager.showAuthView {
            // Minimal hover-based navigation
            ZStack {
                // Background
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Center content
                VStack(spacing: 0) {
                    Text("Authentication View")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.primary)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHovering = hovering
                            }
                        }
                    
                    // Dropdown menu that appears on hover
                    if isHovering {
                        VStack(spacing: 0) {
                            ForEach(0..<6) { index in
                                let menuItems = [
                                    "Master Index",
                                    "Communication Matrix", 
                                    "Template Library",
                                    "Priority Board",
                                    "Narrative Library",
                                    "Confidential Playbook"
                                ]
                                
                                Text(menuItems[index])
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(.primary)
                                    .opacity(1.0 - (Double(index) * 0.15)) // Fade towards bottom
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.clear)
                                    .onTapGesture {
                                        selectedTab = index
                                        isHovering = false
                                    }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.windowBackgroundColor).opacity(0.95))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                }
                .frame(maxWidth: 300)
            }
        } else {
            // Main app content (existing code)
            NavigationView {
                SidebarView(selectedTab: $selectedTab)
                
                TabView(selection: $selectedTab) {
                    Text("Master Index View")
                        .tabItem {
                            Label("Master Index", systemImage: "list.bullet")
                        }
                        .tag(0)
                    
                    Text("Communication Matrix View")
                        .tabItem {
                            Label("Communication Matrix", systemImage: "tablecells")
                        }
                        .tag(1)
                    
                    Text("Template Library View")
                        .tabItem {
                            Label("Templates", systemImage: "doc.text")
                        }
                        .tag(2)
                    
                    Text("Priority Board View")
                        .tabItem {
                            Label("Priority Board", systemImage: "kanban")
                        }
                        .tag(3)
                    
                    Text("Narrative Library View")
                        .tabItem {
                            Label("Narratives", systemImage: "book")
                        }
                        .tag(4)
                    
                    Text("Confidential Playbook View")
                        .tabItem {
                            Label("Playbook", systemImage: "lock.shield")
                        }
                        .tag(5)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        if openAIManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                        }
                        
                        Menu {
                            Button("Sign Out") {
                                authManager.signOut()
                            }
                        } label: {
                            Image(systemName: "person.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(supabaseManager)
                    .environmentObject(openAIManager)
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct SidebarView: View {
    @Binding var selectedTab: Int?
    
    var body: some View {
        List {
            NavigationLink(destination: Text("Master Index View"), tag: 0, selection: $selectedTab) {
                Label("Master Index", systemImage: "list.bullet")
            }
            
            NavigationLink(destination: Text("Communication Matrix View"), tag: 1, selection: $selectedTab) {
                Label("Communication Matrix", systemImage: "tablecells")
            }
            
            NavigationLink(destination: Text("Template Library View"), tag: 2, selection: $selectedTab) {
                Label("Template Library", systemImage: "doc.text")
            }
            
            NavigationLink(destination: Text("Priority Board View"), tag: 3, selection: $selectedTab) {
                Label("Priority Board", systemImage: "kanban")
            }
            
            NavigationLink(destination: Text("Narrative Library View"), tag: 4, selection: $selectedTab) {
                Label("Narrative Library", systemImage: "book")
            }
            
            NavigationLink(destination: Text("Confidential Playbook View"), tag: 5, selection: $selectedTab) {
                Label("Confidential Playbook", systemImage: "lock.shield")
            }
        }
        .listStyle(SidebarListStyle())
    }
}

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

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
        .environmentObject(OpenAIManager())
}
