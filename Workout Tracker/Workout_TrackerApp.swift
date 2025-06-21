// WorkoutTrackerApp.swift

import SwiftUI
import UserNotifications

@main
struct WorkoutTrackerApp: App {
    @StateObject private var store = WorkoutStore()
    
    // CORRECTED: Use a simple 'let' constant. The delegate does not need to be an
    // @StateObject because it doesn't publish any changes for the UI to observe.
    private let notificationDelegate = NotificationDelegate()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    // This line will now work correctly with the 'let' constant.
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                    
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        if granted {
                            print("Notification permission granted.")
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                }
        }
    }
}
