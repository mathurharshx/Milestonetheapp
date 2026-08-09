import ExpoModulesCore
import WidgetKit

/// Native Expo module that bridges React Native ↔ WidgetKit shared storage.
/// Uses UserDefaults with a shared App Group suite so both the main app
/// and the widget extension can read/write the same data.
public class WidgetBridgeModule: Module {
  private static let suiteName = "group.com.mathurharsh.milestone"

  public func definition() -> ModuleDefinition {
    Name("WidgetBridge")

    /// Write a string value to shared UserDefaults
    Function("setSharedData") { (key: String, value: String) in
      guard let defaults = UserDefaults(suiteName: WidgetBridgeModule.suiteName) else {
        return
      }
      defaults.set(value, forKey: key)
      defaults.synchronize()
    }

    /// Read a string value from shared UserDefaults
    Function("getSharedData") { (key: String) -> String? in
      guard let defaults = UserDefaults(suiteName: WidgetBridgeModule.suiteName) else {
        return nil
      }
      return defaults.string(forKey: key)
    }

    /// Reload all widget timelines so they pick up fresh data
    Function("reloadWidget") {
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }
}
