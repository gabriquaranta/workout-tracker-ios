// NOTE: The abbreviatedString(from:) method referenced in WorkoutLog requires a DateComponentsFormatter extension, usually implemented in DateComponentsFormatter+Extensions.swift. Ensure this extension exists in your project.
//
//  Models.swift
//  Workout Tracker
//

import Foundation

// MARK: - Workout Plan Models
struct Workout: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
    var scheduledDays: Set<Weekday> = []
    
    init(id: UUID = UUID(), name: String, exercises: [Exercise], scheduledDays: Set<Weekday> = []) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.scheduledDays = scheduledDays
    }
}

struct Exercise: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var sets: [WorkoutSet]
    
    init(id: UUID = UUID(), name: String, sets: [WorkoutSet]) {
        self.id = id
        self.name = name
        self.sets = sets
    }
}

struct WorkoutSet: Codable, Identifiable, Hashable {
    let id: UUID
    var reps: Int = 10
    var weight: Double = 20.0
    var restTimeInSeconds: Int = 60
    
    init(id: UUID = UUID(), reps: Int = 10, weight: Double = 20.0, restTimeInSeconds: Int = 60) {
        self.id = id
        self.reps = max(0, reps)
        self.weight = max(0.0, weight)
        self.restTimeInSeconds = max(0, restTimeInSeconds)
    }
}

// MARK: - Live Workout Model
struct LiveWorkoutSet: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var reps: Int
    var weight: Double
    var restTimeInSeconds: Int
    var isCompleted: Bool = false
    var wasModified: Bool = false // Tracks if reps or weight were changed.
}

// MARK: - Active Workout Model
struct ActiveWorkout: Codable, Equatable {
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
struct WorkoutLog: Codable, Identifiable, Equatable {
    let id: UUID
    var date: Date
    var workoutName: String
    var duration: TimeInterval
    var completedExercises: [CompletedExercise]
    var notes: String? = nil
    
    init(id: UUID = UUID(), date: Date, workoutName: String, duration: TimeInterval, completedExercises: [CompletedExercise], notes: String? = nil) {
        self.id = id
        self.date = date
        self.workoutName = workoutName
        self.duration = duration
        self.completedExercises = completedExercises
        self.notes = notes
    }

    /// Formats the workout duration using the custom DateComponentsFormatter extension.
    /// The method 'abbreviatedString(from:)' is a static extension in DateComponentsFormatter+Extensions.swift.
    /// Make sure DateComponentsFormatter+Extensions.swift is included in the target.
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: duration) ?? "0s"
    }
}

struct CompletedExercise: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var sets: [CompletedSet]
    var feedback: FeedbackRating? = nil
    
    init(id: UUID = UUID(), name: String, sets: [CompletedSet], feedback: FeedbackRating? = nil) {
        self.id = id
        self.name = name
        self.sets = sets
        self.feedback = feedback
    }

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

struct CompletedSet: Codable, Identifiable, Equatable {
    let id: UUID
    var reps: Int
    var weight: Double
    
    init(id: UUID = UUID(), reps: Int, weight: Double) {
        self.id = id
        self.reps = reps
        self.weight = weight
    }
    
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

