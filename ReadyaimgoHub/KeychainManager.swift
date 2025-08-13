import Foundation
import Security

class KeychainManager: ObservableObject {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Generic Keychain Operations
    
    func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
    
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - String Operations
    
    func saveString(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }
    
    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - API Key Management
    
    func saveSupabaseKey(_ key: String) -> Bool {
        return saveString(key: "supabase_anon_key", value: key)
    }
    
    func loadSupabaseKey() -> String? {
        return loadString(key: "supabase_anon_key")
    }
    
    func saveOpenAIKey(_ key: String) -> Bool {
        return saveString(key: "openai_api_key", value: key)
    }
    
    func loadOpenAIKey() -> String? {
        return loadString(key: "openai_api_key")
    }
    
    func saveSupabaseURL(_ url: String) -> Bool {
        return saveString(key: "supabase_url", value: url)
    }
    
    func loadSupabaseURL() -> String? {
        return loadString(key: "supabase_url")
    }
    
    // MARK: - Clear All Keys
    
    func clearAllKeys() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Key Existence Check
    
    func keyExists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
