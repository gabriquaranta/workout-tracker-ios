//
//  UserDefaultsKeys.swift
//  Workout Tracker
//

import Foundation

/// Centralized enum for all UserDefaults keys used throughout the app.
/// This prevents typos and provides compile-time safety for storage keys.
enum UserDefaultsKeys {
    // MARK: - Workout Data
    static let workouts = "workoutStore_workouts"
    static let history = "workoutStore_history"
    static let activeWorkout = "workoutStore_activeWorkout"
    
    // MARK: - User Settings
    static let bodyweight = "bodyweight"
    static let smallestWeightIncrement = "smallestWeightIncrement"
    
    // MARK: - Theme
    static let selectedTheme = "selectedTheme"
}
