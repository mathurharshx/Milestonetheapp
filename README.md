# Milestone (iOS)

A minimalist, high-impact native iOS productivity application designed for deep focus and milestone achievement. Built with 100% pure Swift, SwiftUI, WidgetKit, and ActivityKit.

---

## Key Features

- **Single Mission Focus & Dual Pillars:** Commitment to an active goal at a time with optional Work & Personal dual-track balance.
- **Dedicated Tasks Runway:** Scheduled daily tasks, milestone deliverables, and consistency tracking ribbon.
- **Dynamic Dot Grid Matrix:** Visual progress tracking dynamically sampled across 24h, 90d, 365d, and 1095d time horizons.
- **4-Phase Pomodoro Timer:** 4-session focus cycles with an interactive 96-dot progress ring.
- **Dynamic Island & Live Activities:** Battery-efficient Dynamic Island capsule and Lock Screen timer banner with real-time countdown.
- **Apple Fitness-Style Celebration:** Cascading dot matrix wave, glowing award seal, goal stats, and seamless spatial archive transition.
- **ADHD Procedural Soundscapes:** Real-time on-device synthesis of 40Hz Gamma neural entrainment and Brown Noise.
- **Background Accountability Notifications:** Clean, minimal, non-intrusive notifications for focus sessions, daily reminders, and deadline alerts.
- **Native 5-Tab Navigation:** Pomodoro, Tasks, Mission, Archive, and Settings.
- **Brutalist Luxury Aesthetic:** Pitch-black OLED theme with titanium white and alpine sage emerald accents.

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
