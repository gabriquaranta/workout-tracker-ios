//
//  Models.swift
//  Workout Tracker
//
//  Created by Gabriele Quaranta on 20/06/25.
//

// Models.swift

import Foundation

// MARK: - Workout Plan Models
struct Workout: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var exercises: [Exercise]
}

struct Exercise: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var sets: [WorkoutSet]
}

struct WorkoutSet: Codable, Identifiable, Hashable {
    var id = UUID()
    var reps: Int = 10
    var weight: Double = 20.0
    var restTimeInSeconds: Int = 60
}

// MARK: - Workout Log Models (for historical data)
struct WorkoutLog: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var workoutName: String
    var duration: TimeInterval // in seconds
    var completedExercises: [CompletedExercise]
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

struct CompletedExercise: Codable, Identifiable {
    var id = UUID()
    var name: String
    var sets: [CompletedSet]
    
    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }
}

struct CompletedSet: Codable, Identifiable {
    var id = UUID()
    var reps: Int
    var weight: Double
    
    var volume: Double {
        Double(reps) * weight
    }
}
