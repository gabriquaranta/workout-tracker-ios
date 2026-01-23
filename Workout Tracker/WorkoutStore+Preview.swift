//
//  WorkoutStore+Preview.swift
//  Workout Tracker
//

import Foundation

#if DEBUG

// MARK: - Preview Data Factory

/// Factory for creating mock workout data for SwiftUI Previews.
/// Only available in DEBUG builds to prevent inclusion in release builds.
enum PreviewMockData {
    
    // MARK: - Sample Workouts
    
    static var sampleWorkouts: [Workout] {
        [
            Workout(
                name: "Push Day",
                exercises: [
                    Exercise(
                        name: "Bench Press",
                        sets: [
                            WorkoutSet(reps: 8, weight: 80, restTimeInSeconds: 90),
                            WorkoutSet(reps: 8, weight: 80, restTimeInSeconds: 90),
                            WorkoutSet(reps: 8, weight: 80, restTimeInSeconds: 90)
                        ]
                    ),
                    Exercise(
                        name: "Overhead Press",
                        sets: [
                            WorkoutSet(reps: 10, weight: 40, restTimeInSeconds: 60),
                            WorkoutSet(reps: 10, weight: 40, restTimeInSeconds: 60),
                            WorkoutSet(reps: 10, weight: 40, restTimeInSeconds: 60)
                        ]
                    ),
                    Exercise(
                        name: "Tricep Dips",
                        sets: [
                            WorkoutSet(reps: 12, weight: 0, restTimeInSeconds: 45),
                            WorkoutSet(reps: 12, weight: 0, restTimeInSeconds: 45)
                        ]
                    )
                ],
                scheduledDays: [.monday, .thursday]
            ),
            Workout(
                name: "Pull Day",
                exercises: [
                    Exercise(
                        name: "Deadlift",
                        sets: [
                            WorkoutSet(reps: 5, weight: 120, restTimeInSeconds: 120),
                            WorkoutSet(reps: 5, weight: 120, restTimeInSeconds: 120),
                            WorkoutSet(reps: 5, weight: 120, restTimeInSeconds: 120)
                        ]
                    ),
                    Exercise(
                        name: "Pull-ups",
                        sets: [
                            WorkoutSet(reps: 8, weight: 0, restTimeInSeconds: 60),
                            WorkoutSet(reps: 8, weight: 0, restTimeInSeconds: 60),
                            WorkoutSet(reps: 8, weight: 0, restTimeInSeconds: 60)
                        ]
                    )
                ],
                scheduledDays: [.tuesday, .friday]
            ),
            Workout(
                name: "Leg Day",
                exercises: [
                    Exercise(
                        name: "Squat",
                        sets: [
                            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120),
                            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120),
                            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120)
                        ]
                    ),
                    Exercise(
                        name: "Leg Press",
                        sets: [
                            WorkoutSet(reps: 10, weight: 150, restTimeInSeconds: 90),
                            WorkoutSet(reps: 10, weight: 150, restTimeInSeconds: 90)
                        ]
                    )
                ],
                scheduledDays: [.wednesday, .saturday]
            )
        ]
    }
    
    // MARK: - Sample History
    
    static var sampleHistory: [WorkoutLog] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            WorkoutLog(
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                workoutName: "Push Day",
                duration: 3600,
                completedExercises: [
                    CompletedExercise(
                        name: "Bench Press",
                        sets: [
                            CompletedSet(reps: 8, weight: 80),
                            CompletedSet(reps: 8, weight: 80),
                            CompletedSet(reps: 7, weight: 80)
                        ],
                        feedback: .moderate
                    ),
                    CompletedExercise(
                        name: "Overhead Press",
                        sets: [
                            CompletedSet(reps: 10, weight: 40),
                            CompletedSet(reps: 10, weight: 40),
                            CompletedSet(reps: 9, weight: 40)
                        ],
                        feedback: .easy
                    )
                ],
                notes: "Felt strong today!"
            ),
            WorkoutLog(
                date: calendar.date(byAdding: .day, value: -3, to: now)!,
                workoutName: "Pull Day",
                duration: 2700,
                completedExercises: [
                    CompletedExercise(
                        name: "Deadlift",
                        sets: [
                            CompletedSet(reps: 5, weight: 120),
                            CompletedSet(reps: 5, weight: 120),
                            CompletedSet(reps: 5, weight: 120)
                        ],
                        feedback: .hard
                    )
                ]
            ),
            WorkoutLog(
                date: calendar.date(byAdding: .day, value: -5, to: now)!,
                workoutName: "Leg Day",
                duration: 3300,
                completedExercises: [
                    CompletedExercise(
                        name: "Squat",
                        sets: [
                            CompletedSet(reps: 5, weight: 100),
                            CompletedSet(reps: 5, weight: 100),
                            CompletedSet(reps: 5, weight: 100)
                        ],
                        feedback: .moderate
                    )
                ]
            )
        ]
    }
}

