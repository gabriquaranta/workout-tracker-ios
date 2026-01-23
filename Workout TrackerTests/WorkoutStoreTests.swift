// WorkoutStoreTests.swift

import Testing
import Foundation
@testable import Workout_Tracker

// MARK: - Mock Persistence Manager

/// Mock implementation of PersistenceProtocol for testing purposes.
/// Stores all data in memory and tracks save/load operations.
final class MockPersistenceManager: PersistenceProtocol {
    
    // MARK: - Stored Data
    
    var workouts: [Workout]?
    var history: [WorkoutLog]?
    var activeWorkout: ActiveWorkout?
    var bodyweight: Double?
    var smallestWeightIncrement: Double?
    var theme: String?
    
    // MARK: - Call Tracking
    
    var saveWorkoutsCalled = false
    var loadWorkoutsCalled = false
    var saveHistoryCalled = false
    var loadHistoryCalled = false
    var saveActiveWorkoutCalled = false
    var loadActiveWorkoutCalled = false
    var saveBodyweightCalled = false
    var loadBodyweightCalled = false
    var saveSmallestWeightIncrementCalled = false
    var loadSmallestWeightIncrementCalled = false
    var saveThemeCalled = false
    var loadThemeCalled = false
    
    // MARK: - Initialization
    
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
    
    // MARK: - Reset Tracking
    
    func resetTracking() {
        saveWorkoutsCalled = false
        loadWorkoutsCalled = false
        saveHistoryCalled = false
        loadHistoryCalled = false
        saveActiveWorkoutCalled = false
        loadActiveWorkoutCalled = false
        saveBodyweightCalled = false
        loadBodyweightCalled = false
        saveSmallestWeightIncrementCalled = false
        loadSmallestWeightIncrementCalled = false
        saveThemeCalled = false
        loadThemeCalled = false
    }
    
    // MARK: - PersistenceProtocol Implementation
    
    func saveWorkouts(_ workouts: [Workout]) {
        saveWorkoutsCalled = true
        self.workouts = workouts
    }
    
    func loadWorkouts() -> [Workout]? {
        loadWorkoutsCalled = true
        return workouts
    }
    
    func saveHistory(_ history: [WorkoutLog]) {
        saveHistoryCalled = true
        self.history = history
    }
    
    func loadHistory() -> [WorkoutLog]? {
        loadHistoryCalled = true
        return history
    }
    
    func saveActiveWorkout(_ activeWorkout: ActiveWorkout?) {
        saveActiveWorkoutCalled = true
        self.activeWorkout = activeWorkout
    }
    
    func loadActiveWorkout() -> ActiveWorkout? {
        loadActiveWorkoutCalled = true
        return activeWorkout
    }
    
    func saveBodyweight(_ bodyweight: Double) {
        saveBodyweightCalled = true
        self.bodyweight = bodyweight
    }
    
    func loadBodyweight() -> Double? {
        loadBodyweightCalled = true
        return bodyweight
    }
    
    func saveSmallestWeightIncrement(_ increment: Double) {
        saveSmallestWeightIncrementCalled = true
        self.smallestWeightIncrement = increment
    }
    
    func loadSmallestWeightIncrement() -> Double? {
        loadSmallestWeightIncrementCalled = true
        return smallestWeightIncrement
    }
    
    func saveTheme(_ theme: String) {
        saveThemeCalled = true
        self.theme = theme
    }
    
    func loadTheme() -> String? {
        loadThemeCalled = true
        return theme
    }
}

// MARK: - Mock Progressive Overload Service

/// Mock implementation of ProgressiveOverloadServiceProtocol for testing purposes.
final class MockProgressiveOverloadService: ProgressiveOverloadServiceProtocol {
    
    var suggestionToReturn: (suggestedWeight: Double, percentageIncrease: Double)?
    var shouldDeloadResult = false
    var improvementPercentage: Double?
    
    func getProgressiveOverloadSuggestion(
        for exerciseName: String,
        in history: [WorkoutLog],
        smallestWeightIncrement: Double
    ) -> (suggestedWeight: Double, percentageIncrease: Double)? {
        return suggestionToReturn
    }
    
    func shouldDeload(for exerciseName: String, in history: [WorkoutLog]) -> Bool {
        return shouldDeloadResult
    }
    
