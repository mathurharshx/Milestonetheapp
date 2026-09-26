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
    public var activePersonalMission: Mission? {
        didSet {
            saveActivePersonalMission()
            syncToWidget()
        }
    }
    public var activePillar: MissionCategory = .work {
        didSet {
            UserDefaults.standard.set(activePillar.rawValue, forKey: activePillarKey)
            syncToWidget()
        }
    }

    public var currentPillarMission: Mission? {
        get {
            switch activePillar {
            case .work: return activeMission
            case .personal: return activePersonalMission
            }
        }
        set {
            switch activePillar {
            case .work: activeMission = newValue
            case .personal: activePersonalMission = newValue
            }
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
    private let activePersonalKey = "milestone:activePersonalMission"
    private let activePillarKey = "milestone:activePillar"
    private let archiveKey = "milestone:archivedMissions"
    private let vaultKey = "milestone:vaultMissions"
    private let hasInitializedFirstMissionKey = "milestone:hasInitializedFirstMission"

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

        let pillarRaw = UserDefaults.standard.string(forKey: activePillarKey) ?? "work"
        self.activePillar = MissionCategory(rawValue: pillarRaw) ?? .work

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

        if let activeData = UserDefaults.standard.data(forKey: activeKey),
           let mission = try? decoder.decode(Mission.self, from: activeData) {
            self.activeMission = mission
        } else {
            self.activeMission = nil
        }

        if let personalData = UserDefaults.standard.data(forKey: activePersonalKey),
           let mission = try? decoder.decode(Mission.self, from: personalData) {
            self.activePersonalMission = mission
        } else {
            self.activePersonalMission = nil
        }

        syncToWidget()
        refreshMissionNotifications()
    }

    public func switchPillar(to category: MissionCategory) {
        self.activePillar = category
        syncToWidget()
    }

    public func createMission(
        title: String,
        targetDate: Date,
        note: String? = nil,
        todos: [TodoTask] = [],
        category: MissionCategory? = nil
    ) {
        let cat = category ?? activePillar
        let newMission = Mission(
            id: "\(Int(Date().timeIntervalSince1970 * 1000))",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            todos: todos,
            targetDate: targetDate,
            createdAt: Date(),
            isActive: true,
            category: cat
        )
        if cat == .personal {
            self.activePersonalMission = newMission
        } else {
            self.activeMission = newMission
        }
    }

    public func completeMission() {
        guard var mission = currentPillarMission else { return }
        mission.completedAt = Date()
        mission.isActive = false
        self.currentPillarMission = mission
    }

    public func archiveMission(_ missionToArchive: Mission? = nil) {
        guard let mission = missionToArchive ?? currentPillarMission else { return }
        UserDefaults.standard.set(true, forKey: hasInitializedFirstMissionKey)
        var completed = mission
        completed.completedAt = mission.completedAt ?? Date()
        completed.isActive = false

        self.archivedMissions.removeAll(where: { $0.id == completed.id })
        self.archivedMissions.insert(completed, at: 0)

        if completed.id == activeMission?.id || activePillar == .work || mission.category == .work {
            self.activeMission = nil
            UserDefaults.standard.removeObject(forKey: activeKey)
        }
        if completed.id == activePersonalMission?.id || activePillar == .personal || mission.category == .personal {
            self.activePersonalMission = nil
            UserDefaults.standard.removeObject(forKey: activePersonalKey)
        }
        self.currentPillarMission = nil

        UserDefaults.standard.synchronize()
        syncToWidget()
        refreshMissionNotifications()
    }

    public func toggleTodo(id: String) {
        guard var mission = currentPillarMission else { return }
        if let index = mission.todos.firstIndex(where: { $0.id == id }) {
            mission.todos[index].done.toggle()
            self.currentPillarMission = mission
        }
    }

    public func deleteTodo(id: String) {
        guard var mission = currentPillarMission else { return }
        mission.todos.removeAll(where: { $0.id == id })
        self.currentPillarMission = mission
    }

    public func moveTodo(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard var mission = currentPillarMission else { return }
        mission.todos.move(fromOffsets: source, toOffset: destination)
        self.currentPillarMission = mission
    }

    public func addTodo(text: String) {
        guard var mission = currentPillarMission else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newTodo = TodoTask(
            id: "\(Int(Date().timeIntervalSince1970 * 1000))",
            text: trimmed,
            done: false
        )
        mission.todos.append(newTodo)
        self.currentPillarMission = mission
    }

    public func deleteArchived(ids: Set<String>) {
        self.archivedMissions.removeAll(where: { ids.contains($0.id) })
    }

    #if DEBUG
    // ── Apply Simulator Mission Test Preset ──
    public func applyTestPreset(_ preset: MissionTestPreset) {
        let now = Date()
        let createdAt: Date
        let targetDate: Date

        switch preset {
        case .standard90Days:
            // 90 days total: 5 days passed, 85 days remaining
            createdAt = Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now
            targetDate = Calendar.current.date(byAdding: .day, value: 85, to: now) ?? now

        case .halfWay30Days:
            // 30 days total: 15 days passed, 15 days remaining
            createdAt = Calendar.current.date(byAdding: .day, value: -15, to: now) ?? now
            targetDate = Calendar.current.date(byAdding: .day, value: 15, to: now) ?? now

        case .finalStretch3Days:
            // 30 days total: 27 days passed, 3 days remaining
            createdAt = Calendar.current.date(byAdding: .day, value: -27, to: now) ?? now
            targetDate = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now

        case .hourly48h:
            // 48 hours total: 12 hours passed, 36 hours remaining (< 48h runway track)
            createdAt = now.addingTimeInterval(-12 * 3600)
            targetDate = now.addingTimeInterval(36 * 3600)

        case .urgent24h:
            // 24 hours total: 6 hours passed, 18 hours remaining (< 24h urgent track)
            createdAt = now.addingTimeInterval(-6 * 3600)
            targetDate = now.addingTimeInterval(18 * 3600)

        case .completingNow:
            // 15 seconds remaining: immediate test of completion wave & celebration
            createdAt = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            targetDate = now.addingTimeInterval(15)
        }

        if var mission = activeMission {
            mission.createdAt = createdAt
            mission.targetDate = targetDate
            mission.isActive = true
            self.activeMission = mission
        } else {
            self.activeMission = Mission(
                id: "work_test_mission",
                title: "Launch Milestone v1.0",
                todos: [
                    TodoTask(id: "1", text: "Submit App Store Metadata & Screenshots", done: false),
                    TodoTask(id: "2", text: "Invite TestFlight Beta Testers", done: false),
                    TodoTask(id: "3", text: "Publish Launch Announcement", done: false)
                ],
                targetDate: targetDate,
                createdAt: createdAt,
                isActive: true,
                category: .work
            )
        }

        // Also seed activePersonalMission so Dual Pillar Large Widget has rich live data to test
        let pCreated = Calendar.current.date(byAdding: .day, value: -10, to: now) ?? now
        let pTarget = Calendar.current.date(byAdding: .day, value: 20, to: now) ?? now
        self.activePersonalMission = Mission(
            id: "personal_test_mission",
            title: "Half Marathon 2026",
            todos: [
                TodoTask(id: "p1", text: "Morning 10km Endurance Run", done: true),
                TodoTask(id: "p2", text: "Electrolyte Recovery & Mobility", done: false)
            ],
            targetDate: pTarget,
            createdAt: pCreated,
            isActive: true,
            category: .personal
        )

        syncToWidget()
    }
    #endif

    private func saveActiveMission() {
        if let mission = activeMission {
            if let encoded = try? encoder.encode(mission) {
                UserDefaults.standard.set(encoded, forKey: activeKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: activeKey)
        }
        UserDefaults.standard.synchronize()
    }

    private func saveActivePersonalMission() {
        if let mission = activePersonalMission {
            if let encoded = try? encoder.encode(mission) {
                UserDefaults.standard.set(encoded, forKey: activePersonalKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: activePersonalKey)
        }
        UserDefaults.standard.synchronize()
    }

    private func saveArchivedMissions() {
        if let encoded = try? encoder.encode(archivedMissions) {
            UserDefaults.standard.set(encoded, forKey: archiveKey)
        }
        UserDefaults.standard.synchronize()
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

        let current = currentPillarMission ?? activeMission
        let totalTodos = current?.todos.count ?? 0
        let doneTodos = current?.todos.filter(\.done).count ?? 0
        let topTask = current?.todos.first(where: { !$0.done })

        // Construct dedicated payloads for Work & Personal
        let workPayload: MissionWidgetPayload? = activeMission.map { m in
            MissionWidgetPayload(
                title: m.title,
                targetDate: m.targetDate.timeIntervalSince1970,
                createdAt: m.createdAt.timeIntervalSince1970,
                category: "work",
                todosTotal: m.todos.count,
                todosDone: m.todos.filter(\.done).count,
                topPendingTaskText: m.todos.first(where: { !$0.done })?.text,
                topPendingTaskId: m.todos.first(where: { !$0.done })?.id
            )
        }

        let personalPayload: MissionWidgetPayload? = activePersonalMission.map { m in
            MissionWidgetPayload(
                title: m.title,
                targetDate: m.targetDate.timeIntervalSince1970,
                createdAt: m.createdAt.timeIntervalSince1970,
                category: "personal",
                todosTotal: m.todos.count,
                todosDone: m.todos.filter(\.done).count,
                topPendingTaskText: m.todos.first(where: { !$0.done })?.text,
                topPendingTaskId: m.todos.first(where: { !$0.done })?.id
            )
        }

        let isPro = UserDefaults.standard.bool(forKey: "milestone:isProUser")

        let updated = MilestoneWidgetData(
            isDarkMode: existing.isDarkMode,
            isProUser: isPro,
            pomodoroPhase: existing.pomodoroPhase,
            pomodoroTimeRemaining: existing.pomodoroTimeRemaining,
            pomodoroTotalTime: existing.pomodoroTotalTime,
            pomodoroIsRunning: existing.pomodoroIsRunning,
            pomodoroSession: existing.pomodoroSession,
            pomodoroTotalSessions: existing.pomodoroTotalSessions,
            pomodoroTargetEndTime: existing.pomodoroTargetEndTime,
            missionTitle: current?.title,
            missionTargetDate: current?.targetDate.timeIntervalSince1970,
            missionCreatedAt: current?.createdAt.timeIntervalSince1970,
            missionCategory: current?.category.rawValue ?? "work",
            missionTodosTotal: totalTodos,
            missionTodosDone: doneTodos,
            topPendingTaskText: topTask?.text,
            topPendingTaskId: topTask?.id,
            workMissionPayload: workPayload,
            personalMissionPayload: personalPayload,
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
    public func addToVault(title: String, targetDate: Date, note: String? = nil, todos: [TodoTask] = [], category: MissionCategory? = nil) {
        let cat = category ?? activePillar
        let mission = Mission(
            id: "\(Int(Date().timeIntervalSince1970 * 1000))",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            todos: todos,
            targetDate: targetDate,
            createdAt: Date(),
            isActive: false,
            category: cat
        )
        self.vaultMissions.insert(mission, at: 0)
    }

    public func deleteFromVault(id: String) {
        self.vaultMissions.removeAll(where: { $0.id == id })
    }

    public func updateVaultMissionTargetDate(id: String, targetDate: Date) {
        if let index = vaultMissions.firstIndex(where: { $0.id == id }) {
            vaultMissions[index].targetDate = targetDate
        }
    }

    public func activeMission(for category: MissionCategory) -> Mission? {
        switch category {
        case .work: return activeMission
        case .personal: return activePersonalMission
        }
    }

    public func promoteToActiveMission(vaultMissionId: String) {
        guard let index = vaultMissions.firstIndex(where: { $0.id == vaultMissionId }) else { return }
        var mission = vaultMissions.remove(at: index)
        mission.isActive = true
        if mission.category == .personal {
            self.activePersonalMission = mission
            self.activePillar = .personal
        } else {
            self.activeMission = mission
            self.activePillar = .work
        }
        syncToWidget()
        refreshMissionNotifications()
    }

    public func swapVaultMissionWithActive(vaultMissionId: String) {
        guard let index = vaultMissions.firstIndex(where: { $0.id == vaultMissionId }) else { return }
        var newMission = vaultMissions.remove(at: index)
        newMission.isActive = true

        if newMission.category == .personal {
            if var current = activePersonalMission {
                current.isActive = false
                vaultMissions.insert(current, at: 0)
            }
            self.activePersonalMission = newMission
            self.activePillar = .personal
        } else {
            if var current = activeMission {
                current.isActive = false
                vaultMissions.insert(current, at: 0)
            }
            self.activeMission = newMission
            self.activePillar = .work
        }
        syncToWidget()
        refreshMissionNotifications()
    }

    public func completeCurrentAndActivateVault(vaultMissionId: String) {
        guard let index = vaultMissions.firstIndex(where: { $0.id == vaultMissionId }) else { return }
        var newMission = vaultMissions.remove(at: index)
        newMission.isActive = true

        if newMission.category == .personal {
            if let current = activePersonalMission {
                archiveMission(current)
            }
            self.activePersonalMission = newMission
            self.activePillar = .personal
        } else {
            if let current = activeMission {
                archiveMission(current)
            }
            self.activeMission = newMission
            self.activePillar = .work
        }
        syncToWidget()
        refreshMissionNotifications()
    }

    private func saveVaultMissions() {
        if let data = try? encoder.encode(vaultMissions) {
            UserDefaults.standard.set(data, forKey: vaultKey)
        }
        UserDefaults.standard.synchronize()
    }
}
