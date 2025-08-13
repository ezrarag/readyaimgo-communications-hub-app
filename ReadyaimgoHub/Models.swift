import Foundation
import SwiftUI

// MARK: - Chat Model
struct Chat: Identifiable, Codable {
    let id: UUID
    var title: String
    var categoryNumber: Int
    var status: String
    var link: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, notes, link
        case categoryNumber = "category_number"
        case status, createdAt = "created_at", updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), title: String, categoryNumber: Int, status: String = "active", link: String? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.categoryNumber = categoryNumber
        self.status = status
        self.link = link
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Communication Model
struct Communication: Identifiable, Codable {
    let id: UUID
    var audience: String
    var purpose: String
    var tone: String
    var keyPoints: [String]
    var risks: [String]
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, audience, purpose, tone
        case keyPoints = "key_points"
        case risks, createdAt = "created_at", updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), audience: String, purpose: String, tone: String, keyPoints: [String] = [], risks: [String] = []) {
        self.id = id
        self.audience = audience
        self.purpose = purpose
        self.tone = tone
        self.keyPoints = keyPoints
        self.risks = risks
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Template Model
struct Template: Identifiable, Codable {
    let id: UUID
    var category: String
    var shortVersion: String
    var longVersion: String?
    var confidentialVersion: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, category
        case shortVersion = "short_version"
        case longVersion = "long_version"
        case confidentialVersion = "confidential_version"
        case createdAt = "created_at", updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), category: String, shortVersion: String, longVersion: String? = nil, confidentialVersion: String? = nil) {
        self.id = id
        self.category = category
        self.shortVersion = shortVersion
        self.longVersion = longVersion
        self.confidentialVersion = confidentialVersion
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Narrative Model
struct Narrative: Identifiable, Codable {
    let id: UUID
    var type: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, content, createdAt = "created_at", updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), type: String, content: String) {
        self.id = id
        self.type = type
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - ProjectTask Model
struct ProjectTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var status: String
    var assignedTo: String?
    var deadline: Date?
    var description: String?
    var priority: Int
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, status, description, priority
        case assignedTo = "assigned_to"
        case deadline, createdAt = "created_at", updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), title: String, status: String = "later", assignedTo: String? = nil, deadline: Date? = nil, description: String? = nil, priority: Int = 1) {
        self.id = id
        self.title = title
        self.status = status
        self.assignedTo = assignedTo
        self.deadline = deadline
        self.description = description
        self.priority = priority
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Enums
enum TaskStatus: String, CaseIterable {
    case now = "now"
    case next = "next"
    case later = "later"
    
    var displayName: String {
        switch self {
        case .now: return "Now"
        case .next: return "Next"
        case .later: return "Later"
        }
    }
    
    var color: Color {
        switch self {
        case .now: return .red
        case .next: return .orange
        case .later: return .blue
        }
    }
}

enum TemplateCategory: String, CaseIterable {
    case clients = "Clients"
    case investors = "Investors"
    case publicAudience = "Public"
    case partners = "Partners"
    case lobbyists = "Lobbyists"
    
    var displayName: String { 
        switch self {
        case .publicAudience: return "Public"
        default: return rawValue
        }
    }
}

enum NarrativeType: String, CaseIterable {
    case mission = "mission"
    case vision = "vision"
    case originStory = "origin_story"
    case pitch = "pitch"
    
    var displayName: String {
        switch self {
        case .mission: return "Mission Statement"
        case .vision: return "Vision"
        case .originStory: return "Origin Story"
        case .pitch: return "Pitch"
        }
    }
}

// MARK: - Extensions
extension Chat {
    var statusColor: Color {
        switch status.lowercased() {
        case "active": return .green
        case "pending": return .orange
        case "completed": return .blue
        case "archived": return .gray
        default: return .primary
        }
    }
}

extension Communication {
    var toneColor: Color {
        switch tone.lowercased() {
        case "professional": return .blue
        case "casual": return .green
        case "urgent": return .red
        case "friendly": return .orange
        default: return .primary
        }
    }
}
