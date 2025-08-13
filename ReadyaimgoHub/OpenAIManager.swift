import Foundation
import SwiftUI

// MARK: - Placeholder Types
struct OpenAIRequest: Codable {
    let model: String
    let messages: [[String: String]]
    let maxTokens: Int
    let temperature: Double
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

enum OpenAIError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
}

class OpenAIManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastResponse: String = ""
    
    // Configuration
    @AppStorage("openai_api_key") var apiKey: String = ""
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // Load API key from UserDefaults for now
        if let key = UserDefaults.standard.string(forKey: "openai_api_key") {
            apiKey = key
        }
    }
    
    func saveConfiguration() {
        // Save API key to UserDefaults for now
        if !apiKey.isEmpty {
            UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
        }
    }
    
    // MARK: - ChatGPT API Calls
    func sendMessage(_ message: String, systemPrompt: String? = nil) async -> String? {
        guard !apiKey.isEmpty else {
            await MainActor.run {
                errorMessage = "OpenAI API key not configured"
            }
            return nil
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await makeAPICall(message: message, systemPrompt: systemPrompt)
            
            await MainActor.run {
                self.lastResponse = response
                self.isLoading = false
            }
            
            return response
        } catch {
            await MainActor.run {
                self.errorMessage = "API Error: \(error.localizedDescription)"
                self.isLoading = false
            }
            return nil
        }
    }
    
    private func makeAPICall(message: String, systemPrompt: String?) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var messages: [[String: String]] = []
        
        if let systemPrompt = systemPrompt {
            messages.append(["role": "system", "content": systemPrompt])
        }
        
        messages.append(["role": "user", "content": message])
        
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: messages,
            maxTokens: 1000,
            temperature: 0.7
        )
        
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }
        
        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return openAIResponse.choices.first?.message.content ?? "No response content"
        } catch {
            throw OpenAIError.decodingError
        }
    }
    
    // MARK: - Helper Methods
    func generateCommunicationDraft(audience: String, purpose: String, tone: String, keyPoints: String) async -> String? {
        let prompt = """
        Create a professional communication draft for:
        Audience: \(audience)
        Purpose: \(purpose)
        Tone: \(tone)
        Key Points: \(keyPoints)
        
        Please provide a clear, concise message that aligns with these parameters.
        """
        
        return await sendMessage(prompt, systemPrompt: "You are a professional communications expert. Create clear, effective messaging.")
    }
    
    func generateTemplateVariation(template: String, audience: String, tone: String) async -> String? {
        let prompt = """
        Adapt this template for a new audience and tone:
        
        Original Template:
        \(template)
        
        New Audience: \(audience)
        New Tone: \(tone)
        
        Please provide an adapted version that maintains the core message while fitting the new context.
        """
        
        return await sendMessage(prompt, systemPrompt: "You are a professional communications expert. Adapt messaging for different audiences and tones.")
    }
    
    func generateNarrativeContent(type: String, context: String) async -> String? {
        let prompt = """
        Create \(type) content for:
        Context: \(context)
        
        Please provide compelling, authentic content that aligns with the specified type and context.
        """
        
        return await sendMessage(prompt, systemPrompt: "You are a professional communications expert. Create authentic, compelling narrative content.")
    }
    
    func analyzeCommunicationEffectiveness(message: String, audience: String) async -> String? {
        let prompt = """
        Analyze the effectiveness of this communication:
        
        Message: \(message)
        Target Audience: \(audience)
        
        Please provide feedback on clarity, tone, messaging effectiveness, and suggestions for improvement.
        """
        
        return await sendMessage(prompt, systemPrompt: "You are a professional communications expert. Analyze messaging effectiveness and provide constructive feedback.")
    }
    
    func analyzeCommunication(communication: Communication) async -> String? {
        // Mock implementation - would typically call OpenAI API
        return "This is a mock analysis of the communication. In production, this would analyze the content using OpenAI's API."
    }
    
    func generateTemplate(purpose: String, audience: String, tone: String) async -> String? {
        // Mock implementation - would typically call OpenAI API
        return """
        Here's a mock template for \(purpose) targeting \(audience) with a \(tone) tone:
        
        Dear [Recipient],
        
        I hope this message finds you well. I'm reaching out regarding [specific purpose].
        
        [Main content would be generated here based on the purpose, audience, and tone parameters]
        
        Thank you for your time and consideration.
        
        Best regards,
        [Your Name]
        """
    }
}
