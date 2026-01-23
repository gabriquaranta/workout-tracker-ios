//
//  Workout_TrackerApp.swift
//  Workout Tracker
//

import SwiftUI
import UserNotifications

@main
struct WorkoutTrackerApp: App {
    @StateObject private var store = WorkoutStore()
    @StateObject private var themeManager = ThemeManager()
    
    // CORRECTED: Use a simple 'let' constant. The delegate does not need to be an
    // @StateObject because it doesn't publish any changes for the UI to observe.
    private let notificationDelegate = NotificationDelegate()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .onAppear {
                    ActivityManager.endAllWorkoutsNow()

                    // This line will now work correctly with the 'let' constant.
                    UNUserNotificationCenter.current().delegate = notificationDelegate

                    // End any lingering Live Activities from previous runs
                    ActivityManager.endAllWorkoutsNow()

                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                        // Notification permission handled silently
                    }
                }
        }
    }
}
