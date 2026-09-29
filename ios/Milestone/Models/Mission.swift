import Foundation

public enum TaskType: String, Codable, CaseIterable {
    case daily = "daily"
    case milestone = "milestone"
}

public struct TodoTask: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var text: String
    public var done: Bool
    public var type: TaskType
    public var lastCompletedDate: Date?
    public var streakCount: Int

    public var reminderHour: Int?
    public var reminderMinute: Int?

    public init(
        id: String = UUID().uuidString,
        text: String,
        done: Bool = false,
        type: TaskType = .milestone,
        lastCompletedDate: Date? = nil,
        streakCount: Int = 0,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.id = id
        self.text = text
        self.done = done
        self.type = type
        self.lastCompletedDate = lastCompletedDate
        self.streakCount = streakCount
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    public var isCompletedToday: Bool {
        guard type == .daily else { return done }
        guard let lastDate = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    public var formattedReminderTime: String? {
        guard let hour = reminderHour, let minute = reminderMinute else { return nil }
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        guard let date = Calendar.current.date(from: comps) else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    enum CodingKeys: String, CodingKey {
        case id, text, done, type, lastCompletedDate, streakCount, reminderHour, reminderMinute
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        done = try container.decode(Bool.self, forKey: .done)
        type = try container.decodeIfPresent(TaskType.self, forKey: .type) ?? .milestone
        lastCompletedDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletedDate)
        streakCount = try container.decodeIfPresent(Int.self, forKey: .streakCount) ?? 0
        reminderHour = try container.decodeIfPresent(Int.self, forKey: .reminderHour)
        reminderMinute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute)
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

// ── Mission Launch Coordinator: High-Fidelity Hand-Off Between Creation & Home Screen ──
@Observable
public final class MissionLaunchCoordinator {
    public static let shared = MissionLaunchCoordinator()

    public var isIgniting: Bool = false
    public var lastForgedCategory: MissionCategory = .work
    public var ignitionToken: UUID = UUID()

    private init() {}

    @MainActor
    public func triggerLaunch(category: MissionCategory) {
        self.lastForgedCategory = category
        self.ignitionToken = UUID()
        self.isIgniting = true

        // Complete ignition after cascade settles
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
            self.isIgniting = false
        }
    }
}

