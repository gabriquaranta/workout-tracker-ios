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

// MARK: - Workout Log Models
struct WorkoutLog: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var workoutName: String
    var duration: TimeInterval
    var completedExercises: [CompletedExercise]
    var notes: String? = nil // NEW: Add optional notes for the whole workout session

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
    var feedback: FeedbackRating? = nil

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }
}

enum FeedbackRating: String, Codable, CaseIterable, Identifiable {
    case veryEasy = "😄"
    case easy = "🙂"
    case moderate = "😐"
    case hard = "🥵"
    case veryHard = "💀"
    
    var id: String { self.rawValue }
}

struct CompletedSet: Codable, Identifiable {
    var id = UUID()
    var reps: Int
    var weight: Double
    
    var volume: Double {
        Double(reps) * weight
    }
}
