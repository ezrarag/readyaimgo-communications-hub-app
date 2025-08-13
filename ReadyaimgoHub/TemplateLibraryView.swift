import SwiftUI

struct TemplateLibraryView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var openAIManager: OpenAIManager
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showAddTemplate = false
    @State private var showGenerateTemplate = false
    @State private var newTemplate = Template(category: "", shortVersion: "")
    
    private let categories = ["All"] + TemplateCategory.allCases.map { $0.displayName }
    
    var filteredTemplates: [Template] {
        var filtered = supabaseManager.templates
        
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.category.localizedCaseInsensitiveContains(searchText) ||
                template.shortVersion.localizedCaseInsensitiveContains(searchText) ||
                (template.longVersion?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Template Library")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(filteredTemplates.count) templates")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Button(action: { showGenerateTemplate = true }) {
                        Label("Generate with AI", systemImage: "sparkles")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showAddTemplate = true }) {
                        Label("Add Template", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            // Filters
            HStack {
                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Templates Grid
            if filteredTemplates.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No templates yet" : "No templates found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Add your first message template to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(filteredTemplates) { template in
                            TemplateCardView(
                                template: template,
                                onUpdate: { updatedTemplate in
                                    Task {
                                        await supabaseManager.updateTemplate(updatedTemplate)
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await supabaseManager.deleteTemplate(template)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showAddTemplate) {
            AddTemplateView(template: $newTemplate) {
                Task {
                    await supabaseManager.createTemplate(newTemplate)
                    newTemplate = Template(category: "", shortVersion: "")
                    showAddTemplate = false
                }
            }
        }
        .sheet(isPresented: $showGenerateTemplate) {
            GenerateTemplateView()
                .environmentObject(openAIManager)
                .environmentObject(supabaseManager)
        }
        .onAppear {
            Task {
                await supabaseManager.loadTemplates()
            }
        }
    }
}

struct TemplateCardView: View {
    let template: Template
    let onUpdate: (Template) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editedTemplate: Template
    @State private var showLongVersion = false
    @State private var showConfidentialVersion = false
    
    init(template: Template, onUpdate: @escaping (Template) -> Void, onDelete: @escaping () -> Void) {
        self.template = template
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editedTemplate = State(initialValue: template)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                Text(template.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(template.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Short Version
            if isEditing {
                if #available(macOS 13.0, *) {
                    TextField("Short Version", text: $editedTemplate.shortVersion, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    TextField("Short Version", text: $editedTemplate.shortVersion)
                }
            } else {
                Text(template.shortVersion)
                    .font(.body)
                    .lineLimit(3)
            }
            
            // Long Version (if exists)
            if let longVersion = template.longVersion, !longVersion.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Button(action: { showLongVersion.toggle() }) {
                        HStack {
                            Text("View Long Version")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Image(systemName: showLongVersion ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showLongVersion {
                        Text(longVersion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Confidential Version (if exists)
            if let confidentialVersion = template.confidentialVersion, !confidentialVersion.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Button(action: { showConfidentialVersion.toggle() }) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .font(.caption)
                            Text("View Confidential Version")
                                .font(.caption)
                                .foregroundColor(.red)
                            Image(systemName: showConfidentialVersion ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showConfidentialVersion {
                        Text(confidentialVersion)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Actions
            HStack {
                Button("Copy Short") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(template.shortVersion, forType: .string)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if template.longVersion != nil {
                    Button("Copy Long") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(template.longVersion!, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Spacer()
                
                if isEditing {
                    HStack {
                        Button("Save") {
                            onUpdate(editedTemplate)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("Cancel") {
                            editedTemplate = template
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
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct AddTemplateView: View {
    @Binding var template: Template
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Template Details") {
                    Picker("Category", selection: $template.category) {
                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category.displayName)
                        }
                    }
                    
                    Section("Template Content") {
                        if #available(macOS 13.0, *) {
                            TextField("Short Version", text: $template.shortVersion, axis: .vertical)
                                .lineLimit(3...6)
                        } else {
                            TextField("Short Version", text: $template.shortVersion)
                        }
                        
                        if #available(macOS 13.0, *) {
                            TextField("Long Version", text: Binding(
                                get: { template.longVersion ?? "" },
                                set: { template.longVersion = $0.isEmpty ? nil : $0 }
                            ), axis: .vertical)
                            .lineLimit(5...10)
                        } else {
                            TextField("Long Version", text: Binding(
                                get: { template.longVersion ?? "" },
                                set: { template.longVersion = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        if #available(macOS 13.0, *) {
                            TextField("Confidential Version", text: Binding(
                                get: { template.confidentialVersion ?? "" },
                                set: { template.confidentialVersion = $0.isEmpty ? nil : $0 }
                            ), axis: .vertical)
                            .lineLimit(5...10)
                        } else {
                            TextField("Confidential Version", text: Binding(
                                get: { template.confidentialVersion ?? "" },
                                set: { template.confidentialVersion = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                }
            }
            .navigationTitle("Add Template")
        }
        .frame(width: 500, height: 400)
    }
}

struct GenerateTemplateView: View {
    @EnvironmentObject var openAIManager: OpenAIManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory = TemplateCategory.clients
    @State private var purpose = ""
    @State private var keyPoints = ""
    @State private var generatedTemplate: String = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isGenerating {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Generating template with AI...")
                            .font(.headline)
                    }
                } else if !generatedTemplate.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Generated Template")
                                .font(.headline)
                            
                            Text(generatedTemplate)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            
                            HStack {
                                Button("Save as Template") {
                                    saveGeneratedTemplate()
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Generate Another") {
                                    generatedTemplate = ""
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("AI Template Generator")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 15) {
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(TemplateCategory.allCases, id: \.self) { category in
                                    Text(category.displayName).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            TextField("Purpose", text: $purpose)
                            
                            TextField("Key Points (comma separated)", text: $keyPoints)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button("Generate Template") {
                            generateTemplate()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(purpose.isEmpty || keyPoints.isEmpty)
                    }
                }
            }
            .padding()
            .navigationTitle("AI Template Generator")
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
    
    private func generateTemplate() {
        isGenerating = true
        
        Task {
            if let result = await openAIManager.generateTemplate(
                purpose: purpose,
                audience: selectedCategory.displayName,
                tone: "professional"
            ) {
                generatedTemplate = result
            }
            isGenerating = false
        }
    }
    
    private func saveGeneratedTemplate() {
        let template = Template(
            category: selectedCategory.displayName,
            shortVersion: generatedTemplate,
            longVersion: nil,
            confidentialVersion: nil
        )
        
        Task {
            await supabaseManager.createTemplate(template)
            dismiss()
        }
    }
}

#Preview {
    TemplateLibraryView()
        .environmentObject(SupabaseManager())
        .environmentObject(OpenAIManager())
}
