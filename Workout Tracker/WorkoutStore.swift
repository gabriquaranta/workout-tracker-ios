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

    private let workoutsKey = "workoutStore_workouts"
    private let historyKey = "workoutStore_history"

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

    // MARK: - Helper Functions
    
    func addWorkoutLog(_ log: WorkoutLog) {
        history.insert(log, at: 0)
    }
    
    // NEW: Function to clear only the workout history.
    func clearHistory() {
        history.removeAll()
        // The didSet property observer on `history` will automatically call saveHistory().
    }
    
    func getLastPerformance(for exerciseName: String) -> CompletedSet? {
        for log in history {
            if let exercise = log.completedExercises.first(where: { $0.name == exerciseName }),
               let lastSet = exercise.sets.last {
                return lastSet
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
            ]),
            Workout(name: "Push Day", exercises: [
                Exercise(name: "Overhead Press", sets: [WorkoutSet()]),
                Exercise(name: "Incline Dumbbell Press", sets: [WorkoutSet()]),
            ])
        ]
    }
}
