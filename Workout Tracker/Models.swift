// Models.swift

import Foundation

// MARK: - Workout Plan Models
struct Workout: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var exercises: [Exercise]
    var scheduledDays: Set<Weekday> = []
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

// MARK: - Live Workout Model
struct LiveWorkoutSet: Identifiable, Codable {
    let id: UUID
    var reps: Int
    var weight: Double
    var restTimeInSeconds: Int
    var isCompleted: Bool = false
    var wasModified: Bool = false // NEW: Tracks if reps or weight were changed.
}

// MARK: - Active Workout Model
struct ActiveWorkout: Codable {
    var workoutID: UUID
    var workoutName: String
    var startTime: Date
    var totalElapsedTime: TimeInterval
    var liveSetsByExercise: [UUID: [LiveWorkoutSet]]
    var exerciseFeedback: [String: FeedbackRating]
    var isResting: Bool
    var restEndDate: Date?
    var restTimeRemaining: Int
}

// MARK: - Workout Log Models
struct WorkoutLog: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var workoutName: String
    var duration: TimeInterval
    var completedExercises: [CompletedExercise]
    var notes: String? = nil

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

enum Weekday: Int, CaseIterable, Codable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1
    
    var shortName: String {
        switch self {
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        case .sunday: return "S"
        }
    }
    
    var fullName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}
