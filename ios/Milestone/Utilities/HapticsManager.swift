import UIKit

public final class HapticsManager {
    public static let shared = HapticsManager()

    public var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "milestone:haptics") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "milestone:haptics")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "milestone:haptics")
        }
    }

    private init() {}

    public func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    public func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
