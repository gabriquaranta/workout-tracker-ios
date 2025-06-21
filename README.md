# SwiftUI Workout Tracker
A simple snappy workout tracking app built entirely with SwiftUI. This app allows to create custom workout plans, track their progress and view statistics and history to monitor performance over time.

<p>
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3372.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3373.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3374.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3375.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3376.PNG" width="180" />
  <img src="https://github.com/gabriquaranta/workout-tracker-ios/blob/main/screenshots/IMG_3377.PNG" width="180" />
</p>

## Features
- **Workout Creation**: Create, edit, and delete custom workout plans.
- **Customizable Exercises**: Add exercises to any workout and define multiple sets with specific reps, weight, and rest times.
- **Active Workout Mode**:
  - A live workout timer tracks the total session duration.
  - Check off sets as you complete them.
  - An automatic rest timer starts after each completed set.
  - Foreground notifications alert when the rest period is over.
- **Performance Stats**:
  - A dedicated stats tab lists every exercise you've ever performed.
  - View a graph of max set volume (reps * weight) for each exercise over time.
  - Track key personal records, including max weight lifted and the reps performed at that weight.
- **Workout History**:
  - Access a detailed, date-sorted log of all previously completed workouts.
  - Review the exact sets, reps, and weights performed in any past session.
- **Data Persistence**: Workouts and history are automatically saved to the device only.
## Technology Stack
- Language: Swift
- UI Framework: SwiftUI (100% native)
- Charts: Apple's Charts Framework (iOS 16+)
- Data Persistence: UserDefaults with Codable for simple and fast data storage.
- Notifications: UserNotifications Framework for handling rest timer alerts.
## How to Run
#### Prerequisites
- macOS Ventura or later
- Xcode 14 or later
- An iOS Simulator or physical device running iOS 16.0 or later (required for the Charts framework).
#### Steps
1. Clone or download the project source code.
2. Open the WorkoutTracker.xcodeproj file in Xcode.
3. Select a target simulator (e.g., iPhone 14 Pro) or connect a physical device.
4. Press the Run button (or Cmd + R) to build and run the app.
