import SwiftUI

struct CommunicationMatrixView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var openAIManager: OpenAIManager
    
    @State private var searchText = ""
    @State private var selectedAudience = "All"
    @State private var selectedPurpose = "All"
    @State private var selectedTone = "All"
    @State private var showAddCommunication = false
    @State private var newCommunication = Communication(audience: "", purpose: "", tone: "")
    @State private var showAIAnalysis = false
    @State private var selectedCommunication: Communication?
    
    private let audiences = ["All", "Clients", "Investors", "Public", "Partners", "Lobbyists", "Media", "Employees"]
    private let purposes = ["All", "Inform", "Persuade", "Update", "Request", "Announce", "Clarify", "Coordinate"]
    private let tones = ["All", "Professional", "Casual", "Urgent", "Friendly", "Formal", "Confident", "Empathetic"]
    
    var filteredCommunications: [Communication] {
        var filtered = supabaseManager.communications
        
        if !searchText.isEmpty {
            filtered = filtered.filter { communication in
                communication.audience.localizedCaseInsensitiveContains(searchText) ||
                communication.purpose.localizedCaseInsensitiveContains(searchText) ||
                communication.tone.localizedCaseInsensitiveContains(searchText) ||
                communication.keyPoints.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                communication.risks.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if selectedAudience != "All" {
            filtered = filtered.filter { $0.audience == selectedAudience }
        }
        
        if selectedPurpose != "All" {
            filtered = filtered.filter { $0.purpose == selectedPurpose }
        }
        
        if selectedTone != "All" {
            filtered = filtered.filter { $0.tone == selectedTone }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Communication Matrix")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(filteredCommunications.count) communications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showAddCommunication = true }) {
                    Label("Add Communication", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Filters
            VStack(spacing: 10) {
                HStack {
                    TextField("Search communications...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                    
                    Spacer()
                }
                
                HStack {
                    Picker("Audience", selection: $selectedAudience) {
                        ForEach(audiences, id: \.self) { audience in
                            Text(audience).tag(audience)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Purpose", selection: $selectedPurpose) {
                        ForEach(purposes, id: \.self) { purpose in
                            Text(purpose).tag(purpose)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Tone", selection: $selectedTone) {
                        ForEach(tones, id: \.self) { tone in
                            Text(tone).tag(tone)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            // Communications Table
            if filteredCommunications.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No communications yet" : "No communications found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Add your first communication strategy to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCommunications) { communication in
                            CommunicationRowView(
                                communication: communication,
                                onUpdate: { updatedCommunication in
                                    Task {
                                        await supabaseManager.updateCommunication(updatedCommunication)
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await supabaseManager.deleteCommunication(communication)
                                    }
                                },
                                onAnalyze: {
                                    selectedCommunication = communication
                                    showAIAnalysis = true
                                }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            
                            Divider()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddCommunication) {
            AddCommunicationView(communication: $newCommunication) {
                Task {
                    await supabaseManager.createCommunication(newCommunication)
                    newCommunication = Communication(audience: "", purpose: "", tone: "")
                    showAddCommunication = false
                }
            }
        }
        .sheet(isPresented: $showAIAnalysis) {
            if let communication = selectedCommunication {
                AIAnalysisView(communication: communication)
                    .environmentObject(openAIManager)
            }
        }
        .onAppear {
            Task {
                await supabaseManager.loadCommunications()
            }
        }
    }
}

struct CommunicationRowView: View {
    let communication: Communication
    let onUpdate: (Communication) -> Void
    let onDelete: () -> Void
    let onAnalyze: () -> Void
    
    @State private var isEditing = false
    @State private var editedCommunication: Communication
    
    init(communication: Communication, onUpdate: @escaping (Communication) -> Void, onDelete: @escaping () -> Void, onAnalyze: @escaping () -> Void) {
        self.communication = communication
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onAnalyze = onAnalyze
        self._editedCommunication = State(initialValue: communication)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(communication.audience)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(communication.purpose)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(communication.tone)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(communication.toneColor.opacity(0.2))
                            .foregroundColor(communication.toneColor)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text(communication.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    if isEditing {
                        HStack {
                            Button("Save") {
                                onUpdate(editedCommunication)
                                isEditing = false
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Button("Cancel") {
                                editedCommunication = communication
                                isEditing = false
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    } else {
                        HStack {
                            Button("Analyze") {
                                onAnalyze()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
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
            
            if !communication.keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Key Points:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(communication.keyPoints, id: \.self) { point in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundColor(.secondary)
                            Text(point)
                                .font(.caption)
                        }
                    }
                }
            }
            
            if !communication.risks.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Risks:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    ForEach(communication.risks, id: \.self) { risk in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                            Text(risk)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            if isEditing {
                VStack(spacing: 10) {
                    HStack {
                        TextField("Audience", text: $editedCommunication.audience)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Purpose", text: $editedCommunication.purpose)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Tone", text: $editedCommunication.tone)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        TextField("Key Points (comma separated)", text: Binding(
                            get: { editedCommunication.keyPoints.joined(separator: ", ") },
                            set: { editedCommunication.keyPoints = $0.isEmpty ? [] : $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        TextField("Risks (comma separated)", text: Binding(
                            get: { editedCommunication.risks.joined(separator: ", ") },
                            set: { editedCommunication.risks = $0.isEmpty ? [] : $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }
}

struct AddCommunicationView: View {
    @Binding var communication: Communication
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Communication Details") {
                    TextField("Audience", text: $communication.audience)
                    TextField("Purpose", text: $communication.purpose)
                    TextField("Tone", text: $communication.tone)
                }
                
                Section("Key Points") {
                    TextField("Key Points (comma separated)", text: Binding(
                        get: { communication.keyPoints.joined(separator: ", ") },
                        set: { communication.keyPoints = $0.isEmpty ? [] : $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                }
                
                Section("Risks") {
                    TextField("Risks (comma separated)", text: Binding(
                        get: { communication.risks.joined(separator: ", ") },
                        set: { communication.risks = $0.isEmpty ? [] : $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                }
            }
            .navigationTitle("Add Communication")
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
                    .disabled(communication.audience.isEmpty || communication.purpose.isEmpty || communication.tone.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct AIAnalysisView: View {
    let communication: Communication
    @EnvironmentObject var openAIManager: OpenAIManager
    @Environment(\.dismiss) private var dismiss
    @State private var analysis: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if openAIManager.isLoading {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Analyzing communication strategy...")
                            .font(.headline)
                    }
                } else if !analysis.isEmpty {
                    ScrollView {
                        Text(analysis)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .padding()
                    }
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("AI Analysis")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Get AI-powered insights about your communication strategy")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Analyze") {
                            Task {
                                if let result = await openAIManager.analyzeCommunication(communication: communication) {
                                    analysis = result
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    CommunicationMatrixView()
        .environmentObject(SupabaseManager())
        .environmentObject(OpenAIManager())
}