    func getImprovementPercentage(
        for exerciseName: String,
        in history: [WorkoutLog],
        overLast workoutCount: Int
    ) -> Double? {
        return improvementPercentage
    }
}

// MARK: - WorkoutStore Tests

@MainActor
struct WorkoutStoreTests {
    
    // MARK: - Helper Functions
    
    /// Creates a sample workout for testing.
    private func createSampleWorkout(
        name: String = "Test Workout",
        exercises: [Exercise]? = nil
    ) -> Workout {
        let defaultExercises = [
            Exercise(name: "Squat", sets: [
                WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 90)
            ]),
            Exercise(name: "Bench Press", sets: [
                WorkoutSet(reps: 8, weight: 60, restTimeInSeconds: 60)
            ])
        ]
        return Workout(
            name: name,
            exercises: exercises ?? defaultExercises
        )
    }
    
    /// Creates a sample workout log for testing.
    private func createSampleWorkoutLog(
        date: Date = Date(),
        workoutName: String = "Test Workout",
        duration: TimeInterval = 3600,
        exercises: [CompletedExercise]? = nil
    ) -> WorkoutLog {
        let defaultExercises = [
            CompletedExercise(
                name: "Squat",
                sets: [CompletedSet(reps: 5, weight: 100)],
                feedback: .moderate
            )
        ]
        return WorkoutLog(
            date: date,
            workoutName: workoutName,
            duration: duration,
            completedExercises: exercises ?? defaultExercises
        )
    }
    
    /// Creates a sample active workout for testing.
    private func createSampleActiveWorkout(workoutID: UUID = UUID()) -> ActiveWorkout {
        return ActiveWorkout(
            workoutID: workoutID,
            workoutName: "Test Active Workout",
            startTime: Date(),
            totalElapsedTime: 120,
            liveSetsByExercise: [:],
            exerciseFeedback: [:],
            isResting: false,
            restEndDate: nil,
            restTimeRemaining: 0
        )
    }
    
    // MARK: - Loading Workouts Tests
    
    @Test func init_loadsWorkoutsFromPersistence() async {
        let existingWorkouts = [createSampleWorkout(name: "Loaded Workout")]
        let mockPersistence = MockPersistenceManager(workouts: existingWorkouts)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(mockPersistence.loadWorkoutsCalled == true)
        #expect(store.workouts.count == 1)
        #expect(store.workouts.first?.name == "Loaded Workout")
    }
    
    @Test func init_createsPlaceholderWorkouts_whenNoPersistenceData() async {
        let mockPersistence = MockPersistenceManager(workouts: nil)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(mockPersistence.loadWorkoutsCalled == true)
        #expect(store.workouts.isEmpty == false)
        // Placeholder workouts should be created
        #expect(store.workouts.count >= 1)
    }
    
    @Test func init_loadsHistoryFromPersistence() async {
        let existingHistory = [createSampleWorkoutLog(workoutName: "Loaded Log")]
        let mockPersistence = MockPersistenceManager(history: existingHistory)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(mockPersistence.loadHistoryCalled == true)
        #expect(store.history.count == 1)
        #expect(store.history.first?.workoutName == "Loaded Log")
    }
    
    @Test func init_createsEmptyHistory_whenNoPersistenceData() async {
        let mockPersistence = MockPersistenceManager(history: nil)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(mockPersistence.loadHistoryCalled == true)
        #expect(store.history.isEmpty == true)
    }
    
    @Test func init_loadsActiveWorkout_whenExists() async {
        let activeWorkout = createSampleActiveWorkout()
        let mockPersistence = MockPersistenceManager(activeWorkout: activeWorkout)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(mockPersistence.loadActiveWorkoutCalled == true)
        #expect(store.activeWorkout != nil)
        #expect(store.activeWorkout?.workoutName == "Test Active Workout")
    }
    
    @Test func init_loadsBodyweightFromPersistence() async {
        let mockPersistence = MockPersistenceManager(bodyweight: 85.5)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(mockPersistence.loadBodyweightCalled == true)
        #expect(store.bodyweight == 85.5)
    }
    
    @Test func init_usesDefaultBodyweight_whenNotSet() async {
        let mockPersistence = MockPersistenceManager(bodyweight: nil)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(store.bodyweight == 70.0)
    }
    
    @Test func init_loadsSmallestWeightIncrement() async {
        let mockPersistence = MockPersistenceManager(smallestWeightIncrement: 1.25)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(mockPersistence.loadSmallestWeightIncrementCalled == true)
        #expect(store.smallestWeightIncrement == 1.25)
    }
    
    @Test func init_usesDefaultSmallestWeightIncrement_whenNotSet() async {
        let mockPersistence = MockPersistenceManager(smallestWeightIncrement: nil)
        
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(store.smallestWeightIncrement == 0.5)
    }
    
    // MARK: - Saving Workouts Tests
    
    @Test func workoutsDidSet_savesWorkouts() async {
        let mockPersistence = MockPersistenceManager()
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        let newWorkout = createSampleWorkout(name: "New Workout")
        store.workouts.append(newWorkout)
        
        #expect(mockPersistence.saveWorkoutsCalled == true)
        #expect(mockPersistence.workouts?.count ?? 0 > 0)
    }
    
    @Test func historyDidSet_savesHistory() async {
        let mockPersistence = MockPersistenceManager()
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        let log = createSampleWorkoutLog()
        store.history.append(log)
        
        #expect(mockPersistence.saveHistoryCalled == true)
        #expect(mockPersistence.history?.count == 1)
    }
    
    @Test func bodyweightDidSet_savesBodyweight() async {
        let mockPersistence = MockPersistenceManager()
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        store.bodyweight = 90.0
        
        #expect(mockPersistence.saveBodyweightCalled == true)
        #expect(mockPersistence.bodyweight == 90.0)
    }
    
    @Test func smallestWeightIncrementDidSet_savesIncrement() async {
        let mockPersistence = MockPersistenceManager()
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        store.smallestWeightIncrement = 2.5
        
        #expect(mockPersistence.saveSmallestWeightIncrementCalled == true)
        #expect(mockPersistence.smallestWeightIncrement == 2.5)
    }
    
    // MARK: - addWorkoutLog Tests
    
    @Test func addWorkoutLog_insertsLogAtBeginning() async {
        let mockPersistence = MockPersistenceManager()
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        let log1 = createSampleWorkoutLog(workoutName: "First Log")
        let log2 = createSampleWorkoutLog(workoutName: "Second Log")
        
        store.addWorkoutLog(log1)
        store.addWorkoutLog(log2)
        
        #expect(store.history.count == 2)
        #expect(store.history.first?.workoutName == "Second Log")
        #expect(store.history.last?.workoutName == "First Log")
    }
    
    @Test func addWorkoutLog_triggersHistorySave() async {
        let mockPersistence = MockPersistenceManager()
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        let log = createSampleWorkoutLog()
        store.addWorkoutLog(log)
        
        #expect(mockPersistence.saveHistoryCalled == true)
    }
    
    // MARK: - updateWorkoutPlan Tests
    
    @Test func updateWorkoutPlan_updatesModifiedSets() async {
        let workoutID = UUID()
        let exerciseID = UUID()
        let setID = UUID()
        
        let workout = Workout(
            id: workoutID,
            name: "Test Workout",
            exercises: [
                Exercise(
                    id: exerciseID,
                    name: "Squat",
                    sets: [WorkoutSet(id: setID, reps: 5, weight: 100, restTimeInSeconds: 90)]
                )
            ]
        )
        
        let mockPersistence = MockPersistenceManager(workouts: [workout])
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        let modifiedLiveSets: [UUID: [LiveWorkoutSet]] = [
            exerciseID: [
                LiveWorkoutSet(
                    id: setID,
                    reps: 8,
                    weight: 110,
                    restTimeInSeconds: 90,
                    isCompleted: true,
                    wasModified: true
                )
            ]
        ]
        
        store.updateWorkoutPlan(from: modifiedLiveSets, for: workoutID)
        
        #expect(store.workouts.first?.exercises.first?.sets.first?.reps == 8)
        #expect(store.workouts.first?.exercises.first?.sets.first?.weight == 110)
    }
    
    @Test func updateWorkoutPlan_ignoresUnmodifiedSets() async {
        let workoutID = UUID()
        let exerciseID = UUID()
        let setID = UUID()
        
        let workout = Workout(
            id: workoutID,
            name: "Test Workout",
            exercises: [
                Exercise(
                    id: exerciseID,
                    name: "Squat",
                    sets: [WorkoutSet(id: setID, reps: 5, weight: 100, restTimeInSeconds: 90)]
                )
            ]
        )
        
        let mockPersistence = MockPersistenceManager(workouts: [workout])
        let store = WorkoutStore(persistence: mockPersistence)
        
        let unmodifiedLiveSets: [UUID: [LiveWorkoutSet]] = [
            exerciseID: [
                LiveWorkoutSet(
                    id: setID,
                    reps: 8,
                    weight: 110,
                    restTimeInSeconds: 90,
                    isCompleted: true,
                    wasModified: false  // Not marked as modified
                )
            ]
        ]
        
        store.updateWorkoutPlan(from: unmodifiedLiveSets, for: workoutID)
        
        // Values should remain unchanged since wasModified is false
        #expect(store.workouts.first?.exercises.first?.sets.first?.reps == 5)
        #expect(store.workouts.first?.exercises.first?.sets.first?.weight == 100)
    }
    
    @Test func updateWorkoutPlan_handlesNonExistentWorkout() async {
        let mockPersistence = MockPersistenceManager(workouts: [createSampleWorkout()])
        let store = WorkoutStore(persistence: mockPersistence)
        let initialWorkoutsCount = store.workouts.count
        
        // Try to update a non-existent workout
        store.updateWorkoutPlan(from: [:], for: UUID())
        
        // Should not crash and workouts should remain unchanged
        #expect(store.workouts.count == initialWorkoutsCount)
    }
    
    // MARK: - addExercise Tests
    
    @Test func addExercise_addsExerciseToWorkout() async {
        let workoutID = UUID()
        let workout = Workout(id: workoutID, name: "Test Workout", exercises: [])
        
        let mockPersistence = MockPersistenceManager(workouts: [workout])
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        let result = store.addExercise(named: "Deadlift", to: workoutID)
        
        #expect(result != nil)
        #expect(result?.name == "Deadlift")
        #expect(store.workouts.first?.exercises.count == 1)
        #expect(store.workouts.first?.exercises.first?.name == "Deadlift")
    }
    
    @Test func addExercise_addsExerciseWithCustomSets() async {
        let workoutID = UUID()
        let workout = Workout(id: workoutID, name: "Test Workout", exercises: [])
        
        let mockPersistence = MockPersistenceManager(workouts: [workout])
        let store = WorkoutStore(persistence: mockPersistence)
        
        let customSets = [
            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120),
            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120),
            WorkoutSet(reps: 5, weight: 100, restTimeInSeconds: 120)
        ]
        
        let result = store.addExercise(named: "Squat", sets: customSets, to: workoutID)
        
        #expect(result != nil)
        #expect(result?.sets.count == 3)
        #expect(result?.sets.first?.reps == 5)
        #expect(result?.sets.first?.weight == 100)
    }
    
    @Test func addExercise_returnsNil_forNonExistentWorkout() async {
        let mockPersistence = MockPersistenceManager(workouts: [])
        let store = WorkoutStore(persistence: mockPersistence)
        
        let result = store.addExercise(named: "Deadlift", to: UUID())
        
        #expect(result == nil)
    }
    
    @Test func addExercise_triggersWorkoutSave() async {
        let workoutID = UUID()
        let workout = Workout(id: workoutID, name: "Test Workout", exercises: [])
        
        let mockPersistence = MockPersistenceManager(workouts: [workout])
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        _ = store.addExercise(named: "Deadlift", to: workoutID)
        
        #expect(mockPersistence.saveWorkoutsCalled == true)
    }
    
    // MARK: - clearHistory Tests
    
    @Test func clearHistory_removesAllHistoryEntries() async {
        let existingHistory = [
            createSampleWorkoutLog(workoutName: "Log 1"),
            createSampleWorkoutLog(workoutName: "Log 2"),
            createSampleWorkoutLog(workoutName: "Log 3")
        ]
        let mockPersistence = MockPersistenceManager(history: existingHistory)
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        #expect(store.history.count == 3)
        
        store.clearHistory()
        
        #expect(store.history.isEmpty == true)
        #expect(mockPersistence.saveHistoryCalled == true)
    }
    
    @Test func clearHistory_handlesEmptyHistory() async {
        let mockPersistence = MockPersistenceManager(history: [])
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        store.clearHistory()
        
        #expect(store.history.isEmpty == true)
    }
    
    // MARK: - deleteHistory Tests
    
    @Test func deleteHistory_removesEntriesContainingExercise() async {
        let exercises1 = [CompletedExercise(name: "Squat", sets: [], feedback: nil)]
        let exercises2 = [CompletedExercise(name: "Bench Press", sets: [], feedback: nil)]
        let exercises3 = [
            CompletedExercise(name: "Squat", sets: [], feedback: nil),
            CompletedExercise(name: "Deadlift", sets: [], feedback: nil)
        ]
        
        let existingHistory = [
            createSampleWorkoutLog(workoutName: "Workout 1", exercises: exercises1),
            createSampleWorkoutLog(workoutName: "Workout 2", exercises: exercises2),
            createSampleWorkoutLog(workoutName: "Workout 3", exercises: exercises3)
        ]
        
        let mockPersistence = MockPersistenceManager(history: existingHistory)
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        store.deleteHistory(for: "Squat")
        
        // Workouts 1 and 3 contain Squat, so only Workout 2 should remain
        #expect(store.history.count == 1)
        #expect(store.history.first?.workoutName == "Workout 2")
        #expect(mockPersistence.saveHistoryCalled == true)
    }
    
    @Test func deleteHistory_handlesExerciseNotInHistory() async {
        let exercises = [CompletedExercise(name: "Bench Press", sets: [], feedback: nil)]
        let existingHistory = [createSampleWorkoutLog(exercises: exercises)]
        
        let mockPersistence = MockPersistenceManager(history: existingHistory)
        let store = WorkoutStore(persistence: mockPersistence)
        
        store.deleteHistory(for: "Squat")
        
        // No logs should be removed since Squat is not in history
        #expect(store.history.count == 1)
    }
    
    // MARK: - Active Workout Management Tests
    
    @Test func activeWorkoutDidSet_savesActiveWorkout() async {
        let mockPersistence = MockPersistenceManager()
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        let activeWorkout = createSampleActiveWorkout()
        store.activeWorkout = activeWorkout
        
        #expect(mockPersistence.saveActiveWorkoutCalled == true)
        #expect(mockPersistence.activeWorkout?.workoutName == "Test Active Workout")
    }
    
    @Test func clearActiveWorkout_setsActiveWorkoutToNil() async {
        let activeWorkout = createSampleActiveWorkout()
        let mockPersistence = MockPersistenceManager(activeWorkout: activeWorkout)
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(store.activeWorkout != nil)
        
        store.clearActiveWorkout()
        
        #expect(store.activeWorkout == nil)
    }
    
    @Test func clearActiveWorkout_savesNilActiveWorkout() async {
        let activeWorkout = createSampleActiveWorkout()
        let mockPersistence = MockPersistenceManager(activeWorkout: activeWorkout)
        let store = WorkoutStore(persistence: mockPersistence)
        mockPersistence.resetTracking()
        
        store.clearActiveWorkout()
        
        #expect(mockPersistence.saveActiveWorkoutCalled == true)
        #expect(mockPersistence.activeWorkout == nil)
    }
    
    @Test func init_restoresActiveWorkoutRestState_whenValid() async {
        let futureRestEndDate = Date().addingTimeInterval(30) // 30 seconds in the future
        let activeWorkout = ActiveWorkout(
            workoutID: UUID(),
            workoutName: "Rest Test Workout",
            startTime: Date().addingTimeInterval(-120),
            totalElapsedTime: 120,
            liveSetsByExercise: [:],
            exerciseFeedback: [:],
            isResting: true,
            restEndDate: futureRestEndDate,
            restTimeRemaining: 30
        )
        
        let mockPersistence = MockPersistenceManager(activeWorkout: activeWorkout)
        let store = WorkoutStore(persistence: mockPersistence)
        
        #expect(store.activeWorkout?.isResting == true)
        #expect((store.activeWorkout?.restTimeRemaining ?? 0) > 0)
    }
    
    @Test func init_resetsExpiredRestState() async {
        let pastRestEndDate = Date().addingTimeInterval(-30) // 30 seconds in the past
        let activeWorkout = ActiveWorkout(
            workoutID: UUID(),
            workoutName: "Expired Rest Test Workout",
            startTime: Date().addingTimeInterval(-120),
            totalElapsedTime: 120,
            liveSetsByExercise: [:],
            exerciseFeedback: [:],
            isResting: true,
            restEndDate: pastRestEndDate,
            restTimeRemaining: 30
        )
        
        let mockPersistence = MockPersistenceManager(activeWorkout: activeWorkout)
        let store = WorkoutStore(persistence: mockPersistence)
        
        // Rest should be reset since it has expired
        #expect(store.activeWorkout?.isResting == false)
        #expect(store.activeWorkout?.restTimeRemaining == 0)
    }
    
    // MARK: - Helper Function Tests
    
    @Test func getAllExerciseNames_returnsUniqueNames() async {
        let workouts = [
            Workout(name: "Workout A", exercises: [
                Exercise(name: "Squat", sets: []),
                Exercise(name: "Bench Press", sets: [])
            ]),
            Workout(name: "Workout B", exercises: [
                Exercise(name: "Squat", sets: []),  // Duplicate
                Exercise(name: "Deadlift", sets: [])
            ])
        ]
        
        let mockPersistence = MockPersistenceManager(workouts: workouts)
        let store = WorkoutStore(persistence: mockPersistence)
        
        let names = store.getAllExerciseNames()
        
        #expect(names.count == 3)  // Squat, Bench Press, Deadlift (unique)
        #expect(names.contains("Squat"))
        #expect(names.contains("Bench Press"))
        #expect(names.contains("Deadlift"))
    }
    
    @Test func getAllExerciseNames_returnsSortedNames() async {
        let workouts = [
            Workout(name: "Workout", exercises: [
                Exercise(name: "Squat", sets: []),
                Exercise(name: "Bench Press", sets: []),
                Exercise(name: "Deadlift", sets: [])
            ])
        ]
        
        let mockPersistence = MockPersistenceManager(workouts: workouts)
        let store = WorkoutStore(persistence: mockPersistence)
        
        let names = store.getAllExerciseNames()
        
        #expect(names == ["Bench Press", "Deadlift", "Squat"])
    }
    
    @Test func getLastFeedback_returnsLatestFeedback() async {
        let oldLog = createSampleWorkoutLog(
            date: Date().addingTimeInterval(-86400 * 7),  // 7 days ago
            exercises: [CompletedExercise(name: "Squat", sets: [], feedback: .easy)]
        )
        let recentLog = createSampleWorkoutLog(
            date: Date().addingTimeInterval(-86400),  // 1 day ago
            exercises: [CompletedExercise(name: "Squat", sets: [], feedback: .hard)]
        )
        
        // History is ordered with most recent first
        let mockPersistence = MockPersistenceManager(history: [recentLog, oldLog])
        let store = WorkoutStore(persistence: mockPersistence)
        
        let feedback = store.getLastFeedback(for: "Squat")
        
        #expect(feedback == .hard)
    }
    
    @Test func getLastFeedback_returnsNil_whenNoHistory() async {
        let mockPersistence = MockPersistenceManager(history: [])
        let store = WorkoutStore(persistence: mockPersistence)
        
        let feedback = store.getLastFeedback(for: "Squat")
        
        #expect(feedback == nil)
    }
    
    @Test func getHistory_returnsLogsContainingExercise() async {
        let logWithSquat = createSampleWorkoutLog(
            workoutName: "Leg Day",
            exercises: [CompletedExercise(name: "Squat", sets: [], feedback: nil)]
        )
        let logWithBench = createSampleWorkoutLog(
            workoutName: "Push Day",
            exercises: [CompletedExercise(name: "Bench Press", sets: [], feedback: nil)]
        )
        let logWithBoth = createSampleWorkoutLog(
            workoutName: "Full Body",
            exercises: [
                CompletedExercise(name: "Squat", sets: [], feedback: nil),
                CompletedExercise(name: "Bench Press", sets: [], feedback: nil)
            ]
        )
        
        let mockPersistence = MockPersistenceManager(history: [logWithSquat, logWithBench, logWithBoth])
        let store = WorkoutStore(persistence: mockPersistence)
        
        let squatHistory = store.getHistory(for: "Squat")
        
        #expect(squatHistory.count == 2)
        #expect(squatHistory.contains(where: { $0.workoutName == "Leg Day" }))
        #expect(squatHistory.contains(where: { $0.workoutName == "Full Body" }))
    }
}
