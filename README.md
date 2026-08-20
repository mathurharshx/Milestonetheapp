# Milestone (iOS)

A minimalist, high-impact native iOS productivity application designed for deep focus and milestone achievement. Built with 100% pure Swift, SwiftUI, WidgetKit, and ActivityKit.

---

## Key Features

- **Single Mission Focus:** Commitment to one active goal at a time to prevent cognitive overload.
- **Dynamic Dot Grid Matrix:** Visual progress tracking dynamically sampled across 24h, 90d, 365d, and 1095d time horizons.
- **4-Phase Pomodoro Timer:** 4-session focus cycles with an interactive 96-dot progress ring.
- **Dynamic Island & Live Activities:** Battery-efficient, Apple Clock app-style snug Dynamic Island capsule and Lock Screen timer banner with real-time countdown.
- **Apple Fitness-Style Celebration:** Cascading dot matrix wave, glowing award seal, goal stats, and seamless spatial archive transition.
- **Background Accountability Notifications:** Clean, minimal, non-intrusive notifications for focus sessions and daily morning countdowns.
- **Customizable ADHD Rhythms:** Tailored focus intervals (15m, 20m, 25m, 30m, 45m, 50m, 60m) and break lengths.
- **Native 4-Tab Navigation:** Mission, Pomodoro, Archive, and Settings.
- **System Theme Synchronization:** Automatic Light/Dark mode matching iOS with fluid switch physics.

---

## Project Structure

```text
ios/
├── Milestone.xcodeproj            # Xcode Project & Build Configurations
├── Milestone/                     # Main iOS Application
│   ├── App/                       # MilestoneApp entry point
│   ├── Models/                    # Mission, Pomodoro, Theme data models
│   ├── Stores/                    # Observable state stores (MissionStore, PomodoroStore, UserStore)
│   ├── Views/                     # SwiftUI tabs, sheets, components, and modals
│   ├── Utilities/                 # Date calculations, haptics, notification manager
│   ├── Images.xcassets/           # App icon (1024x1024) & visual assets
│   ├── Info.plist                 # App configuration & encryption exemptions
│   └── Milestone.entitlements     # App Groups entitlement
└── MilestoneWidgetExtension/      # WidgetKit & ActivityKit Extension
    ├── MilestoneMissionWidget.swift
    ├── MilestonePomodoroWidget.swift
    ├── PomodoroLiveActivi
    ty.swift # Dynamic Island & Lock Screen Live Activity
    └── Info.plist
```

---

## Building and Running

### Prerequisites
- macOS Sonoma or later
- Xcode 15.0 or later
- iOS 17.0+ deployment target

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/mathurharshx/Milestonetheapp.git
   ```
2. Open the Xcode project:
   ```bash
   open ios/Milestone.xcodeproj
   ```
3. Select the **Milestone** scheme and your target device or simulator (e.g., iPhone 17).
4. Press `Cmd + R` to build and run.

---

## App Store Submission

- **Target Version:** `1.0.0`
- **Build Number:** `1`
- **Validation:** Pre-validated for App Store submission (`-validate-for-store`).
