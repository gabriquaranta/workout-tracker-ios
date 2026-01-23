//
//  WorkoutActivityAttributes.swift
//  Workout Tracker
//

import Foundation
import Foundation
import ActivityKit

struct WorkoutActivityAttributes: ActivityAttributes {
    // This defines the dynamic data that will update during the activity.
    public struct ContentState: Codable, Hashable {
        var timerEndDate: Date
        var workoutTimerText: String
        var isResting: Bool
    }
    
    // This is static data that you provide once when the activity starts.
    var workoutName: String
}