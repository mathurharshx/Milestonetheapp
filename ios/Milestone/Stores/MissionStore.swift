import SwiftUI
import Observation

@Observable
public final class MissionStore {
    public var activeMission: Mission? {
        didSet {
            saveActiveMission()
            syncToWidget()
            refreshMorningNotification()
        }
    }
    public var archivedMissions: [Mission] = [] {
        didSet {
            saveArchivedMissions()
        }
    }
    public var isLoading: Bool = true

    private let activeKey = "milestone:activeMission"
    private let archiveKey = "milestone:archivedMissions"

    private var encoder: JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }

    private var decoder: JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let dateStr = try? container.decode(String.self) {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let d = formatter.date(from: dateStr) { return d }
                formatter.formatOptions = [.withInternetDateTime]
                if let d = formatter.date(from: dateStr) { return d }
            }
            if let ts = try? container.decode(Double.self) {
                return ts > 100_000_000_000 ? Date(timeIntervalSince1970: ts / 1000) : Date(timeIntervalSince1970: ts)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        return dec
    }

    public init() {
        loadData()
    }

    public func loadData() {
        isLoading = true
        defer { isLoading = false }

        if let activeData = UserDefaults.standard.data(forKey: activeKey),
           let mission = try? decoder.decode(Mission.self, from: activeData) {
            self.activeMission = mission
        } else {
            self.activeMission = nil
        }

        if let archiveData = UserDefaults.standard.data(forKey: archiveKey),
           let missions = try? decoder.decode([Mission].self, from: archiveData) {
            self.archivedMissions = missions
        } else {
            self.archivedMissions = []
        }

        syncToWidget()
        refreshMorningNotification()
    }

    public func createMission(title: String, targetDate: Date, note: String? = nil, todos: [TodoTask] = []) {
        let newMission = Mission(
            id: "\(Int(Date().timeIntervalSince1970 * 1000))",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            todos: todos,
            targetDate: targetDate,
            createdAt: Date(),
            isActive: true
        )
        self.activeMission = newMission
    }

    public func completeMission() {
        guard var mission = activeMission else { return }
        mission.completedAt = Date()
        mission.isActive = false
        self.activeMission = mission
    }

    public func archiveMission() {
        guard let mission = activeMission else { return }
        var completed = mission
        completed.completedAt = mission.completedAt ?? Date()
        completed.isActive = false

        self.archivedMissions.insert(completed, at: 0)
        self.activeMission = nil
    }

    public func toggleTodo(id: String) {
        guard var mission = activeMission else { return }
        if let index = mission.todos.firstIndex(where: { $0.id == id }) {
            mission.todos[index].done.toggle()
            self.activeMission = mission
        }
    }

    public func addTodo(text: String) {
        guard var mission = activeMission else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newTodo = TodoTask(
            id: "\(Int(Date().timeIntervalSince1970 * 1000))",
            text: trimmed,
            done: false
        )
        mission.todos.append(newTodo)
        self.activeMission = mission
    }

    public func deleteArchived(ids: Set<String>) {
        self.archivedMissions.removeAll(where: { ids.contains($0.id) })
    }

    private func saveActiveMission() {
        if let mission = activeMission {
            if let encoded = try? encoder.encode(mission) {
                UserDefaults.standard.set(encoded, forKey: activeKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: activeKey)
        }
    }

    private func saveArchivedMissions() {
        if let encoded = try? encoder.encode(archivedMissions) {
            UserDefaults.standard.set(encoded, forKey: archiveKey)
        }
    }

    public func refreshMorningNotification() {
        let isEnabled = UserDefaults.standard.object(forKey: "milestone:morningReminderEnabled") as? Bool ?? true
        let hour = UserDefaults.standard.object(forKey: "milestone:morningReminderHour") as? Int ?? 9
        let min = UserDefaults.standard.object(forKey: "milestone:morningReminderMinute") as? Int ?? 0

        Task { @MainActor in
            if isEnabled, let mission = activeMission {
                NotificationManager.shared.scheduleDailyMorningReminder(mission: mission, hour: hour, minute: min)
            } else {
                NotificationManager.shared.cancelDailyMorningReminder()
            }
        }
    }

    public func syncToWidget() {
        let existing = SharedWidgetStore.load() ?? MilestoneWidgetData()

        let totalTodos = activeMission?.todos.count ?? 0
        let doneTodos = activeMission?.todos.filter(\.done).count ?? 0

        let updated = MilestoneWidgetData(
            pomodoroPhase: existing.pomodoroPhase,
            pomodoroTimeRemaining: existing.pomodoroTimeRemaining,
            pomodoroTotalTime: existing.pomodoroTotalTime,
            pomodoroIsRunning: existing.pomodoroIsRunning,
            pomodoroSession: existing.pomodoroSession,
            pomodoroTotalSessions: existing.pomodoroTotalSessions,
            missionTitle: activeMission?.title,
            missionTargetDate: activeMission?.targetDate.timeIntervalSince1970,
            missionCreatedAt: activeMission?.createdAt.timeIntervalSince1970,
            missionTodosTotal: totalTodos,
            missionTodosDone: doneTodos,
            lastUpdated: Date().timeIntervalSince1970
        )
        SharedWidgetStore.save(updated)
    }
}
