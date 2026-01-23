//
//  WorkoutStore.swift
//  Workout Tracker
//

import SwiftUI
import Combine

// MARK: - Supporting Types

/// A data point representing total workout volume for a given week.
///
/// Used by charts to visualize weekly training volume trends over time.
struct WeeklyVolumePoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let totalVolume: Double
}

/// The central data store for managing workouts, workout history, and active workout sessions.
///
/// `WorkoutStore` is the primary source of truth for all workout-related data in the app.
/// It handles persistence, state management, and progressive overload calculations.
/// Use this class as an `@EnvironmentObject` throughout the app to access and modify workout data.
///
/// - Note: This class is marked as `@MainActor` to ensure all UI updates happen on the main thread.
@MainActor
class WorkoutStore: ObservableObject {
    
    // MARK: - Properties
    
    private let persistence: PersistenceProtocol
    private let progressiveOverloadService: ProgressiveOverloadServiceProtocol
    
    /// Cached exercise names to avoid recalculating on every call.
    private var _exerciseNamesCache: [String]?
    
    /// Cached weekly volume data to avoid recalculating on every access.
    private var _weeklyVolumeCache: [WeeklyVolumePoint]?
    
    /// The collection of workout plans defined by the user.
    ///
    /// Changes to this property are automatically persisted to storage.
    /// Each workout contains exercises with their target sets, reps, and weights.
    @Published var workouts: [Workout] {
        didSet {
            _exerciseNamesCache = nil
            saveWorkouts()
        }
    }
    
    /// The chronological log of completed workouts.
    ///
    /// Most recent workouts appear first. Changes are automatically persisted.
    /// Used for tracking progress, calculating progressive overload suggestions,
    /// and displaying workout history to the user.
    @Published var history: [WorkoutLog] {
        didSet {
            _exerciseNamesCache = nil
            _weeklyVolumeCache = nil
            saveHistory()
        }
    }
    
    /// The currently in-progress workout session, if any.
    ///
    /// When a user starts a workout, this property holds the live session state
    /// including elapsed time, rest timer state, and completed sets.
    /// Set to `nil` when no workout is active. Changes are automatically persisted
    /// to allow resuming workouts after app termination.
    @Published var activeWorkout: ActiveWorkout? {
        didSet {
            saveActiveWorkout()
        }
    }

    /// The user's current bodyweight in kilograms.
    ///
    /// Used for calculating relative strength and bodyweight-based exercises.
    /// Defaults to 70.0 kg if not previously set.
    @Published var bodyweight: Double {
        didSet {
            persistence.saveBodyweight(bodyweight)
        }
    }

    /// The smallest weight increment available at the user's gym, in kilograms.
    ///
    /// Used to round progressive overload suggestions to practical values.
    /// Defaults to 0.5 kg if not previously set.
    @Published var smallestWeightIncrement: Double {
        didSet {
            persistence.saveSmallestWeightIncrement(smallestWeightIncrement)
        }
    }
    
    // MARK: - Initialization

    init(
        persistence: PersistenceProtocol = UserDefaultsPersistenceManager(),
        progressiveOverloadService: ProgressiveOverloadServiceProtocol = ProgressiveOverloadService()
    ) {
        self.persistence = persistence
        self.progressiveOverloadService = progressiveOverloadService
        
        // Load workouts
        if let loadedWorkouts = persistence.loadWorkouts() {
            self.workouts = loadedWorkouts
        } else {
            self.workouts = Self.createPlaceholderWorkouts()
        }
        
        // Load history
        if let loadedHistory = persistence.loadHistory() {
            self.history = loadedHistory
        } else {
            self.history = []
        }
        
        // Load active workout if it exists
        if let decodedActiveWorkout = persistence.loadActiveWorkout() {
            // Update elapsed time based on current time
            var updatedWorkout = decodedActiveWorkout
            let currentTime = Date()
            let timeSinceStart = currentTime.timeIntervalSince(decodedActiveWorkout.startTime)
            updatedWorkout.totalElapsedTime = timeSinceStart
            
            // Check if rest period is still active
            if let restEndDate = decodedActiveWorkout.restEndDate {
                let timeRemaining = Int(round(restEndDate.timeIntervalSince(currentTime)))
                if timeRemaining > 0 {
                    updatedWorkout.restTimeRemaining = timeRemaining
                    updatedWorkout.isResting = true
                } else {
                    updatedWorkout.isResting = false
                    updatedWorkout.restEndDate = nil
                    updatedWorkout.restTimeRemaining = 0
                }
            } else {
                updatedWorkout.isResting = false
                updatedWorkout.restTimeRemaining = 0
            }
            
            self.activeWorkout = updatedWorkout
        } else {
            self.activeWorkout = nil
        }

        // Bodyweight
        self.bodyweight = persistence.loadBodyweight() ?? 70.0

        // Smallest weight increment (kg) used for rounding suggestions
        self.smallestWeightIncrement = persistence.loadSmallestWeightIncrement() ?? 0.5
    }
    