// MARK: - In-Memory Preview Persistence

/// A minimal in-memory persistence manager for SwiftUI Previews.
/// Does not persist any data - all changes are discarded.
final class PreviewPersistenceManager: PersistenceProtocol {
    
    private var workouts: [Workout]?
    private var history: [WorkoutLog]?
    private var activeWorkout: ActiveWorkout?
    private var bodyweight: Double?
    private var smallestWeightIncrement: Double?
    private var theme: String?
    
    init(
        workouts: [Workout]? = nil,
        history: [WorkoutLog]? = nil,
        activeWorkout: ActiveWorkout? = nil,
        bodyweight: Double? = nil,
        smallestWeightIncrement: Double? = nil
    ) {
        self.workouts = workouts
        self.history = history
        self.activeWorkout = activeWorkout
        self.bodyweight = bodyweight
        self.smallestWeightIncrement = smallestWeightIncrement
    }
    
    func saveWorkouts(_ workouts: [Workout]) { self.workouts = workouts }
    func loadWorkouts() -> [Workout]? { workouts }
    
    func saveHistory(_ history: [WorkoutLog]) { self.history = history }
    func loadHistory() -> [WorkoutLog]? { history }
    
    func saveActiveWorkout(_ activeWorkout: ActiveWorkout?) { self.activeWorkout = activeWorkout }
    func loadActiveWorkout() -> ActiveWorkout? { activeWorkout }
    
    func saveBodyweight(_ bodyweight: Double) { self.bodyweight = bodyweight }
    func loadBodyweight() -> Double? { bodyweight }
    
    func saveSmallestWeightIncrement(_ increment: Double) { self.smallestWeightIncrement = increment }
    func loadSmallestWeightIncrement() -> Double? { smallestWeightIncrement }
    
    func saveTheme(_ theme: String) { self.theme = theme }
    func loadTheme() -> String? { theme }
}

// MARK: - WorkoutStore Preview Extension

extension WorkoutStore {
    
    /// A fully configured WorkoutStore for SwiftUI Previews.
    /// Contains sample workouts, history, and user settings.
    @MainActor
    static var preview: WorkoutStore {
        let persistence = PreviewPersistenceManager(
            workouts: PreviewMockData.sampleWorkouts,
            history: PreviewMockData.sampleHistory,
            bodyweight: 75.0,
            smallestWeightIncrement: 2.5
        )
        return WorkoutStore(persistence: persistence)
    }
    
    /// A WorkoutStore with an active workout in progress.
    @MainActor
    static var previewWithActiveWorkout: WorkoutStore {
        let workout = PreviewMockData.sampleWorkouts[0]
        
        var liveSetsByExercise: [UUID: [LiveWorkoutSet]] = [:]
        for exercise in workout.exercises {
            liveSetsByExercise[exercise.id] = exercise.sets.enumerated().map { index, set in
                LiveWorkoutSet(
                    id: set.id,
                    reps: set.reps,
                    weight: set.weight,
                    restTimeInSeconds: set.restTimeInSeconds,
                    isCompleted: index == 0
                )
            }
        }
        
        let activeWorkout = ActiveWorkout(
            workoutID: workout.id,
            workoutName: workout.name,
            startTime: Date().addingTimeInterval(-600),
            totalElapsedTime: 600,
            liveSetsByExercise: liveSetsByExercise,
            exerciseFeedback: [:],
            isResting: true,
            restEndDate: Date().addingTimeInterval(30),
            restTimeRemaining: 30
        )
        
        let persistence = PreviewPersistenceManager(
            workouts: PreviewMockData.sampleWorkouts,
            history: PreviewMockData.sampleHistory,
            activeWorkout: activeWorkout,
            bodyweight: 75.0,
            smallestWeightIncrement: 2.5
        )
        return WorkoutStore(persistence: persistence)
    }
    
    /// An empty WorkoutStore for testing first-run experiences.
    @MainActor
    static var previewEmpty: WorkoutStore {
        let persistence = PreviewPersistenceManager()
        return WorkoutStore(persistence: persistence)
    }
}

#endif
