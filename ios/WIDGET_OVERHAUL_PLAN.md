# Milestone Widget Suite Overhaul & Aesthetic Refinement Plan

**Date:** September 27, 2026  
**Status:** Ready for Review  
**Target:** iOS 17.0+ / iOS 18  

---

## 1. Executive Summary of Changes

Based on your exact voice requirements, we are overhauling the widget suite to make it ultra-minimalist, remove clutter and duplicate widgets, fix all text truncations, and introduce a flagship full-screen/large aesthetic dot matrix.

---

## 2. Widget-by-Widget Specification

### **Widget 1: "Dot Matrix" (Clean Active Milestone Countdown)**
- **Small Size**:
  - **Remove**: `"64 DAYS REMAINING"` text completely.
  - **Keep ONLY**: The pure **Dot Matrix** + the **Mission Title** cleanly at the bottom.
  - No text clutter, no redundant labels.
- **Medium Size**:
  - Left column: Minimalist `"84D LEFT"` (replaces `"84 DAYS REMAINING..."` to eliminate text truncation) + Mission Title.
  - Right column: Full dynamic obsidian dot matrix.

### **Widget 2: Eliminate Duplicate Widgets**
- Currently, `MilestoneDotMatrixWidget` and `MilestoneWorkDotMatrixWidget` overlap in functionality and clutter the Widget Gallery.
- **Consolidation**:
  - Keep `MilestoneDotMatrixWidget` as the primary Work/Active Mission dot matrix.
  - Keep `MilestonePersonalDotMatrixWidget` as the dedicated Personal Mission countdown (Pro).
  - Remove duplicate `MilestoneWorkDotMatrixWidget`.

### **Widget 3: "Mission Card" (Tasks + Countdown)**
- **Small Size**: Remove `.systemSmall` support.
  - *Reasoning*: As requested, the small Mission Card is cramped and cluttered.
- **Medium Size**: Keep only the horizontal `.systemMedium` banner with the priority task and runway bar.

### **Widget 4: Focus Timer Widget**
- **Small Size**:
  - **Remove**: The long `"FOCUS SESSION"` text header that was truncating into `"FOCUS SE..."`.
  - **Keep**: Only the clean session fraction: **`1/4`** at the top right, with the hardware ring centered. Clean and zero truncation.

### **Widget 5: Dual-Pillar Large Widget (Work + Personal Side-by-Side)**
- **Refinements**:
  - Header: Replace `"DAYS REMAINING"` with `"D LEFT"` (e.g. `84D LEFT`) so text never truncates to `...`.
  - Grid: Support dynamic 1:1 scaling so 64, 84, and 90-day missions display their **exact 1:1 dots** without an arbitrary 70-dot cap.

### **Widget 6: NEW Flagship Large Widget — Full-Screen Aesthetic Runway (Work & Personal)**
- A dedicated `.systemLarge` widget designed purely for aesthetics on a home screen page:
  - **Top Single Row**:
    - Left: `WORK` (or `PERSONAL`) indicator dot + title.
    - Right: Synchronized countdown counter: `84D LEFT`.
  - **Entire Rest of the Canvas**:
    - A sprawling, majestic, high-density **Obsidian Dot Runway** stretching edge-to-edge.
    - Dynamic dot matrix scaling cleanly whether the mission is 10 days or 150 days.

---

## 3. Dynamic Dot Sizing Engine (1 to 150+ Days)

To ensure the dots never clip, overflow, or look like awkward dust:

| Total Mission Days | Grid Layout | Dot Size | Spacing | Behavior |
|---|:---:|:---:|:---:|---|
| **1 – 15 Days** | 5 cols | `9.0 pt` | `6.0 pt` | Bold, punchy sprint dots (1:1) |
| **16 – 35 Days** | 6 cols | `7.2 pt` | `4.8 pt` | Clean monthly matrix (1:1) |
| **36 – 65 Days** | 7 cols | `5.8 pt` | `3.8 pt` | 7-day calendar week rhythm (1:1) |
| **66 – 100 Days** | 9 or 10 cols | `4.8 pt` | `3.0 pt` | High-density runway, exact 1:1 (e.g. all 90 dots visible) |
| **101 – 150+ Days** | 10 cols | `4.6 pt` | `2.6 pt` | 100-dot milestone percentage heat matrix (1 dot = 1% progress) |

---

## 4. Implementation Task List

- [ ] **Task 1: Overhaul Small Dot Matrix View**
  - In `MilestoneDotMatrixWidget.swift`: Remove `"DAYS REMAINING"` header; display pure dots + mission title.
- [ ] **Task 2: Eliminate Duplicate Widgets & Clean Widget Gallery**
  - Consolidate `MilestoneWorkDotMatrixWidget` into `MilestoneDotMatrixWidget`.
  - Remove `.systemSmall` from `MilestoneMissionWidget.swift`.
- [ ] **Task 3: Fix Focus Timer Truncation**
  - In `MilestonePomodoroWidget.swift`: Replace `"FOCUS SESSION"` with minimal `1/4` session counter.
- [ ] **Task 4: Implement Dynamic Dot Engine (1 to 150+ Days)**
  - Support exact 1:1 rendering for 64d, 84d, 90d, and percentiles for 101–150+d.
- [ ] **Task 5: Build Large Aesthetic Dot Runway Widget**
  - Full-canvas aesthetic layout: Top header row (`WORK` + `84D LEFT`) + full-page dot runway.
- [ ] **Task 6: Simulator & Device Build Verification**
  - Build and verify with `xcodebuild`.
  - Validate all sizes (Small, Medium, Large, Lock Screen) for visual balance and zero clipping.
