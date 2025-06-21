//
//  NotificationDelegate.swift
//  Workout Tracker
//
//  Created by Gabriele Quaranta on 20/06/25.
//


// NotificationDelegate.swift

import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    // This function is called when a notification is delivered to a foreground app.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Here, we tell the system to show the notification alert (banner), play a sound,
        // and update the badge icon. You can customize this as needed.
        completionHandler([.banner, .sound, .badge])
    }
}