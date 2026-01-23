// MockPersistenceManager.swift

import Foundation
@testable import Workout_Tracker

// MARK: - In-Memory Persistence Manager

/// A mock implementation of PersistenceProtocol that stores data in memory only.
/// Perfect for unit tests and SwiftUI previews as it:
/// - Does not touch UserDefaults
/// - Provides isolated storage per instance
/// - Can be pre-populated with test data
final class MockPersistenceManager: PersistenceProtocol {
    
    // MARK: - In-Memory Storage
    
    var workouts: [Workout]?
    var history: [WorkoutLog]?
    var activeWorkout: ActiveWorkout?
    var bodyweight: Double?
    var smallestWeightIncrement: Double?
    var theme: String?
    
    // MARK: - Call Tracking (for verification in tests)
    
    private(set) var saveWorkoutsCalled = false
    private(set) var saveHistoryCalled = false
    private(set) var saveActiveWorkoutCalled = false
    private(set) var saveBodyweightCalled = false
    private(set) var saveSmallestWeightIncrementCalled = false
    private(set) var saveThemeCalled = false
    
    // MARK: - Initialization
    
    /// Creates an empty mock persistence manager
    init() {}
    
    /// Creates a mock persistence manager with pre-populated data
    init(
        workouts: [Workout]? = nil,
        history: [WorkoutLog]? = nil,
        activeWorkout: ActiveWorkout? = nil,
        bodyweight: Double? = nil,
        smallestWeightIncrement: Double? = nil,
        theme: String? = nil
    ) {
        self.workouts = workouts
        self.history = history
        self.activeWorkout = activeWorkout
        self.bodyweight = bodyweight
        self.smallestWeightIncrement = smallestWeightIncrement
        self.theme = theme
    }
    
    // MARK: - Workout Data
    
    func saveWorkouts(_ workouts: [Workout]) {
        self.workouts = workouts
        saveWorkoutsCalled = true
    }
    
    func loadWorkouts() -> [Workout]? {
        return workouts
    }
    
    // MARK: - History
    
    func saveHistory(_ history: [WorkoutLog]) {
        self.history = history
        saveHistoryCalled = true
    }
    
    func loadHistory() -> [WorkoutLog]? {
        return history
    }
    
    // MARK: - Active Workout State
    
    func saveActiveWorkout(_ activeWorkout: ActiveWorkout?) {
        self.activeWorkout = activeWorkout
        saveActiveWorkoutCalled = true
    }
    
    func loadActiveWorkout() -> ActiveWorkout? {
        return activeWorkout
    }
    
    // MARK: - User Settings
    
    func saveBodyweight(_ bodyweight: Double) {
        self.bodyweight = bodyweight
        saveBodyweightCalled = true
    }
    
    func loadBodyweight() -> Double? {
        return bodyweight
    }
    
    func saveSmallestWeightIncrement(_ increment: Double) {
        self.smallestWeightIncrement = increment
        saveSmallestWeightIncrementCalled = true
    }
    
    func loadSmallestWeightIncrement() -> Double? {
        return smallestWeightIncrement
    }
    
    // MARK: - Theme Settings
    
    func saveTheme(_ theme: String) {
        self.theme = theme
        saveThemeCalled = true
    }
    
    func loadTheme() -> String? {
        return theme
    }
    
    // MARK: - Test Helpers
    
    /// Resets all call tracking flags
    func resetCallTracking() {
        saveWorkoutsCalled = false
        saveHistoryCalled = false
        saveActiveWorkoutCalled = false
        saveBodyweightCalled = false
        saveSmallestWeightIncrementCalled = false
        saveThemeCalled = false
    }
    
    /// Clears all stored data
    func clearAllData() {
        workouts = nil
        history = nil
        activeWorkout = nil
        bodyweight = nil
        smallestWeightIncrement = nil
        theme = nil
    }
}
