//
//  PersistenceManager.swift
//  Workout Tracker
//

import Foundation

// MARK: - Persistence Protocol

/// Protocol defining persistence operations for the Workout Tracker app.
/// Enables dependency injection and facilitates testing with mock implementations.
/// Future migration to SwiftData/CoreData can be achieved by creating a new conforming type.
protocol PersistenceProtocol {
    
    // MARK: - Workout Data
    
    /// Saves the array of workout plans
    func saveWorkouts(_ workouts: [Workout])
    
    /// Loads saved workout plans, returns nil if no data exists
    func loadWorkouts() -> [Workout]?
    
    // MARK: - History
    
    /// Saves the workout history logs
    func saveHistory(_ history: [WorkoutLog])
    
    /// Loads workout history logs, returns nil if no data exists
    func loadHistory() -> [WorkoutLog]?
    
    // MARK: - Active Workout State
    
    /// Saves the current active workout state
    func saveActiveWorkout(_ activeWorkout: ActiveWorkout?)
    
    /// Loads the active workout state, returns nil if no active workout exists
    func loadActiveWorkout() -> ActiveWorkout?
    
    // MARK: - User Settings
    
    /// Saves the user's bodyweight
    func saveBodyweight(_ bodyweight: Double)
    
    /// Loads the user's bodyweight, returns nil if not set
    func loadBodyweight() -> Double?
    
    /// Saves the smallest weight increment preference
    func saveSmallestWeightIncrement(_ increment: Double)
    
    /// Loads the smallest weight increment, returns nil if not set
    func loadSmallestWeightIncrement() -> Double?
    
    // MARK: - Theme Settings
    
    /// Saves the selected theme
    func saveTheme(_ theme: String)
    
    /// Loads the selected theme, returns nil if not set
    func loadTheme() -> String?
}

// MARK: - UserDefaults Implementation

/// Default implementation of PersistenceProtocol using UserDefaults.
/// Provides backward-compatible storage for existing app data.
final class UserDefaultsPersistenceManager: PersistenceProtocol {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    /// Creates a new UserDefaultsPersistenceManager.
    /// - Parameter userDefaults: The UserDefaults instance to use. Defaults to `.standard`.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }
    
    // MARK: - Workout Data
    
    func saveWorkouts(_ workouts: [Workout]) {
        do {
            let encoded = try encoder.encode(workouts)
            userDefaults.set(encoded, forKey: UserDefaultsKeys.workouts)
        } catch {
            let persistenceError = PersistenceError.encodingFailed(
                type: "[Workout]",
                underlyingError: error
            )
            PersistenceLogger.log(persistenceError)
        }
    }
    
    func loadWorkouts() -> [Workout]? {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.workouts) else {
            // No data found is expected for first-time users - not an error
            return nil
        }
        
        do {
            return try decoder.decode([Workout].self, from: data)
        } catch {
            let persistenceError = PersistenceError.decodingFailed(
                type: "[Workout]",
                underlyingError: error
            )
            PersistenceLogger.log(persistenceError)
            return nil
        }
    }
    
    // MARK: - History
    
    func saveHistory(_ history: [WorkoutLog]) {
        do {
            let encoded = try encoder.encode(history)
            userDefaults.set(encoded, forKey: UserDefaultsKeys.history)
        } catch {
            let persistenceError = PersistenceError.encodingFailed(
                type: "[WorkoutLog]",
                underlyingError: error
            )
            PersistenceLogger.log(persistenceError)
        }
    }
    
    func loadHistory() -> [WorkoutLog]? {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.history) else {
            // No history is expected for first-time users - not an error
            return nil
        }
        
        do {
            return try decoder.decode([WorkoutLog].self, from: data)
        } catch {
            let persistenceError = PersistenceError.decodingFailed(
                type: "[WorkoutLog]",
                underlyingError: error
            )
            PersistenceLogger.log(persistenceError)
            return nil
        }
    }
    
    // MARK: - Active Workout State
    
    func saveActiveWorkout(_ activeWorkout: ActiveWorkout?) {
        if let activeWorkout = activeWorkout {
            do {
                let encoded = try encoder.encode(activeWorkout)
                userDefaults.set(encoded, forKey: UserDefaultsKeys.activeWorkout)
            } catch {
                let persistenceError = PersistenceError.encodingFailed(
                    type: "ActiveWorkout",
                    underlyingError: error
                )
                PersistenceLogger.log(persistenceError)
            }
        } else {
            userDefaults.removeObject(forKey: UserDefaultsKeys.activeWorkout)
        }
    }
    
    func loadActiveWorkout() -> ActiveWorkout? {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.activeWorkout) else {
            // No active workout is a normal state - not an error
            return nil
        }
        
        do {
            return try decoder.decode(ActiveWorkout.self, from: data)
        } catch {
            let persistenceError = PersistenceError.decodingFailed(
                type: "ActiveWorkout",
                underlyingError: error
            )
            PersistenceLogger.log(persistenceError)
            return nil
        }
    }
    
    // MARK: - User Settings
    
    func saveBodyweight(_ bodyweight: Double) {
        userDefaults.set(bodyweight, forKey: UserDefaultsKeys.bodyweight)
    }
    
    func loadBodyweight() -> Double? {
        return userDefaults.object(forKey: UserDefaultsKeys.bodyweight) as? Double
    }
    
    func saveSmallestWeightIncrement(_ increment: Double) {
        userDefaults.set(increment, forKey: UserDefaultsKeys.smallestWeightIncrement)
    }
    
    func loadSmallestWeightIncrement() -> Double? {
        return userDefaults.object(forKey: UserDefaultsKeys.smallestWeightIncrement) as? Double
    }
    
    // MARK: - Theme Settings
    
    func saveTheme(_ theme: String) {
        userDefaults.set(theme, forKey: UserDefaultsKeys.selectedTheme)
    }
    
    func loadTheme() -> String? {
        return userDefaults.string(forKey: UserDefaultsKeys.selectedTheme)
    }
}
