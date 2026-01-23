//
//  ActivityManager.swift
//  Workout Tracker
//

import Foundation
import ActivityKit

struct ActivityManager {
    /// End all active WorkoutActivityAttributes activities immediately.
    static func endAllWorkoutsNow() {
        Task {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                let state = WorkoutActivityAttributes.ContentState(timerEndDate: Date(), workoutTimerText: "00:00", isResting: false)
                let content = ActivityContent(state: state, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }
}
