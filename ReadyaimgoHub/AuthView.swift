import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "hub.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Readyaimgo Hub")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Strategic Communications Command Center")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Auth Form
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button(action: performAuth) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 300)
            
            // Features Preview
            VStack(spacing: 20) {
                Text("Everything you need for strategic communications")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    FeatureCard(
                        icon: "list.bullet",
                        title: "Master Index",
                        description: "Track all project chats and communications"
                    )
                    
                    FeatureCard(
                        icon: "tablecells",
                        title: "Communication Matrix",
                        description: "Strategic messaging framework"
                    )
                    
                    FeatureCard(
                        icon: "doc.text",
                        title: "Template Library",
                        description: "Reusable message templates"
                    )
                    
                    FeatureCard(
                        icon: "kanban",
                        title: "Priority Board",
                        description: "Visual task management"
                    )
                    
                    FeatureCard(
                        icon: "book",
                        title: "Narrative Library",
                        description: "Core messaging consistency"
                    )
                    
                    FeatureCard(
                        icon: "lock.shield",
                        title: "Confidential Playbook",
                        description: "Secure strategy notes"
                    )
                }
            }
            .padding(.top, 40)
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    private func performAuth() {
        isLoading = true
        
        if isSignUp {
            authManager.signUp(email: email, password: password)
        } else {
            authManager.signIn(email: email, password: password)
        }
        
        // Reset form after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            email = ""
            password = ""
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
