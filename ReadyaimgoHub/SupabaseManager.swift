import Foundation
import SwiftUI

// MARK: - User Type (to be replaced with actual Supabase User type)
struct User {
    let id: String
    let email: String
    let name: String?
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
    @Published var tasks: [ProjectTask] = []
    
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
            Chat(id: UUID(), title: "Product Launch", categoryNumber: 1, status: "active"),
            Chat(id: UUID(), title: "Investor Meeting", categoryNumber: 2, status: "pending"),
            Chat(id: UUID(), title: "Team Retrospective", categoryNumber: 3, status: "completed")
        ]
        
        communications = [
            Communication(id: UUID(), audience: "Investors", purpose: "Funding Update", tone: "professional", keyPoints: ["Growth metrics", "Market expansion"], risks: ["Market volatility"]),
            Communication(id: UUID(), audience: "Customers", purpose: "Product Update", tone: "friendly", keyPoints: ["New features", "Improved UX"], risks: ["User adoption"])
        ]
        
        templates = [
            Template(id: UUID(), category: "Investors", shortVersion: "We are excited to share..."),
            Template(id: UUID(), category: "Customers", shortVersion: "Thank you for your support...")
        ]
        
        narratives = [
            Narrative(id: UUID(), type: "mission", content: "To revolutionize communication..."),
            Narrative(id: UUID(), type: "origin_story", content: "It all began when...")
        ]
        
        tasks = [
            ProjectTask(id: UUID(), title: "Prepare Q4 Report", status: "now", description: "Compile quarterly metrics", priority: 1),
            ProjectTask(id: UUID(), title: "Update Website", status: "next", description: "Refresh content and design", priority: 2)
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
    
    func createChat(_ chat: Chat) {
        addChat(chat)
    }
    
    func loadChats() {
        // In mock mode, chats are already loaded in init
        // This would typically fetch from Supabase
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
    
    func createNarrative(_ narrative: Narrative) async {
        addNarrative(narrative)
    }
    
    func createCommunication(_ communication: Communication) async {
        addCommunication(communication)
    }
    
    func loadCommunications() async {
        // In mock mode, communications are already loaded in init
        // This would typically fetch from Supabase
    }
    
    func createTemplate(_ template: Template) async {
        addTemplate(template)
    }
    
    func loadTemplates() async {
        // In mock mode, templates are already loaded in init
        // This would typically fetch from Supabase
    }
    
    func addTask(_ task: ProjectTask) {
        tasks.append(task)
    }
    
    func createTask(_ task: ProjectTask) {
        addTask(task)
    }
    
    func loadTasks() async {
        // In mock mode, tasks are already loaded in init
        // This would typically fetch from Supabase
    }
    
    func loadNarratives() async {
        // In mock mode, narratives are already loaded in init
        // This would typically fetch from Supabase
    }
    
    func updateTask(_ task: ProjectTask) async {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    func deleteTask(_ task: ProjectTask) async {
        tasks.removeAll { $0.id == task.id }
    }
}
