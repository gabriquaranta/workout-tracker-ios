//
//  WorkoutError.swift
//  Workout Tracker
//

import Foundation

// MARK: - Workout Errors

/// Custom error types for workout-related operations in the Workout Tracker app.
/// Provides meaningful error context for workout creation, modification,
/// and exercise management failures.
enum WorkoutError: Error, LocalizedError {
    
    /// The specified exercise was not found in the workout
    case exerciseNotFound(name: String)
    
    /// The specified workout was not found
    case workoutNotFound(id: UUID)
    
    /// Set data is invalid or malformed
    case invalidSetData(reason: String)
    
    /// Workout has no exercises
    case emptyWorkout
    
    /// Exercise has no sets
    case emptyExercise(name: String)
    
    /// Duplicate exercise name in the same workout
    case duplicateExercise(name: String)
    
    /// Invalid weight value (negative or unreasonable)
    case invalidWeight(value: Double)
    
    /// Invalid rep count (zero or negative)
    case invalidReps(value: Int)
    
    /// Workout is currently active and cannot be modified
    case workoutInProgress
    
    /// Timer operation failed
    case timerError(reason: String)
    
    // MARK: - LocalizedError Conformance
    
    var errorDescription: String? {
        switch self {
        case .exerciseNotFound(let name):
            return "Exercise '\(name)' was not found"
        case .workoutNotFound(let id):
            return "Workout with ID \(id.uuidString) was not found"
        case .invalidSetData(let reason):
            return "Invalid set data: \(reason)"
        case .emptyWorkout:
            return "Cannot save an empty workout"
        case .emptyExercise(let name):
            return "Exercise '\(name)' has no sets"
        case .duplicateExercise(let name):
            return "Exercise '\(name)' already exists in this workout"
        case .invalidWeight(let value):
            return "Invalid weight value: \(value)"
        case .invalidReps(let value):
            return "Invalid rep count: \(value)"
        case .workoutInProgress:
            return "Cannot modify workout while it is in progress"
        case .timerError(let reason):
            return "Timer error: \(reason)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .exerciseNotFound:
            return "The exercise does not exist in the current workout"
        case .workoutNotFound:
            return "The workout could not be located in stored data"
        case .invalidSetData:
            return "The set contains invalid or incomplete information"
        case .emptyWorkout:
            return "A workout must contain at least one exercise"
        case .emptyExercise:
            return "An exercise must contain at least one set"
        case .duplicateExercise:
            return "Each exercise name must be unique within a workout"
        case .invalidWeight:
            return "Weight must be a positive number"
        case .invalidReps:
            return "Rep count must be at least 1"
        case .workoutInProgress:
            return "Complete or cancel the current workout first"
        case .timerError:
            return "The rest timer encountered an error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .exerciseNotFound:
            return "Try adding the exercise to the workout first"
        case .workoutNotFound:
            return "The workout may have been deleted. Try refreshing the list"
        case .invalidSetData:
            return "Check that weight and reps are valid numbers"
        case .emptyWorkout:
            return "Add at least one exercise before saving"
        case .emptyExercise:
            return "Add at least one set to the exercise"
        case .duplicateExercise:
            return "Use a different exercise name or combine with existing"
        case .invalidWeight:
            return "Enter a weight value of 0 or greater"
        case .invalidReps:
            return "Enter a rep count of 1 or more"
        case .workoutInProgress:
            return "Finish your current workout before making changes"
        case .timerError:
            return "Try restarting the timer"
        }
    }
}
