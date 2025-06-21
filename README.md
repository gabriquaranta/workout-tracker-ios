
# SwiftUI Workout Tracker

A simple, snappy, and modern workout tracking app built entirely with SwiftUI. This app allows users to create custom workout plans, track their progress in real-time with Live Activity support, and view detailed statistics and history to monitor their performance over time.

<p>
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3379.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3380.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3381.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3382.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3383.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3384.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3385.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3386.PNG" width="180" />
</p>


## Key Features

-   **Dynamic Workout Plans**:
    -   Create, edit, and delete custom workout plans.
    -   Clone existing workouts to quickly create new routines.
    -   Add exercises to any workout and define multiple sets with specific reps, weight, and rest times.
    -   Newly added sets automatically copy the values from the previous set, speeding up plan creation.

-   **Interactive Workout Sessions**:
    -   **Live Activities & Dynamic Island**: Your main workout timer and active rest timers are always visible on your Lock Screen and in the Dynamic Island.
    -   A live in-app timer tracks the total session duration.
    -   Check off sets as you complete them with satisfying **haptic feedback**.
    -   An automatic rest timer starts after each set, with a system notification when time is up.

-   **Qualitative & Quantitative Tracking**:
    -   **Exercise Feedback**: Rate how each exercise felt using an emoji scale (😄 to 💀) and see how it compares to your last attempt.
    -   **Workout Notes**: After finishing, add session-specific notes (e.g., "Felt strong," "Low energy") that are saved to your workout log.

-   **Advanced Stats & History**:
    -   **Main Dashboard**: See your total completed workouts and total time spent working out at a glance on the main screen.
    -   **Performance Graphs**: View a graph of your **max single-set volume** (`reps * weight`) for each exercise over time.
    -   **Personal Records**: Track key PRs, including your max weight ever lifted and the corresponding reps for that lift.
    -   **Searchable History**: A detailed, date-sorted log of all completed workouts, including notes and feedback. The main stats screen has a search bar to quickly find any exercise.
    -   **Clear History**: Option to safely delete all workout history and stats without affecting your saved workout plans.

-   **Data Persistence**: Your workouts and history are automatically saved to the device, so your data is always there when you open the app.

## Technology Stack

-   **Language**: Swift
-   **UI Framework**: SwiftUI (100% native)
-   **Advanced Features**:
    -   **ActivityKit**: For Live Activities and Dynamic Island integration.
    -   **Charts**: Apple's native `Charts` Framework.
    -   **UserNotifications**: For handling rest timer alerts.
-   **Data Persistence**: `UserDefaults` with `Codable` for simple and fast local data storage.

## How to Run

### Prerequisites
-   macOS Ventura or later
-   Xcode 14.1 or later (for Live Activities support)
-   An iOS Simulator or physical device running **iOS 16.1 or later**.

### Steps
1.  Clone or download the project source code.
2.  Open the `WorkoutTracker.xcodeproj` file in Xcode.
3.  Ensure you have a development team selected in the "Signing & Capabilities" tab for both the `Workout Tracker` and `WorkoutWidgets` targets.
4.  Select a target simulator (e.g., iPhone 15 Pro) or connect a physical device.
5.  Press the **Run** button (or `Cmd + R`) to build and run the app.
