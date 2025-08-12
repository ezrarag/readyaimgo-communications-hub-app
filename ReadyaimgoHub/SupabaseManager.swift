import Foundation
import SwiftUI

// MARK: - Placeholder Types (to be replaced with actual Supabase types)
struct User {
    let id: String
    let email: String
    let name: String?
}

struct Chat {
    let id: String
    let title: String
    let number: String
    let status: String
    let createdAt: Date
}

struct Communication {
    let id: String
    let audience: String
    let purpose: String
    let tone: String
    let keyPoints: String
    let risks: String
}

struct Template {
    let id: String
    let title: String
    let content: String
    let category: String
}

struct Narrative {
    let id: String
    let title: String
    let content: String
    let type: String
}

struct Task {
    let id: String
    let title: String
    let description: String
    let priority: String
    let status: String
}

class SupabaseManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Configuration
    @AppStorage("supabase_url") var projectURL: String = ""
    @AppStorage("supabase_anon_key") var anonKey: String = ""
    
    // Data
    @Published var chats: [Chat] = []
    @Published var communications: [Communication] = []
    @Published var templates: [Template] = []
    @Published var narratives: [Narrative] = []
    @Published var tasks: [Task] = []
    
    init() {
        loadMockData()
    }
    
    func setupSupabase() {
        // Placeholder for Supabase setup
        print("Supabase setup would happen here with URL: \(projectURL)")
    }
    
    func saveConfiguration() {
        setupSupabase()
    }
    
    // MARK: - Mock Data Loading
    private func loadMockData() {
        // Load sample data for development
        chats = [
            Chat(id: "1", title: "Product Launch", number: "CHAT-001", status: "Active", createdAt: Date()),
            Chat(id: "2", title: "Investor Meeting", number: "CHAT-002", status: "Planning", createdAt: Date()),
            Chat(id: "3", title: "Team Retrospective", number: "CHAT-003", status: "Completed", createdAt: Date())
        ]
        
        communications = [
            Communication(id: "1", audience: "Investors", purpose: "Funding Update", tone: "Professional", keyPoints: "Growth metrics, market expansion", risks: "Market volatility"),
            Communication(id: "2", audience: "Customers", purpose: "Product Update", tone: "Friendly", keyPoints: "New features, improved UX", risks: "User adoption")
        ]
        
        templates = [
            Template(id: "1", title: "Investor Pitch", content: "We are excited to share...", category: "Investors"),
            Template(id: "2", title: "Customer Newsletter", content: "Thank you for your support...", category: "Customers")
        ]
        
        narratives = [
            Narrative(id: "1", title: "Mission Statement", content: "To revolutionize communication...", type: "Mission"),
            Narrative(id: "2", title: "Origin Story", content: "It all began when...", type: "Origin")
        ]
        
        tasks = [
            Task(id: "1", title: "Prepare Q4 Report", description: "Compile quarterly metrics", priority: "High", status: "Now"),
            Task(id: "2", title: "Update Website", description: "Refresh content and design", priority: "Medium", status: "Next")
        ]
    }
    
    // MARK: - Authentication (Mock)
    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        // Removed Task.sleep for compatibility
        
        // Mock authentication
        let user = User(id: "user-1", email: email, name: "Demo User")
        self.currentUser = user
        self.isAuthenticated = true
        
        isLoading = false
    }
    
    @MainActor
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        // Removed Task.sleep for compatibility
        
        // Mock registration
        let user = User(id: "user-1", email: email, name: "Demo User")
        self.currentUser = user
        self.isAuthenticated = true
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        self.currentUser = nil
        self.isAuthenticated = false
        clearAllData()
    }
    
    // MARK: - Data Management
    func loadAllData() async {
        // Mock data is already loaded in init
    }
    
    func clearAllData() {
        chats.removeAll()
        communications.removeAll()
        templates.removeAll()
        narratives.removeAll()
        tasks.removeAll()
    }
    
    // MARK: - CRUD Operations
    func addChat(_ chat: Chat) {
        chats.append(chat)
    }
    
    func updateChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
        }
    }
    
    func deleteChat(_ chat: Chat) {
        chats.removeAll { $0.id == chat.id }
    }
    
    func addCommunication(_ communication: Communication) {
        communications.append(communication)
    }
    
    func updateCommunication(_ communication: Communication) {
        if let index = communications.firstIndex(where: { $0.id == communication.id }) {
            communications[index] = communication
        }
    }
    
    func deleteCommunication(_ communication: Communication) {
        communications.removeAll { $0.id == communication.id }
    }
    
    func addTemplate(_ template: Template) {
        templates.append(template)
    }
    
    func updateTemplate(_ template: Template) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        }
    }
    
    func deleteTemplate(_ template: Template) {
        templates.removeAll { $0.id == template.id }
    }
    
    func addNarrative(_ narrative: Narrative) {
        narratives.append(narrative)
    }
    
    func updateNarrative(_ narrative: Narrative) {
        if let index = narratives.firstIndex(where: { $0.id == narrative.id }) {
            narratives[index] = narrative
        }
    }
    
    func deleteNarrative(_ narrative: Narrative) {
        narratives.removeAll { $0.id == narrative.id }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
}
