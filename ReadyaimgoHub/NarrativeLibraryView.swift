import SwiftUI

struct NarrativeLibraryView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    @State private var showAddNarrative = false
    @State private var newNarrative = Narrative(type: "", content: "")
    @State private var editingNarrative: Narrative?
    
    var narrativesByType: [String: [Narrative]] {
        Dictionary(grouping: supabaseManager.narratives) { $0.type }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Narrative Library")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Core messaging consistency")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showAddNarrative = true }) {
                    Label("Add Narrative", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Narratives Grid
            if supabaseManager.narratives.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "book")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No narratives yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your core messaging to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(NarrativeType.allCases, id: \.self) { narrativeType in
                            if let narratives = narrativesByType[narrativeType.rawValue],
                               let narrative = narratives.first {
                                NarrativeCardView(
                                    narrative: narrative,
                                    onUpdate: { updatedNarrative in
                                        Task {
                                            await supabaseManager.updateNarrative(updatedNarrative)
                                        }
                                    }
                                )
                            } else {
                                EmptyNarrativeCard(narrativeType: narrativeType) {
                                    newNarrative = Narrative(type: narrativeType.rawValue, content: "")
                                    showAddNarrative = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showAddNarrative) {
            AddNarrativeView(narrative: $newNarrative) {
                Task {
                    await supabaseManager.createNarrative(newNarrative)
                    newNarrative = Narrative(type: "", content: "")
                    showAddNarrative = false
                }
            }
        }
        .onAppear {
            Task {
                await supabaseManager.loadNarratives()
            }
        }
    }
}

struct NarrativeCardView: View {
    let narrative: Narrative
    let onUpdate: (Narrative) -> Void
    
    @State private var isEditing = false
    @State private var editedNarrative: Narrative
    @State private var showCopiedMessage = false
    
    init(narrative: Narrative, onUpdate: @escaping (Narrative) -> Void) {
        self.narrative = narrative
        self.onUpdate = onUpdate
        self._editedNarrative = State(initialValue: narrative)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(narrative.type.capitalized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(narrative.updatedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isEditing {
                    HStack {
                        Button("Save") {
                            onUpdate(editedNarrative)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("Cancel") {
                            editedNarrative = narrative
                            isEditing = false
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Content
            if isEditing {
                if #available(macOS 13.0, *) {
                    TextField("Content", text: $editedNarrative.content, axis: .vertical)
                        .lineLimit(5...10)
                } else {
                    TextField("Content", text: $editedNarrative.content)
                }
            } else {
                Text(narrative.content)
                    .font(.body)
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
            }
            
            // Copy Button
            if !isEditing {
                Button(action: copyToClipboard) {
                    HStack {
                        Image(systemName: showCopiedMessage ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                        Text(showCopiedMessage ? "Copied!" : "Copy to Clipboard")
                            .font(.caption)
                    }
                    .foregroundColor(showCopiedMessage ? .green : .blue)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(showCopiedMessage)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(narrative.content, forType: .string)
        
        showCopiedMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedMessage = false
        }
    }
}

struct EmptyNarrativeCard: View {
    let narrativeType: NarrativeType
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "plus.circle")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
            
            Text(narrativeType.displayName)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("No content yet")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Add Content") {
                onAdd()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
}

struct AddNarrativeView: View {
    @Binding var narrative: Narrative
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Narrative Details") {
                    Picker("Type", selection: $narrative.type) {
                        ForEach(NarrativeType.allCases, id: \.self) { narrativeType in
                            Text(narrativeType.displayName).tag(narrativeType.rawValue)
                        }
                    }
                    
                    if #available(macOS 13.0, *) {
                        TextField("Content", text: $narrative.content, axis: .vertical)
                            .lineLimit(5...15)
                    } else {
                        TextField("Content", text: $narrative.content)
                    }
                }
            }
            .navigationTitle("Add Narrative")
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
                    .disabled(narrative.type.isEmpty || narrative.content.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 300)
    }
}

#Preview {
    NarrativeLibraryView()
        .environmentObject(SupabaseManager())
}
