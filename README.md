# SwiftUI Workout Tracker

A simple, snappy, and modern workout tracking app built entirely with SwiftUI. This app allows users to create custom workout plans, track their progress in real-time with Live Activity support, and view detailed statistics and history to monitor their performance over time.

<p>
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3379.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_4958.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_4959.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_4961.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_4962.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_4964.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_4965.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_4966.PNG" width="180" />
</p>

---

## Features

### Core Functionality

- **Dynamic Workout Plans**: Create, edit, delete, and clone custom workout plans with exercises and sets
- **Interactive Workout Sessions**: Real-time tracking with haptic feedback and automatic rest timers
- **Live Activities & Dynamic Island**: Workout timer and rest timer always visible on Lock Screen
- **Exercise Feedback**: Rate exercises on an emoji scale (😄 to 💀) with comparison to previous sessions
- **Progressive Overload Tracking**: Smart weight increase suggestions and deload recommendations

### Stats & Analytics

- **Performance Graphs**: Max single-set volume and bodyweight percentage over time
- **Personal Records**: Track max weight, reps at max, and best bodyweight percentage
- **Weekly Volume Trend**: Visual chart of training load over weeks
- **Searchable History**: Date-sorted log with notes and feedback

### Customization

- **Theme Switching**: Light, dark, or automatic (system) appearance
- **Bodyweight Tracking**: Used for relative strength calculations
- **Weight Increment Settings**: Match recommendations to your available plates
- **Import/Export**: Share routines via JSON files

---

## Architecture

The app follows a layered architecture moving toward MVVM with service abstractions.

```
┌─────────────────────────────────────────────────────────────────┐
│                         View Layer                              │
│  (SwiftUI Views with @EnvironmentObject access to WorkoutStore)│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       WorkoutStore                              │
│  Central ObservableObject managing state and coordinating       │
│  between views and services                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ PersistenceManager│ │ProgressiveOverload│ │WorkoutTimerManager│
│  (Storage)        │ │    Service        │ │   (Timers)        │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

### Project Structure

```
Workout Tracker/
├── Workout Tracker/              # Main app target
│   ├── Models.swift              # Core data models (Workout, Exercise, Set, etc.)
│   ├── WorkoutStore.swift        # Central state management (@MainActor)
│   ├── Constants.swift           # App-wide constants (overload thresholds, etc.)
│   ├── UserDefaultsKeys.swift    # Type-safe UserDefaults keys
│   │
│   ├── Services/                 # Business logic layer
│   │   ├── PersistenceManager.swift      # Storage abstraction (PersistenceProtocol)
│   │   ├── ProgressiveOverloadService.swift  # Progressive overload algorithms
│   │   ├── WorkoutTimerManager.swift     # Timer management with Combine
│   │   ├── PersistenceError.swift        # Custom error types
│   │   └── WorkoutError.swift            # Workout operation errors
│   │
│   ├── Components/               # Reusable UI components
│   │   ├── CardStyle.swift               # Shared card styling modifier
│   │   ├── ChipView.swift                # Tag/chip UI component
│   │   ├── ExerciseSuggestionService.swift   # Exercise name autocomplete logic
│   │   └── ExerciseSuggestionsView.swift     # Autocomplete dropdown UI
│   │
│   ├── Extensions/               # Swift extensions
│   │   └── DateComponentsFormatter+Extensions.swift  # Time formatting utilities
│   │
│   ├── [View Files]              # SwiftUI views (ActiveWorkoutView, StatsView, etc.)
│   └── Assets.xcassets/          # Images and colors
│
├── WorkoutWidgets/               # Widget Extension target
│   ├── WorkoutWidgets.swift      # Live Activity implementation
│   ├── WorkoutWidgetsBundle.swift
│   └── WorkoutActivityAttributes.swift  # Shared with main app
│
├── Workout TrackerTests/         # Unit tests
│   ├── WorkoutStoreTests.swift
│   ├── ProgressiveOverloadServiceTests.swift
│   ├── ModelsTests.swift
│   └── Mocks/                    # Test doubles
│       ├── MockPersistenceManager.swift
│       └── MockWorkoutStore.swift
│
└── Workout TrackerUITests/       # UI tests
```

### Key Services

| Service                        | Responsibility                                                                                                                                  |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **PersistenceManager**         | Abstracts UserDefaults storage with `PersistenceProtocol`. Enables future migration to SwiftData/CoreData and facilitates testing with mocks.   |
| **ProgressiveOverloadService** | Stateless service implementing evidence-based progressive overload algorithms. Calculates weight suggestions and detects when deload is needed. |
| **WorkoutTimerManager**        | Manages workout elapsed time and rest timers using Combine. Separates timer logic from views for testability.                                   |

## Refactor Highlights

### Service Layer

The refactor decoupled `WorkoutStore` from persistence, timer, and overload calculations so each responsibility now lives in a focused service. The service layer discussed above wires together [Workout Tracker/Services/PersistenceManager.swift](Workout%20Tracker/Services/PersistenceManager.swift) (backed by `PersistenceProtocol`), [Workout Tracker/Services/ProgressiveOverloadService.swift](Workout%20Tracker/Services/ProgressiveOverloadService.swift), and [Workout Tracker/Services/WorkoutTimerManager.swift](Workout%20Tracker/Services/WorkoutTimerManager.swift) while `WorkoutStore` orchestrates them through dependency injection and `@MainActor`-guarded state.

Constants such as overload thresholds, request codecs, and UserDefaults keys were centralized inside [Workout Tracker/Constants.swift](Workout%20Tracker/Constants.swift) and [Workout Tracker/UserDefaultsKeys.swift](Workout%20Tracker/UserDefaultsKeys.swift) so every caller references the same source of truth, and the shared formatter in [Workout Tracker/Extensions/DateComponentsFormatter+Extensions.swift](Workout%20Tracker/Extensions/DateComponentsFormatter+Extensions.swift) keeps time displays consistent across widgets and views.

### Expanded Testing & Mocks

The testing layer now exercises the service boundaries and model logic with dedicated suites and test doubles. Coverage is maintained by [Workout TrackerTests/WorkoutStoreTests.swift](Workout%20TrackerTests/WorkoutStoreTests.swift), [Workout TrackerTests/ProgressiveOverloadServiceTests.swift](Workout%20TrackerTests/ProgressiveOverloadServiceTests.swift), and [Workout TrackerTests/ModelsTests.swift](Workout%20TrackerTests/ModelsTests.swift), while [Workout TrackerTests/Mocks/MockPersistenceManager.swift](Workout%20TrackerTests/Mocks/MockPersistenceManager.swift) and [Workout TrackerTests/Mocks/MockWorkoutStore.swift](Workout%20TrackerTests/Mocks/MockWorkoutStore.swift) keep view and service tests deterministic. Together the suites demonstrate CRUD safety, overload algorithms, deload detection, and model validation without touching production storage or timers.

---

## Technology Stack

| Category            | Technology                |
| ------------------- | ------------------------- |
| **Language**        | Swift 5.9+                |
| **UI Framework**    | SwiftUI (100% native)     |
| **Minimum iOS**     | iOS 17.0+                 |
| **Live Activities** | ActivityKit               |
| **Charts**          | Apple Charts framework    |
| **Notifications**   | UserNotifications         |
| **Persistence**     | UserDefaults with Codable |
| **Testing**         | Swift Testing framework   |

---

## Setup Instructions

### Prerequisites

- **macOS**: Sonoma 14.0 or later
- **Xcode**: 15.0 or later (Swift 5.9+, iOS 17 SDK)
- **Device/Simulator**: iOS 17.0 or later

### Build & Run

1. Clone the repository:

   ```bash
   git clone https://github.com/gabriquaranta/workout-tracker-ios.git
   cd workout-tracker-ios
   ```

2. Open the project in Xcode:

   ```bash
   open "Workout Tracker.xcodeproj"
   ```

3. Configure signing:
   - Select the `Workout Tracker` target → Signing & Capabilities
   - Choose your development team
   - Repeat for the `WorkoutWidgets` target

4. Select a target device (iPhone 15 Pro recommended for Dynamic Island)

5. Build and run (`Cmd + R`)

### Dependencies

This project has **no external dependencies**. All functionality uses Apple's native frameworks.

---

## Testing

The project uses Swift's modern Testing framework (`import Testing`).

### Running Tests

**Via Xcode:**

- Press `Cmd + U` to run all tests
- Use the Test Navigator (`Cmd + 6`) to run specific tests

**Via Command Line:**

```bash
xcodebuild test \
  -project "Workout Tracker.xcodeproj" \
  -scheme "Workout Tracker" \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro"
