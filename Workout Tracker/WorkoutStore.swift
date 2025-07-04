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

    private let workoutsKey = "workoutStore_workouts"
    private let historyKey = "workoutStore_history"
    private let activeWorkoutKey = "workoutStore_activeWorkout"

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
    
    // MARK: - Placeholder Data
    static func createPlaceholderWorkouts() -> [Workout] {
        // ... (placeholder data is unchanged) ...
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
