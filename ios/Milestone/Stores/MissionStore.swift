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
    public var vaultMissions: [Mission] = [] {
        didSet {
            saveVaultMissions()
        }
    }
    public var isLoading: Bool = true

    private let activeKey = "milestone:activeMission"
    private let archiveKey = "milestone:archivedMissions"
    private let vaultKey = "milestone:vaultMissions"

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

        if let vaultData = UserDefaults.standard.data(forKey: vaultKey),
           let missions = try? decoder.decode([Mission].self, from: vaultData) {
            self.vaultMissions = missions
        } else {
            self.vaultMissions = []
        }

        syncToWidget()
        refreshMissionNotifications()
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

    public func deleteTodo(id: String) {
        guard var mission = activeMission else { return }
        mission.todos.removeAll(where: { $0.id == id })
        self.activeMission = mission
    }

    public func moveTodo(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard var mission = activeMission else { return }
        mission.todos.move(fromOffsets: source, toOffset: destination)
        self.activeMission = mission
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
        refreshMissionNotifications()
    }

    public func refreshMissionNotifications() {
        let isEnabled = UserDefaults.standard.object(forKey: "milestone:morningReminderEnabled") as? Bool ?? true
        let hour = UserDefaults.standard.object(forKey: "milestone:morningReminderHour") as? Int ?? 9
        let min = UserDefaults.standard.object(forKey: "milestone:morningReminderMinute") as? Int ?? 0

        Task { @MainActor in
            if let mission = activeMission, mission.isActive {
                // 1. Daily morning accountability reminder
                if isEnabled {
                    NotificationManager.shared.scheduleDailyMorningReminder(mission: mission, hour: hour, minute: min)
                } else {
                    NotificationManager.shared.cancelDailyMorningReminder()
                }

                // 2. Exact mission target deadline reached alert
                NotificationManager.shared.scheduleMissionDeadlineNotification(mission: mission)
            } else {
                NotificationManager.shared.cancelDailyMorningReminder()
                NotificationManager.shared.cancelMissionDeadlineNotification()
            }
        }
    }

    public func syncToWidget() {
        let existing = SharedWidgetStore.load() ?? MilestoneWidgetData()

        let totalTodos = activeMission?.todos.count ?? 0
        let doneTodos = activeMission?.todos.filter(\.done).count ?? 0
        let topTask = activeMission?.todos.first(where: { !$0.done })?.text

        let updated = MilestoneWidgetData(
            isDarkMode: existing.isDarkMode,
            pomodoroPhase: existing.pomodoroPhase,
            pomodoroTimeRemaining: existing.pomodoroTimeRemaining,
            pomodoroTotalTime: existing.pomodoroTotalTime,
            pomodoroIsRunning: existing.pomodoroIsRunning,
            pomodoroSession: existing.pomodoroSession,
            pomodoroTotalSessions: existing.pomodoroTotalSessions,
            pomodoroTargetEndTime: existing.pomodoroTargetEndTime,
            missionTitle: activeMission?.title,
            missionTargetDate: activeMission?.targetDate.timeIntervalSince1970,
            missionCreatedAt: activeMission?.createdAt.timeIntervalSince1970,
            missionTodosTotal: totalTodos,
            missionTodosDone: doneTodos,
            topPendingTaskText: topTask,
            focusStreak: existing.focusStreak,
            todayFocusMinutes: existing.todayFocusMinutes,
            weeklyFocusLevels: existing.weeklyFocusLevels,
            quoteText: existing.quoteText,
            quoteAuthor: existing.quoteAuthor,
            lastUpdated: Date().timeIntervalSince1970
        )
        SharedWidgetStore.save(updated)
        SharedWidgetStore.reloadWidgetTimelines()
    }

    // ── MISSION VAULT ──
    public func addToVault(title: String, targetDate: Date, note: String? = nil, todos: [TodoTask] = []) {
        let mission = Mission(
            id: "\(Int(Date().timeIntervalSince1970 * 1000))",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            todos: todos,
            targetDate: targetDate,
            createdAt: Date(),
            isActive: false
        )
        self.vaultMissions.insert(mission, at: 0)
    }

    public func deleteFromVault(id: String) {
        self.vaultMissions.removeAll(where: { $0.id == id })
    }

    public func promoteToActiveMission(vaultMissionId: String) {
        guard let index = vaultMissions.firstIndex(where: { $0.id == vaultMissionId }) else { return }
        var mission = vaultMissions.remove(at: index)
        mission.isActive = true
        self.activeMission = mission
    }

    private func saveVaultMissions() {
        if let data = try? encoder.encode(vaultMissions) {
            UserDefaults.standard.set(data, forKey: vaultKey)
        }
    }
}