```

### Test Coverage

| Component            | Test File                               |
| -------------------- | --------------------------------------- |
| Models               | `ModelsTests.swift`                     |
| WorkoutStore         | `WorkoutStoreTests.swift`               |
| Progressive Overload | `ProgressiveOverloadServiceTests.swift` |

### Mock Objects

Test doubles are located in `Workout TrackerTests/Mocks/`:

- `MockPersistenceManager`: Implements `PersistenceProtocol` with in-memory storage
- `MockWorkoutStore`: Test double for view testing

---

## Key Patterns Used

### @EnvironmentObject for Shared State

`WorkoutStore` is injected at the app root and accessed throughout via `@EnvironmentObject`:

```swift
// App root injection
@main
struct WorkoutTrackerApp: App {
    @StateObject private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

// Access in any view
struct WorkoutsView: View {
    @EnvironmentObject var store: WorkoutStore
}
```

### PersistenceProtocol for Storage Abstraction

Protocol-based persistence enables dependency injection and testability:

```swift
protocol PersistenceProtocol {
    func saveWorkouts(_ workouts: [Workout])
    func loadWorkouts() -> [Workout]?
    func saveHistory(_ history: [WorkoutLog])
    func loadHistory() -> [WorkoutLog]?
    // ... additional methods
}

// Production implementation
class PersistenceManager: PersistenceProtocol { ... }

// Test mock
class MockPersistenceManager: PersistenceProtocol { ... }
```

### Live Activities for Workout Tracking

Workout progress is displayed on Lock Screen and Dynamic Island:

```swift
// Start activity
let attributes = WorkoutActivityAttributes(workoutName: workout.name)
let state = WorkoutActivityAttributes.ContentState(
    elapsedTime: 0,
    restTimeRemaining: nil
)
activity = try Activity.request(attributes: attributes, content: .init(state: state))

// Update activity
await activity?.update(using: newState)
```

### @MainActor for Thread Safety

`WorkoutStore` uses `@MainActor` to ensure all state changes occur on the main thread:

```swift
@MainActor
class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] { ... }
}
```

---

## Privacy

All data is stored locally on your device. No accounts, no cloud, and no tracking—your workouts and stats are private and never leave your phone.

---