    // MARK: - Persistence

    private func saveWorkouts() {
        persistence.saveWorkouts(workouts)
    }
    
    private func saveHistory() {
        persistence.saveHistory(history)
    }
    
    private func saveActiveWorkout() {
        persistence.saveActiveWorkout(activeWorkout)
    }
    
    // MARK: - Active Workout Management
    
    /// Ends the current active workout session and clears all related state.
    ///
    /// This method sets `activeWorkout` to `nil` and terminates any associated
    /// Live Activities. Call this when a workout is completed or cancelled.
    func clearActiveWorkout() {
        activeWorkout = nil
        ActivityManager.endAllWorkoutsNow()
    }
    
    // MARK: - Helper Functions

    /// Returns a sorted list of all unique exercise names across all workout plans.
    ///
    /// Useful for autocomplete suggestions and exercise search functionality.
    /// Results are cached and invalidated when workouts or history changes.
    ///
    /// - Returns: An alphabetically sorted array of unique exercise names.
    func getAllExerciseNames() -> [String] {
        if let cached = _exerciseNamesCache {
            return cached
        }
        
        let allNames = workouts.flatMap { workout in
            workout.exercises.map { $0.name }
        }
        let uniqueNames = Array(Set(allNames)).sorted()
        _exerciseNamesCache = uniqueNames
        return uniqueNames
    }

    /// Returns weekly volume data for the last 8 weeks of workout history.
    ///
    /// Aggregates total volume (reps × weight) per week from completed workouts.
    /// Results are cached and invalidated when history changes.
    ///
    /// - Returns: An array of `WeeklyVolumePoint` sorted by week start date.
    func getWeeklyVolumeData() -> [WeeklyVolumePoint] {
        if let cached = _weeklyVolumeCache {
            return cached
        }
        
        guard !history.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: history) { log -> Date in
            calendar.dateInterval(of: .weekOfYear, for: log.date)?.start ?? calendar.startOfDay(for: log.date)
        }
        
