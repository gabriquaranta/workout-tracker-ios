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

## Key Features

- **Dynamic Workout Plans**:

  - Create, edit, and delete custom workout plans.
  - Clone existing workouts to quickly create new routines.
  - Add exercises to any workout and define multiple sets with specific reps, weight, and rest times.
  - Newly added sets automatically copy the values from the previous set, speeding up plan creation.

- **Interactive Workout Sessions**:

  - **Live Activities & Dynamic Island**: Your main workout timer and active rest timers are always visible on your Lock Screen and in the Dynamic Island.
  - A live in-app timer tracks the total session duration.
  - Check off sets as you complete them with satisfying **haptic feedback**.
  - An automatic rest timer starts after each set, with a system notification when time is up.
  - Edit any set inline while you train with quick steppers or direct text entry for reps, weight, and rest.

- **Qualitative & Quantitative Tracking**:

  - **Exercise Feedback**: Rate how each exercise felt using an emoji scale (😄 to 💀) and see how it compares to your last attempt.
  - **Workout Notes**: After finishing, add session-specific notes (e.g., "Felt strong," "Low energy") that are saved to your workout log.

- **Customization & Settings**:

  - **Theme Switching**: Choose between light, dark, or automatic (system) appearance modes in the settings.
  - **Bodyweight Tracking**: Set your current bodyweight in the settings. Used for relative strength stats.
  - **Smallest Weight Increment**: Customize the load rounding the app applies so recommendations match the plates you own.

- **Import & Export**:

  - **Export Workouts**: Export any workout as a JSON file from the editing screen. Share or back up your routines easily.
  - **Import Workouts**: Import a workout from a JSON file, replacing the current workout in the editor. Great for sharing routines with friends or moving between devices.

- **Advanced Stats & History**:

  - **Main Dashboard**: See your total completed workouts, total time spent working out, and average progress across all exercises at a glance on the main screen.
  - **Performance Graphs**: For each exercise, view a graph of your **max single-set volume** (`reps * weight`) over time, or switch to a graph of **max weight as a percentage of your bodyweight** over time.
  - **Personal Records**: Track key PRs, including your max weight ever lifted, reps at max, and best weight/bodyweight %.
  - **Progressive Overload Tracking**: Get smart weight increase suggestions based on your performance, deload warnings when recovery is needed, and detailed progress analytics showing improvement percentages over time.
  - **Weekly Volume Trend**: A compact line chart on the workouts tab highlights how your total load evolves week over week.
  - **Searchable History**: A detailed, date-sorted log of all completed workouts, including notes and feedback. The main stats screen has a search bar to quickly find any exercise.
  - **Clear History**: Option to safely delete all workout history and stats without affecting your saved workout plans.

- **Data Persistence**: Your workouts and history are automatically saved to the device, so your data is always there when you open the app.

## Privacy

All data is stored locally on your device. No accounts, no cloud, and no tracking—your workouts and stats are private and never leave your phone.

## Technology Stack

- **Language**: Swift
- **UI Framework**: SwiftUI (100% native)
- **Advanced Features**:
  - **ActivityKit**: For Live Activities and Dynamic Island integration.
  - **Charts**: Apple's native `Charts` Framework.
  - **UserNotifications**: For handling rest timer alerts.
- **Data Persistence**: `UserDefaults` with `Codable` for simple and fast local data storage.

## How to Run

### Prerequisites

- macOS Ventura or later
- Xcode 14.1 or later (for Live Activities support)
- An iOS Simulator or physical device running **iOS 16.1 or later**.

### Steps

1.  Clone or download the project source code.
2.  Open the `WorkoutTracker.xcodeproj` file in Xcode.
3.  Ensure you have a development team selected in the "Signing & Capabilities" tab for both the `Workout Tracker` and `WorkoutWidgets` targets.
4.  Select a target simulator (e.g., iPhone 15 Pro) or connect a physical device.
5.  Press the **Run** button (or `Cmd + R`) to build and run the app.
