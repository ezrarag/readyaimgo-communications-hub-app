import SwiftUI

struct MasterIndexView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var searchText = ""
    @State private var selectedStatus = "All"
    @State private var showAddChat = false
    @State private var newChat = Chat(title: "", categoryNumber: 1)
    
    private let statuses = ["All", "active", "pending", "completed", "archived"]
    
    var filteredChats: [Chat] {
        var filtered = supabaseManager.chats
        
        if !searchText.isEmpty {
            filtered = filtered.filter { chat in
                chat.title.localizedCaseInsensitiveContains(searchText) ||
                (chat.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if selectedStatus != "All" {
            filtered = filtered.filter { $0.status == selectedStatus }
        }
        
        return filtered.sorted { $0.categoryNumber < $1.categoryNumber }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Master Index")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(filteredChats.count) project chats")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showAddChat = true }) {
                    Label("Add Chat", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Filters
            HStack {
                TextField("Search chats...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                
                Picker("Status", selection: $selectedStatus) {
                    ForEach(statuses, id: \.self) { status in
                        Text(status.capitalized).tag(status)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Chats List
            if filteredChats.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No chats yet" : "No chats found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Add your first project chat to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredChats) { chat in
                        ChatRowView(chat: chat) { updatedChat in
                            Task {
                                await supabaseManager.updateChat(updatedChat)
                            }
                        } onDelete: {
                            Task {
                                await supabaseManager.deleteChat(chat)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showAddChat) {
            AddChatView(chat: $newChat) {
                Task {
                    await supabaseManager.createChat(newChat)
                    newChat = Chat(title: "", categoryNumber: 1)
                    showAddChat = false
                }
            }
        }
        .onAppear {
            Task {
                await supabaseManager.loadChats()
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    let onUpdate: (Chat) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editedChat: Chat
    
    init(chat: Chat, onUpdate: @escaping (Chat) -> Void, onDelete: @escaping () -> Void) {
        self.chat = chat
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editedChat = State(initialValue: chat)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("#\(chat.categoryNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .leading)
                    
                    if isEditing {
                        TextField("Title", text: $editedChat.title)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(chat.title)
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: chat.status)
                }
                
                HStack {
                    if let link = chat.link, !link.isEmpty {
                        Link("View Chat", destination: URL(string: link)!)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    if let notes = chat.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                if isEditing {
                    HStack {
                        TextField("Notes", text: Binding(
                            get: { editedChat.notes ?? "" },
                            set: { editedChat.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        TextField("Link", text: Binding(
                            get: { editedChat.link ?? "" },
                            set: { editedChat.link = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                if isEditing {
                    HStack {
                        Button("Save") {
                            onUpdate(editedChat)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("Cancel") {
                            editedChat = chat
                            isEditing = false
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                } else {
                    HStack {
                        Button("Edit") {
                            isEditing = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Delete") {
                            onDelete()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "active": return .green
        case "pending": return .orange
        case "completed": return .blue
        case "archived": return .gray
        default: return .primary
        }
    }
}

struct AddChatView: View {
    @Binding var chat: Chat
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Chat Details") {
                    TextField("Title", text: $chat.title)
                    
                    Stepper("Category Number: \(chat.categoryNumber)", value: $chat.categoryNumber, in: 1...999)
                    
                    Picker("Status", selection: $chat.status) {
                        Text("Active").tag("active")
                        Text("Pending").tag("pending")
                        Text("Completed").tag("completed")
                        Text("Archived").tag("archived")
                    }
                    
                    TextField("Link (optional)", text: Binding(
                        get: { chat.link ?? "" },
                        set: { chat.link = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField("Notes (optional)", text: Binding(
                        get: { chat.notes ?? "" },
                        set: { chat.notes = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle("Add New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(chat.title.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    MasterIndexView()
        .environmentObject(SupabaseManager())
}
