import SwiftUI

struct PriorityBoardView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    @State private var showAddTask = false
    @State private var newTask = Task(title: "", status: "later")
    @State private var draggedTask: Task?
    
    var tasksByStatus: [String: [Task]] {
        Dictionary(grouping: supabaseManager.tasks) { $0.status }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Priority Board")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(supabaseManager.tasks.count) tasks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showAddTask = true }) {
                    Label("Add Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Kanban Board
            if supabaseManager.tasks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "kanban")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No tasks yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your first task to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        KanbanColumn(
                            status: status,
                            tasks: tasksByStatus[status.rawValue] ?? [],
                            onTaskUpdate: { updatedTask in
                                Task {
                                    await supabaseManager.updateTask(updatedTask)
                                }
                            },
                            onTaskDelete: { task in
                                Task {
                                    await supabaseManager.deleteTask(task)
                                }
                            },
                            onDrop: { task in
                                var updatedTask = task
                                updatedTask.status = status.rawValue
                                Task {
                                    await supabaseManager.updateTask(updatedTask)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView(task: $newTask) {
                Task {
                    await supabaseManager.createTask(newTask)
                    newTask = Task(title: "", status: "later")
                    showAddTask = false
                }
            }
        }
        .onAppear {
            Task {
                await supabaseManager.loadTasks()
            }
        }
    }
}

struct KanbanColumn: View {
    let status: TaskStatus
    let tasks: [Task]
    let onTaskUpdate: (Task) -> Void
    let onTaskDelete: (Task) -> Void
    let onDrop: (Task) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Column Header
            VStack(spacing: 5) {
                HStack {
                    Circle()
                        .fill(status.color)
                        .frame(width: 12, height: 12)
                    
                    Text(status.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(tasks.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.color.opacity(0.2))
                        .foregroundColor(status.color)
                        .clipShape(Capsule())
                }
                
                Divider()
            }
            
            // Tasks
            LazyVStack(spacing: 10) {
                ForEach(tasks.sorted { $0.priority > $1.priority }) { task in
                    TaskCardView(
                        task: task,
                        onUpdate: onTaskUpdate,
                        onDelete: onTaskDelete
                    )
                    .onDrag {
                        NSItemProvider(object: TaskItemProvider(task: task))
                    }
                }
            }
            
            Spacer()
        }
        .frame(width: 300)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onDrop(of: [.text], delegate: TaskDropDelegate(onDrop: onDrop))
    }
}

struct TaskCardView: View {
    let task: Task
    let onUpdate: (Task) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editedTask: Task
    
    init(task: Task, onUpdate: @escaping (Task) -> Void, onDelete: @escaping () -> Void) {
        self.task = task
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editedTask = State(initialValue: task)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                if isEditing {
                    TextField("Title", text: $editedTask.title)
                        .textFieldStyle(.roundedBorder)
                        .font(.headline)
                } else {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                Spacer()
                
                PriorityBadge(priority: task.priority)
            }
            
            // Description
            if let description = task.description, !description.isEmpty {
                if isEditing {
                    TextField("Description", text: Binding(
                        get: { editedTask.description ?? "" },
                        set: { editedTask.description = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                } else {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // Details
            HStack {
                if let assignedTo = task.assignedTo, !assignedTo.isEmpty {
                    HStack {
                        Image(systemName: "person")
                            .font(.caption)
                        Text(assignedTo)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let deadline = task.deadline {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(deadline, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Actions
            HStack {
                if isEditing {
                    HStack {
                        Button("Save") {
                            onUpdate(editedTask)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("Cancel") {
                            editedTask = task
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
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PriorityBadge: View {
    let priority: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { index in
                Circle()
                    .fill(index <= priority ? priorityColor : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .gray
        }
    }
}

struct AddTaskView: View {
    @Binding var task: Task
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $task.title)
                    
                    Picker("Status", selection: $task.status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status.rawValue)
                        }
                    }
                    
                    Stepper("Priority: \(task.priority)", value: $task.priority, in: 1...3)
                }
                
                Section("Additional Details") {
                    TextField("Assigned To (optional)", text: Binding(
                        get: { task.assignedTo ?? "" },
                        set: { task.assignedTo = $0.isEmpty ? nil : $0 }
                    ))
                    
                    DatePicker("Deadline (optional)", selection: Binding(
                        get: { task.deadline ?? Date() },
                        set: { task.deadline = $0 }
                    ), displayedComponents: .date)
                    
                    TextField("Description (optional)", text: Binding(
                        get: { task.description ?? "" },
                        set: { task.description = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Add New Task")
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
                    .disabled(task.title.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 350)
    }
}

// MARK: - Drag and Drop Support
struct TaskItemProvider: NSItemProviderWriting {
    static let writableTypeIdentifiersForItemProvider = [UTType.text.identifier]
    
    let task: Task
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        if typeIdentifier == UTType.text.identifier {
            let taskData = try? JSONEncoder().encode(task)
            completionHandler(taskData, nil)
        } else {
            completionHandler(nil, NSError(domain: "TaskItemProvider", code: -1, userInfo: nil))
        }
        return nil
    }
}

struct TaskDropDelegate: DropDelegate {
    let onDrop: (Task) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [UTType.text]).first else { return false }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
            if let data = data as? Data,
               let task = try? JSONDecoder().decode(Task.self, from: data) {
                DispatchQueue.main.async {
                    onDrop(task)
                }
            }
        }
        
        return true
    }
}

#Preview {
    PriorityBoardView()
        .environmentObject(SupabaseManager())
}
