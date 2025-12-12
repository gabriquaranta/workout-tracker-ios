// WorkoutStore.swift

import SwiftUI
import Combine

class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] {
        didSet {
            saveWorkouts()
        }
    }
    
    @Published var history: [WorkoutLog] {
        didSet {
            saveHistory()
        }
    }
    
    @Published var activeWorkout: ActiveWorkout? {
        didSet {
            saveActiveWorkout()
        }
    }

    @Published var bodyweight: Double {
        didSet {
            UserDefaults.standard.set(bodyweight, forKey: "bodyweight")
        }
    }

    @Published var smallestWeightIncrement: Double {
        didSet {
            UserDefaults.standard.set(smallestWeightIncrement, forKey: "smallestWeightIncrement")
        }
    }

    private let workoutsKey = "workoutStore_workouts"
    private let historyKey = "workoutStore_history"
    private let activeWorkoutKey = "workoutStore_activeWorkout"

    private enum OverloadConstants {
        static let minWorkoutsForSuggestion = 3
        static let minRatedWorkoutsForSuggestion = 2
        static let goodFeedbackThreshold = 0.6
        static let excellentFeedbackThreshold = 0.8
        static let moderateIncrease = 0.025
        static let aggressiveIncrease = 0.05
        static let stagnationTolerance = 0.05
        static let stagnationWindow: TimeInterval = 28 * 24 * 60 * 60
        static let highFrequencyWindow: TimeInterval = 21 * 24 * 60 * 60
        static let highFrequencyThreshold = 21
        static let recentFeedbackSample = 3
        static let poorFeedbackFractionThreshold = 0.5
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: workoutsKey) {
            if let decodedWorkouts = try? JSONDecoder().decode([Workout].self, from: data) {
                self.workouts = decodedWorkouts
            } else {
                self.workouts = Self.createPlaceholderWorkouts()
            }
        } else {
            self.workouts = Self.createPlaceholderWorkouts()
        }
        
        if let data = UserDefaults.standard.data(forKey: historyKey) {
            if let decodedHistory = try? JSONDecoder().decode([WorkoutLog].self, from: data) {
                self.history = decodedHistory
            } else {
                self.history = []
            }
        } else {
            self.history = []
        }
        
        // load active workout if it exists
        if let data = UserDefaults.standard.data(forKey: activeWorkoutKey) {
            if let decodedActiveWorkout = try? JSONDecoder().decode(ActiveWorkout.self, from: data) {
                // update elapsed time based on current time
                var updatedWorkout = decodedActiveWorkout
                let currentTime = Date()
                let timeSinceStart = currentTime.timeIntervalSince(decodedActiveWorkout.startTime)
                updatedWorkout.totalElapsedTime = timeSinceStart
                
                // check if rest period is still active
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
        } else {
            self.activeWorkout = nil
        }

        // bodyweight
        let savedBodyweight = UserDefaults.standard.object(forKey: "bodyweight") as? Double
        self.bodyweight = savedBodyweight ?? 70.0

        // smallest weight increment (kg) used for rounding suggestions
        let savedIncrement = UserDefaults.standard.object(forKey: "smallestWeightIncrement") as? Double
        self.smallestWeightIncrement = savedIncrement ?? 0.5
    }

    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: workoutsKey)
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func saveActiveWorkout() {
        if let activeWorkout = activeWorkout {
            if let encoded = try? JSONEncoder().encode(activeWorkout) {
                UserDefaults.standard.set(encoded, forKey: activeWorkoutKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: activeWorkoutKey)
        }
    }
    
    func clearActiveWorkout() {
        activeWorkout = nil
        ActivityManager.endAllWorkoutsNow()
    }

    func getAllExerciseNames() -> [String] {
        let allNames = workouts.flatMap { workout in
            workout.exercises.map { $0.name }
        }
        let uniqueNames = Array(Set(allNames)).sorted()
        print("All exercise names found: \(uniqueNames)")
        return uniqueNames
    }

    func getTodayWeekday() -> Weekday {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return Weekday(rawValue: weekday) ?? .sunday
    }

    func isWorkoutScheduledForToday(_ workout: Workout) -> Bool {
        let today = getTodayWeekday()
        return workout.scheduledDays.contains(today)
    }

    // MARK: - Helper Functions
    
    func addWorkoutLog(_ log: WorkoutLog) {
        history.insert(log, at: 0)
    }
    
    // NEW: Function to save changes from a workout back to the plan
    func updateWorkoutPlan(from liveSets: [UUID: [LiveWorkoutSet]], for workoutID: UUID) {
        // Find the index of the workout we need to update
        guard let workoutIndex = workouts.firstIndex(where: { $0.id == workoutID }) else { return }
        
        // Iterate through all the exercises in that workout
        for i in 0..<workouts[workoutIndex].exercises.count {
            let exerciseID = workouts[workoutIndex].exercises[i].id
            
            // If we have live data for this exercise...
            if let exerciseLiveSets = liveSets[exerciseID] {
                // ...iterate through its sets
                for j in 0..<workouts[workoutIndex].exercises[i].sets.count {
                    let setID = workouts[workoutIndex].exercises[i].sets[j].id
                    
                    // Find the corresponding live set that was modified
                    if let modifiedSet = exerciseLiveSets.first(where: { $0.id == setID && $0.wasModified }) {
                        // Update the plan with the new values
                        workouts[workoutIndex].exercises[i].sets[j].reps = modifiedSet.reps
                        workouts[workoutIndex].exercises[i].sets[j].weight = modifiedSet.weight
                    }
                }
            }
        }
    }
    
    func clearHistory() {
        history.removeAll()
    }
    
    func getLastFeedback(for exerciseName: String) -> FeedbackRating? {
        for log in history {
            if let exercise = log.completedExercises.first(where: { $0.name == exerciseName }) {
                return exercise.feedback
            }
        }
        return nil
    }
    
    func getHistory(for exerciseName: String) -> [WorkoutLog] {
        history.filter { log in
            log.completedExercises.contains(where: { $0.name == exerciseName })
        }
    }
    
    // remove all history entries containing a given exercise name
    func deleteHistory(for exerciseName: String) {
        history.removeAll { log in
            log.completedExercises.contains(where: { $0.name == exerciseName })
        }
    }
    
    // MARK: - Progressive Overload Functions
    
    /// Returns a suggested weight increase for an exercise based on recent performance
    func getProgressiveOverloadSuggestion(for exerciseName: String) -> (suggestedWeight: Double?, percentageIncrease: Double?)? {
        let exerciseHistory = getHistory(for: exerciseName)
        
        // Need at least a baseline number of workouts to make a suggestion
        guard exerciseHistory.count >= OverloadConstants.minWorkoutsForSuggestion else { return nil }
        
        // Get last 4 workouts, sorted by date (most recent first)
        let recentWorkouts = exerciseHistory.sorted(by: { $0.date > $1.date }).prefix(4)
        
        // Check if user has been consistently completing sets with good feedback
        var ratedWorkoutsCount = 0
        var positiveFeedbackCount = 0
        
        for workout in recentWorkouts {
            if let exercise = workout.completedExercises.first(where: { $0.name == exerciseName }),
               let feedback = exercise.feedback {
                ratedWorkoutsCount += 1
                if feedback == .veryEasy || feedback == .easy || feedback == .moderate {
                    positiveFeedbackCount += 1
                }
            }
        }

        guard ratedWorkoutsCount >= OverloadConstants.minRatedWorkoutsForSuggestion else { return nil }
        
        let goodFeedbackRatio = Double(positiveFeedbackCount) / Double(ratedWorkoutsCount)
        guard goodFeedbackRatio >= OverloadConstants.goodFeedbackThreshold else { return nil }
        
        // Get the maximum weight used in the most recent workout
        guard let mostRecentWorkout = recentWorkouts.first,
              let mostRecentExercise = mostRecentWorkout.completedExercises.first(where: { $0.name == exerciseName }),
              let maxRecentWeight = mostRecentExercise.sets.map({ $0.weight }).max() else {
            return nil
        }

                guard maxRecentWeight > 0 else { return nil }
        
        // Check if weight has increased in the last 2 workouts
        let lastTwoWorkouts = recentWorkouts.prefix(2)
        var hasRecentIncrease = false
        
        if lastTwoWorkouts.count == 2 {
            let workout1 = lastTwoWorkouts.first!
            let workout2 = lastTwoWorkouts.last!
            
            if let exercise1 = workout1.completedExercises.first(where: { $0.name == exerciseName }),
               let exercise2 = workout2.completedExercises.first(where: { $0.name == exerciseName }),
               let maxWeight1 = exercise1.sets.map({ $0.weight }).max(),
               let maxWeight2 = exercise2.sets.map({ $0.weight }).max() {
                hasRecentIncrease = maxWeight1 > maxWeight2
            }
        }
        
        // Don't suggest increase if weight was just increased
        if hasRecentIncrease {
            return nil
        }
        
        // Suggest 2.5-5% increase based on consistency
        let increasePercentage = goodFeedbackRatio >= OverloadConstants.excellentFeedbackThreshold ?
            OverloadConstants.aggressiveIncrease :
            OverloadConstants.moderateIncrease
        
        let rawSuggestedWeight = maxRecentWeight * (1 + increasePercentage)

        // Round up to the nearest multiple of smallestWeightIncrement
        let increment = max(0.0001, smallestWeightIncrement) // guard against zero
        let roundedSuggestedWeight = (rawSuggestedWeight / increment).rounded(.up) * increment

        // Skip if rounding does not actually increase the weight
        if roundedSuggestedWeight <= maxRecentWeight + 0.0001 {
            return nil
        }

        let roundedIncreasePercentage = (roundedSuggestedWeight - maxRecentWeight) / maxRecentWeight

        return (suggestedWeight: roundedSuggestedWeight, percentageIncrease: roundedIncreasePercentage)
    }
    
    /// Determines if an exercise should have a deload week based on recent performance
    func shouldDeload(exerciseName: String) -> Bool {
        let exerciseHistory = getHistory(for: exerciseName)
        
        // Need some history to determine deload needs
        guard exerciseHistory.count >= 4 else { return false }

        // Check for poor feedback first (required for deload suggestion)
        let recentFeedback = exerciseHistory
            .sorted(by: { $0.date > $1.date })
            .prefix(OverloadConstants.recentFeedbackSample)
            .compactMap { workout -> FeedbackRating? in
                workout.completedExercises.first(where: { $0.name == exerciseName })?.feedback
            }

        let hasPoorFeedback: Bool = {
            guard recentFeedback.count >= 2 else { return false }
            let poorFeedbackCount = recentFeedback.filter { $0 == .hard || $0 == .veryHard }.count
            return Double(poorFeedbackCount) / Double(recentFeedback.count) >= OverloadConstants.poorFeedbackFractionThreshold
        }()

        // 1. No progress in 4+ weeks AND poor feedback
        let fourWeeksAgo = Date().addingTimeInterval(-OverloadConstants.stagnationWindow)
        let progressWindow = exerciseHistory.filter { $0.date > fourWeeksAgo }

        if progressWindow.count >= 4 && hasPoorFeedback {
            let sortedProgress = progressWindow.sorted(by: { $0.date < $1.date })
            if let firstWorkout = sortedProgress.first,
               let lastWorkout = sortedProgress.last,
               let firstExercise = firstWorkout.completedExercises.first(where: { $0.name == exerciseName }),
               let lastExercise = lastWorkout.completedExercises.first(where: { $0.name == exerciseName }),
               let firstMaxWeight = firstExercise.sets.map({ $0.weight }).max(),
               let lastMaxWeight = lastExercise.sets.map({ $0.weight }).max() {
                if lastMaxWeight <= firstMaxWeight * (1 + OverloadConstants.stagnationTolerance) {
                    return true
                }
            }
        }

        // 2. High workout frequency AND poor feedback
        let threeWeeksAgo = Date().addingTimeInterval(-OverloadConstants.highFrequencyWindow)
        let highFrequencyWorkouts = exerciseHistory.filter { $0.date > threeWeeksAgo }

        if highFrequencyWorkouts.count >= OverloadConstants.highFrequencyThreshold && hasPoorFeedback {
            return true
        }

        return false
    }
    
    /// Calculates the percentage improvement over the last N workouts for an exercise
    func getImprovementPercentage(for exerciseName: String, overLast workoutCount: Int = 4) -> Double? {
        let exerciseHistory = getHistory(for: exerciseName)
        
        guard exerciseHistory.count >= workoutCount else { return nil }
        
        let sortedWorkouts = exerciseHistory.sorted(by: { $0.date > $1.date })
        let recentWorkouts = sortedWorkouts.prefix(workoutCount)
        
        guard let oldestWorkout = recentWorkouts.last,
              let newestWorkout = recentWorkouts.first,
              let oldestExercise = oldestWorkout.completedExercises.first(where: { $0.name == exerciseName }),
              let newestExercise = newestWorkout.completedExercises.first(where: { $0.name == exerciseName }),
              let oldestMaxWeight = oldestExercise.sets.map({ $0.weight }).max(),
              let newestMaxWeight = newestExercise.sets.map({ $0.weight }).max(),
              oldestMaxWeight > 0 else {
            return nil
        }
        
        let improvement = ((newestMaxWeight - oldestMaxWeight) / oldestMaxWeight) * 100
        return improvement
    }
    
    // MARK: - Placeholder Data
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

