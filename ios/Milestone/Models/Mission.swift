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

public struct Mission: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var note: String?
    public var todos: [TodoTask]
    public var targetDate: Date
    public var createdAt: Date
    public var completedAt: Date?
    public var isActive: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        note: String? = nil,
        todos: [TodoTask] = [],
        targetDate: Date,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.todos = todos
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.isActive = isActive
    }
}
