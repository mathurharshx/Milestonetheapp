import Foundation

public struct TodoTask: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var text: String
    public var done: Bool

    public init(id: String = UUID().uuidString, text: String, done: Bool = false) {
        self.id = id
        self.text = text
        self.done = done
    }
}

public enum MissionCategory: String, Codable, CaseIterable {
    case work = "work"
    case personal = "personal"

    public var title: String {
        switch self {
        case .work: return "WORK"
        case .personal: return "PERSONAL"
        }
    }

    public var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "leaf.fill"
        }
    }
}

public struct Mission: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var note: String?
    public var todos: [TodoTask]
    public var targetDate: Date
    public var createdAt: Date
    public var completedAt: Date?
    public var isActive: Bool
    public var category: MissionCategory

    enum CodingKeys: String, CodingKey {
        case id, title, note, todos, targetDate, createdAt, completedAt, isActive, category
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        note: String? = nil,
        todos: [TodoTask] = [],
        targetDate: Date,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        isActive: Bool = true,
        category: MissionCategory = .work
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.todos = todos
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.isActive = isActive
        self.category = category
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        todos = try container.decodeIfPresent([TodoTask].self, forKey: .todos) ?? []
        targetDate = try container.decode(Date.self, forKey: .targetDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        category = try container.decodeIfPresent(MissionCategory.self, forKey: .category) ?? .work
    }
}
