import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: String = ""
    @Published var showAuthView = false
    
    init() {
        // Check if user is already authenticated
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        // For demo purposes, we'll use a simple check
        // In production, this would check with Supabase
        if let user = UserDefaults.standard.string(forKey: "current_user"), !user.isEmpty {
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            self.showAuthView = true
        }
    }
    
    func signIn(email: String, password: String) {
        // Simulate authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentUser = email
            self.isAuthenticated = true
            self.showAuthView = false
            UserDefaults.standard.set(email, forKey: "current_user")
        }
    }
    
    func signUp(email: String, password: String) {
        // Simulate registration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentUser = email
            self.isAuthenticated = true
            self.showAuthView = false
            UserDefaults.standard.set(email, forKey: "current_user")
        }
    }
    
    func signOut() {
        self.currentUser = ""
        self.isAuthenticated = false
        self.showAuthView = true
        UserDefaults.standard.removeObject(forKey: "current_user")
    }
}