        let points = grouped.map { weekStart, logs -> WeeklyVolumePoint in
            let totalVolume = logs.reduce(0.0) { logTotal, log in
                logTotal + log.completedExercises.reduce(0.0) { exerciseTotal, exercise in
                    exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                        setTotal + Double(set.reps) * set.weight
                    }
                }
            }
            return WeeklyVolumePoint(weekStart: weekStart, totalVolume: totalVolume)
        }
        
        let sortedPoints = points.sorted { $0.weekStart < $1.weekStart }
        let result = Array(sortedPoints.suffix(8))
        _weeklyVolumeCache = result
        return result
    }

    /// Returns the current day of the week as a `Weekday` enum value.
    ///
    /// Uses the system calendar to determine the current weekday.
    ///
    /// - Returns: The current weekday, defaulting to `.sunday` if determination fails.
    func getTodayWeekday() -> Weekday {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return Weekday(rawValue: weekday) ?? .sunday
    }

    /// Checks whether a workout is scheduled to be performed today.
    ///
    /// - Parameter workout: The workout to check.
    /// - Returns: `true` if today's weekday is in the workout's scheduled days.
    func isWorkoutScheduledForToday(_ workout: Workout) -> Bool {
        let today = getTodayWeekday()
        return workout.scheduledDays.contains(today)
    }
    
    // MARK: - CRUD Operations
    
    /// Adds a completed workout session to the history.
    ///
    /// The log is inserted at the beginning of the history array (most recent first).
    /// This triggers automatic persistence of the updated history.
    ///
    /// - Parameter log: The completed workout log to add.
    func addWorkoutLog(_ log: WorkoutLog) {
        history.insert(log, at: 0)
    }
    
    /// Updates a workout plan with modifications made during an active workout session.
    ///
    /// When a user modifies sets during a live workout (changing reps or weight),
    /// this method persists those changes back to the original workout plan.
    /// Only sets marked as `wasModified` are updated.
    ///
    /// - Parameters:
    ///   - liveSets: A dictionary mapping exercise IDs to their modified live sets.
    ///   - workoutID: The ID of the workout plan to update.
    func updateWorkoutPlan(from liveSets: [UUID: [LiveWorkoutSet]], for workoutID: UUID) {
        // Find the index of the workout we need to update
        guard let workoutIndex = workouts.firstIndex(where: { $0.id == workoutID }) else { return }
        
        // Iterate through all the exercises in that workout
        for exerciseIndex in 0..<workouts[workoutIndex].exercises.count {
            let exerciseID = workouts[workoutIndex].exercises[exerciseIndex].id
            
            // If we have live data for this exercise...
            if let exerciseLiveSets = liveSets[exerciseID] {
                // ...iterate through its sets
                for setIndex in 0..<workouts[workoutIndex].exercises[exerciseIndex].sets.count {
                    let setID = workouts[workoutIndex].exercises[exerciseIndex].sets[setIndex].id
                    
                    // Find the corresponding live set that was modified
                    if let modifiedSet = exerciseLiveSets.first(where: { $0.id == setID && $0.wasModified }) {
                        // Update the plan with the new values
                        workouts[workoutIndex].exercises[exerciseIndex].sets[setIndex].reps = modifiedSet.reps
                        workouts[workoutIndex].exercises[exerciseIndex].sets[setIndex].weight = modifiedSet.weight
                    }
                }
            }
        }
    }

    /// Adds a new exercise to an existing workout plan.
    ///
    /// Creates a new exercise with the specified name and sets, then appends it
    /// to the target workout. The exercise is automatically persisted.
    ///
    /// - Parameters:
    ///   - name: The name of the exercise to add.
    ///   - sets: The sets for the exercise. Defaults to a single empty set.
    ///   - workoutID: The ID of the workout to add the exercise to.
    /// - Returns: The newly created `Exercise`, or `nil` if the workout ID was not found.
    @discardableResult
    func addExercise(named name: String, sets: [WorkoutSet] = [WorkoutSet()], to workoutID: UUID) -> Exercise? {
        guard let index = workouts.firstIndex(where: { $0.id == workoutID }) else { return nil }
        let exercise = Exercise(name: name, sets: sets)
        workouts[index].exercises.append(exercise)
        return exercise
    }
    
    /// Removes all entries from the workout history.
    ///
    /// - Warning: This action is irreversible and clears all historical workout data.
    func clearHistory() {
        history.removeAll()
    }
    
    /// Retrieves the most recent feedback rating for a specific exercise.
    ///
    /// Searches through workout history to find the last time this exercise
    /// was performed and returns its associated feedback rating.
    ///
    /// - Parameter exerciseName: The name of the exercise to look up.
    /// - Returns: The most recent `FeedbackRating` for the exercise, or `nil` if not found.
    func getLastFeedback(for exerciseName: String) -> FeedbackRating? {
        for log in history {
            if let exercise = log.completedExercises.first(where: { $0.name == exerciseName }) {
                return exercise.feedback
            }
        }
        return nil
    }
    
    /// Returns all workout logs that include a specific exercise.
    ///
    /// Filters the complete workout history to find sessions where
    /// the specified exercise was performed.
    ///
    /// - Parameter exerciseName: The name of the exercise to filter by.
    /// - Returns: An array of `WorkoutLog` entries containing the exercise.
    func getHistory(for exerciseName: String) -> [WorkoutLog] {
        history.filter { log in
            log.completedExercises.contains(where: { $0.name == exerciseName })
        }
    }
    
    /// Removes all workout history entries that contain a specific exercise.
    ///
    /// - Warning: This permanently deletes all logs where the exercise appears.
    ///
    /// - Parameter exerciseName: The name of the exercise whose history should be deleted.
    func deleteHistory(for exerciseName: String) {
        history.removeAll { log in
            log.completedExercises.contains(where: { $0.name == exerciseName })
        }
    }
    
    // MARK: - Progressive Overload Functions
    
    /// Calculates a suggested weight increase for an exercise based on recent performance.
    ///
    /// Analyzes the user's workout history to determine an appropriate weight progression.
    /// The suggestion is rounded to the user's smallest available weight increment.
    ///
    /// - Parameter exerciseName: The name of the exercise to get suggestions for.
    /// - Returns: A tuple containing the suggested weight and percentage increase,
    ///   or `nil` if insufficient history exists for a recommendation.
    func getProgressiveOverloadSuggestion(for exerciseName: String) -> (suggestedWeight: Double?, percentageIncrease: Double?)? {
        guard let result = progressiveOverloadService.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestWeightIncrement
        ) else {
            return nil
        }
        return (suggestedWeight: result.suggestedWeight, percentageIncrease: result.percentageIncrease)
    }
    
    /// Determines whether an exercise should have a deload week based on recent performance.
    ///
    /// Evaluates the user's feedback history for signs of fatigue or overtraining,
    /// such as multiple consecutive sessions with negative feedback.
    ///
    /// - Parameter exerciseName: The name of the exercise to evaluate.
    /// - Returns: `true` if a deload is recommended, `false` otherwise.
    func shouldDeload(exerciseName: String) -> Bool {
        return progressiveOverloadService.shouldDeload(for: exerciseName, in: history)
    }
    
    /// Calculates the percentage improvement in weight over recent workouts for an exercise.
    ///
    /// Compares the average weight used in recent sessions to earlier sessions
    /// to quantify progress over time.
    ///
    /// - Parameters:
    ///   - exerciseName: The name of the exercise to analyze.
    ///   - workoutCount: The number of recent workouts to consider. Defaults to 4.
    /// - Returns: The percentage improvement, or `nil` if insufficient history exists.
    func getImprovementPercentage(for exerciseName: String, overLast workoutCount: Int = 4) -> Double? {
        return progressiveOverloadService.getImprovementPercentage(
            for: exerciseName,
            in: history,
            overLast: workoutCount
        )
    }
    
    // MARK: - Placeholder Data
    
    /// Creates a set of sample workout plans for new users.
    ///
    /// Used to populate the app with example workouts when no saved data exists.
    /// Includes a "Full Body Strength A" and "Push Day" workout with sample exercises.
    ///
    /// - Returns: An array of pre-configured `Workout` objects.
    static func createPlaceholderWorkouts() -> [Workout] {
        return [
            Workout(name: "Full Body Strength A", exercises: [
                Exercise(name: "Squat", sets: [
                    WorkoutSet(reps: 5, weight: 135, restTimeInSeconds: 90),
                    WorkoutSet(reps: 5, weight: 135, restTimeInSeconds: 90),
                    WorkoutSet(reps: 5, weight: 135, restTimeInSeconds: 90)
                ]),
                Exercise(name: "Bench Press", sets: [
                    WorkoutSet(reps: 8, weight: 100, restTimeInSeconds: 60),
                    WorkoutSet(reps: 8, weight: 100, restTimeInSeconds: 60)
                ]),
                Exercise(name: "Barbell Row", sets: [
                    WorkoutSet(reps: 8, weight: 95, restTimeInSeconds: 60),
                    WorkoutSet(reps: 8, weight: 95, restTimeInSeconds: 60)
                ])
            ], scheduledDays: [.monday, .wednesday, .friday]),
            Workout(name: "Push Day", exercises: [
                Exercise(name: "Overhead Press", sets: [WorkoutSet()]),
                Exercise(name: "Incline Dumbbell Press", sets: [WorkoutSet()]),
            ], scheduledDays: [.tuesday, .thursday])
        ]
    }
}

