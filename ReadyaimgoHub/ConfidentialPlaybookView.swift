import SwiftUI

struct ConfidentialPlaybookView: View {
    @State private var isUnlocked = false
    @State private var password = ""
    @State private var showPasswordError = false
    @State private var notes = ""
    @State private var isEditing = false
    @State private var editedNotes = ""
    
    // In a real app, this would be stored securely in Keychain
    private let correctPassword = "readyaimgo2024"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Confidential Playbook")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Secure strategy notes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isUnlocked {
                    Button(action: { isEditing.toggle() }) {
                        Label(isEditing ? "Cancel" : "Edit", systemImage: isEditing ? "xmark" : "pencil")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            
            if !isUnlocked {
                // Password Protection Screen
                VStack(spacing: 30) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                    
                    VStack(spacing: 15) {
                        Text("Access Restricted")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This section contains confidential strategic information. Please enter the password to continue.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 15) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                            .onSubmit {
                                checkPassword()
                            }
                        
                        if showPasswordError {
                            Text("Incorrect password. Please try again.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Button("Unlock") {
                            checkPassword()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(password.isEmpty)
                    }
                    
                    Spacer()
                }
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Content Area
                VStack(spacing: 20) {
                    if isEditing {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Strategic Notes")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextEditor(text: $editedNotes)
                                .font(.body)
                                .frame(minHeight: 400)
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        HStack {
                            Button("Save") {
                                notes = editedNotes
                                isEditing = false
                                saveNotes()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Cancel") {
                                editedNotes = notes
                                isEditing = false
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Strategic Notes")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("Lock") {
                                    lockPlaybook()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                            
                            if notes.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No notes yet")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Add your confidential strategic notes to get started")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, minHeight: 400)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(12)
                            } else {
                                ScrollView {
                                    Text(notes)
                                        .font(.body)
                                        .multilineTextAlignment(.leading)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                }
                                .frame(maxHeight: 400)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            loadNotes()
        }
    }
    
    private func checkPassword() {
        if password == correctPassword {
            isUnlocked = true
            showPasswordError = false
            password = ""
        } else {
            showPasswordError = true
            password = ""
        }
    }
    
    private func lockPlaybook() {
        isUnlocked = false
        isEditing = false
        editedNotes = notes
    }
    
    private func loadNotes() {
        // In a real app, this would load from secure storage
        if let savedNotes = UserDefaults.standard.string(forKey: "confidential_notes") {
            notes = savedNotes
            editedNotes = savedNotes
        }
    }
    
    private func saveNotes() {
        // In a real app, this would save to secure storage
        UserDefaults.standard.set(notes, forKey: "confidential_notes")
    }
}

// MARK: - Secure Storage Manager (for future implementation)
class SecureStorageManager {
    static let shared = SecureStorageManager()
    
    private init() {}
    
    func storeSecureNote(_ note: String, forKey key: String) {
        // Implementation would use Keychain or other secure storage
        // For now, we'll use UserDefaults as a placeholder
        UserDefaults.standard.set(note, forKey: key)
    }
    
    func retrieveSecureNote(forKey key: String) -> String? {
        // Implementation would use Keychain or other secure storage
        // For now, we'll use UserDefaults as a placeholder
        return UserDefaults.standard.string(forKey: key)
    }
    
    func deleteSecureNote(forKey key: String) {
        // Implementation would use Keychain or other secure storage
        // For now, we'll use UserDefaults as a placeholder
        UserDefaults.standard.removeObject(forKey: key)
    }
}

#Preview {
    ConfidentialPlaybookView()
}
