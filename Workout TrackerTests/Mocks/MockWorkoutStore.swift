// MockWorkoutStore.swift

import Foundation
@testable import Workout_Tracker

// MARK: - Mock Data Factory

/// Factory for creating mock workout data for tests and previews.
/// Provides consistent, realistic sample data that covers common use cases.
enum MockWorkoutData {
    
    // MARK: - Sample Workouts
    
    static var sampleWorkouts: [Workout] {
        [
            Workout(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                name: "Push Day",
                exercises: [
                    Exercise(
                        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                        name: "Bench Press",
                        sets: [
                            WorkoutSet(reps: 8, weight: 80, restTimeInSeconds: 90),
                            WorkoutSet(reps: 8, weight: 80, restTimeInSeconds: 90),
                            WorkoutSet(reps: 8, weight: 80, restTimeInSeconds: 90)
                        ]
                    ),
                    Exercise(
                        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                        name: "Overhead Press",
                        sets: [
                            WorkoutSet(reps: 10, weight: 40, restTimeInSeconds: 60),
                            WorkoutSet(reps: 10, weight: 40, restTimeInSeconds: 60),
                            WorkoutSet(reps: 10, weight: 40, restTimeInSeconds: 60)
                        ]
                    ),
                    Exercise(
                        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
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
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                name: "Pull Day",
                exercises: [
                    Exercise(
                        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
                        name: "Deadlift",
                        sets: [
                            WorkoutSet(reps: 5, weight: 120, restTimeInSeconds: 120),
                            WorkoutSet(reps: 5, weight: 120, restTimeInSeconds: 120),
                            WorkoutSet(reps: 5, weight: 120, restTimeInSeconds: 120)
                        ]
                    ),
                    Exercise(
                        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
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
                id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
                name: "Leg Day",
                exercises: [
                    Exercise(
                        id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
                        name: "Squat",
                        sets: [
                            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120),
                            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120),
                            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120)
                        ]
                    ),
                    Exercise(
                        id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
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
            // Most recent workout - 1 day ago
            WorkoutLog(
                id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                workoutName: "Push Day",
                duration: 3600, // 1 hour
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
            
            // 3 days ago
            WorkoutLog(
                id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
                date: calendar.date(byAdding: .day, value: -3, to: now)!,
                workoutName: "Pull Day",
                duration: 2700, // 45 min
                completedExercises: [
                    CompletedExercise(
                        name: "Deadlift",
                        sets: [
                            CompletedSet(reps: 5, weight: 120),
                            CompletedSet(reps: 5, weight: 120),
                            CompletedSet(reps: 5, weight: 120)
                        ],
                        feedback: .hard
                    ),
                    CompletedExercise(
                        name: "Pull-ups",
                        sets: [
                            CompletedSet(reps: 8, weight: 0),
                            CompletedSet(reps: 7, weight: 0),
                            CompletedSet(reps: 6, weight: 0)
                        ],
                        feedback: .veryHard
                    )
                ]
            ),
            
            // 5 days ago
            WorkoutLog(
                id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
                date: calendar.date(byAdding: .day, value: -5, to: now)!,
                workoutName: "Leg Day",
                duration: 3300, // 55 min
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
            ),
            
            // 1 week ago
            WorkoutLog(
                id: UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!,
                date: calendar.date(byAdding: .day, value: -7, to: now)!,
                workoutName: "Push Day",
                duration: 3500,
                completedExercises: [
                    CompletedExercise(
                        name: "Bench Press",
                        sets: [
                            CompletedSet(reps: 8, weight: 77.5),
                            CompletedSet(reps: 8, weight: 77.5),
                            CompletedSet(reps: 8, weight: 77.5)
                        ],
                        feedback: .easy
                    )
                ]
            )
        ]
    }
    
    // MARK: - Sample Active Workout
    
    static var sampleActiveWorkout: ActiveWorkout {
        let workout = sampleWorkouts[0] // Push Day
        
        var liveSetsByExercise: [UUID: [LiveWorkoutSet]] = [:]
        for exercise in workout.exercises {
            liveSetsByExercise[exercise.id] = exercise.sets.enumerated().map { index, set in
                LiveWorkoutSet(
                    id: set.id,
                    reps: set.reps,
                    weight: set.weight,
                    restTimeInSeconds: set.restTimeInSeconds,
                    isCompleted: index == 0 // First set completed
                )
            }
        }
        
        return ActiveWorkout(
            workoutID: workout.id,
            workoutName: workout.name,
            startTime: Date().addingTimeInterval(-600), // Started 10 min ago
            totalElapsedTime: 600,
            liveSetsByExercise: liveSetsByExercise,
            exerciseFeedback: [:],
            isResting: true,
            restEndDate: Date().addingTimeInterval(30), // 30 sec rest remaining
            restTimeRemaining: 30
        )
    }
}

// MARK: - WorkoutStore Preview Extension

extension WorkoutStore {
    
    /// Creates a WorkoutStore configured for SwiftUI Previews.
    /// Uses in-memory storage and pre-populated mock data.
    /// Does NOT persist any changes.
    @MainActor
    static var preview: WorkoutStore {
        let mockPersistence = MockPersistenceManager(
            workouts: MockWorkoutData.sampleWorkouts,
            history: MockWorkoutData.sampleHistory,
            bodyweight: 75.0,
            smallestWeightIncrement: 2.5
        )
        return WorkoutStore(persistence: mockPersistence)
    }
    
    /// Creates a WorkoutStore with an active workout in progress.
    /// Useful for previewing active workout views.
    @MainActor
    static var previewWithActiveWorkout: WorkoutStore {
        let mockPersistence = MockPersistenceManager(
            workouts: MockWorkoutData.sampleWorkouts,
            history: MockWorkoutData.sampleHistory,
            activeWorkout: MockWorkoutData.sampleActiveWorkout,
            bodyweight: 75.0,
            smallestWeightIncrement: 2.5
        )
        return WorkoutStore(persistence: mockPersistence)
    }
    
    /// Creates an empty WorkoutStore for testing fresh user state.
    @MainActor
    static var previewEmpty: WorkoutStore {
        let mockPersistence = MockPersistenceManager()
        return WorkoutStore(persistence: mockPersistence)
    }
    
    /// Creates a WorkoutStore with only history data.
    /// Useful for testing history-related views.
    @MainActor
    static var previewHistoryOnly: WorkoutStore {
        let mockPersistence = MockPersistenceManager(
            workouts: [],
            history: MockWorkoutData.sampleHistory,
            bodyweight: 80.0,
            smallestWeightIncrement: 1.25
        )
        return WorkoutStore(persistence: mockPersistence)
    }
}
