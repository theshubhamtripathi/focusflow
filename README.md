# FocusFlow 🍅

A professional iOS productivity app built with Swift, SwiftUI, and CoreData.

## Features

- **Pomodoro Timer** — 25/5/15 minute work and break cycles with animated circular progress ring
- **Task Management** — Full CRUD with priority levels, due dates, and completion tracking
- **Daily Streaks** — Consecutive day tracking with GitHub-style activity heatmap
- **Progress Analytics** — Focus time charts, task completion rates, and peak hour analysis
- **Push Notifications** — Timer completion alerts and daily focus reminders
- **Settings** — Customisable timer durations and daily goals

## Tech Stack

| Technology | Usage |
|---|---|
| Swift 5.9 | Primary language |
| SwiftUI | Declarative UI framework |
| CoreData | Local data persistence |
| Combine | Reactive timer with publishers |
| UserNotifications | Push notification scheduling |
| Swift Charts | Analytics visualisation |
| MVVM | Architecture pattern |

## Architecture

```
FocusFlow/
├── App/                    # Entry point, dependency injection
├── Models/                 # CoreData entities (Task, FocusSession)
├── ViewModels/             # Business logic (TaskVM, TimerVM, StreakVM, AnalyticsVM)
├── Views/
│   ├── Tasks/              # TaskListView, TaskDetailView, AddTaskView
│   ├── Timer/              # TimerView, CircularProgressRing
│   ├── Streaks/            # StreakView, HeatmapView, WeeklyBarChart
│   └── Analytics/          # AnalyticsView with Swift Charts
├── Persistence/            # CoreData stack, NotificationManager
└── Resources/              # Assets, AppTheme design system
```

## Key Technical Decisions

**Why MVVM?**
SwiftUI's `@Published` + `ObservableObject` pattern is purpose-built for MVVM. ViewModels own all business logic — Views are purely declarative.

**Why CoreData over other persistence?**
Native Apple framework with zero dependencies. Relationship support between Task and FocusSession enables session history and analytics without manual joins.

**Why Combine for the timer?**
`Timer.publish` integrates directly with `@Published` properties — each tick automatically propagates to the UI with zero manual `DispatchQueue` calls.

## Setup

1. Clone the repo
```bash
git clone https://github.com/theshubhamtripathi/focusflow.git
```
2. Open `FocusFlow.xcodeproj` in Xcode 15+
3. Select a simulator (iPhone 15 or later recommended)
4. Press ⌘ + R to build and run

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Daily Build Log

| Day | Feature | Commit |
|---|---|---|
| Day 1 | Project setup, MVVM structure, CoreData model | ✅ |
| Day 2 | TaskList UI, CoreData CRUD operations | ✅ |
| Day 3 | Pomodoro timer, Combine, circular ring | ✅ |
| Day 4 | Task detail, edit, filters, session linking | ✅ |
| Day 5 | Streak tracking, heatmap, weekly chart | ✅ |
| Day 6 | UserNotifications, Swift Charts analytics | ✅ |
| Day 7 | UI polish, Settings, documentation | ✅ |

## Developer

**Shubham Tripathi**
Built in 7 days as a portfolio project demonstrating iOS development skills.
Open for feature suggestions!
