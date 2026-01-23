// ProgressiveOverloadServiceTests.swift

import Testing
import Foundation
@testable import Workout_Tracker

// MARK: - Progressive Overload Service Tests

struct ProgressiveOverloadServiceTests {
    
    // MARK: - Properties
    
    private let service = ProgressiveOverloadService()
    private let exerciseName = "Bench Press"
    private let smallestIncrement = 2.5
    
    // MARK: - Helper Functions
    
    /// Creates a workout log with a single exercise and specified sets.
    private func createWorkoutLog(
        date: Date,
        exerciseName: String,
        weights: [Double],
        feedback: FeedbackRating? = nil
    ) -> WorkoutLog {
        let sets = weights.map { weight in
            CompletedSet(reps: 10, weight: weight)
        }
        let exercise = CompletedExercise(
            name: exerciseName,
            sets: sets,
            feedback: feedback
        )
        return WorkoutLog(
            date: date,
            workoutName: "Test Workout",
            duration: 3600,
            completedExercises: [exercise]
        )
    }
    
    /// Creates a date offset from today by the specified number of days.
    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }
    
    // MARK: - getProgressiveOverloadSuggestion Tests
    
    @Test func getProgressiveOverloadSuggestion_withNotEnoughHistory_returnsNil() {
        // Only 2 workouts, need at least 3
        let history = [
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: .easy)
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result == nil)
    }
    
    @Test func getProgressiveOverloadSuggestion_withNoRatedWorkouts_returnsNil() {
        // 3 workouts but none have feedback
        let history = [
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: nil)
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result == nil)
    }
    
    @Test func getProgressiveOverloadSuggestion_withPoorFeedback_returnsNil() {
        // All workouts have poor feedback (hard/very hard)
        let history = [
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [50], feedback: .hard),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: .veryHard),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: .hard)
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result == nil)
    }
    
    @Test func getProgressiveOverloadSuggestion_withGoodFeedbackRatio_suggestsModerateIncrease() {
        // 3 out of 4 rated workouts have positive feedback (75% >= 60% threshold)
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [50], feedback: .moderate),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: .hard),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: .easy)
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result != nil)
        if let result = result {
            // 50 * 1.025 = 51.25, rounded up to 52.5
            #expect(result.suggestedWeight == 52.5)
            #expect(result.percentageIncrease > 0)
        }
    }
    
    @Test func getProgressiveOverloadSuggestion_withExcellentFeedbackRatio_suggestsAggressiveIncrease() {
        // All workouts have excellent feedback (100% >= 80% threshold)
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [50], feedback: .veryEasy),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: .moderate)
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result != nil)
        if let result = result {
            // 50 * 1.05 = 52.5, rounded up to 52.5
            #expect(result.suggestedWeight == 52.5)
            #expect(result.percentageIncrease >= 0.05)
        }
    }
    
    @Test func getProgressiveOverloadSuggestion_withRecentWeightIncrease_returnsNil() {
        // Weight was just increased in the most recent workout
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [55], feedback: .easy) // weight increased
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result == nil)
    }
    
    @Test func getProgressiveOverloadSuggestion_withZeroWeight_returnsNil() {
        // Exercise has zero weight (bodyweight exercise or error)
        let history = [
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [0], feedback: .easy),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [0], feedback: .easy),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [0], feedback: .easy)
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result == nil)
    }
    
    @Test func getProgressiveOverloadSuggestion_roundsToSmallestIncrement() {
        // Test rounding logic with different smallest increment
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [47], feedback: .easy),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [47], feedback: .easy),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [47], feedback: .easy),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [47], feedback: .easy)
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: 5.0
        )
        
        #expect(result != nil)
        if let result = result {
            // Should be rounded up to nearest 5
            #expect(result.suggestedWeight.truncatingRemainder(dividingBy: 5.0) == 0)
        }
    }
    
    // MARK: - shouldDeload Tests
    
    @Test func shouldDeload_withNotEnoughHistory_returnsFalse() {
        // Only 2 workouts, need at least 4
        let history = [
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: .hard),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: .hard)
        ]
        
        let result = service.shouldDeload(for: exerciseName, in: history)
        
        #expect(result == false)
    }
    
    @Test func shouldDeload_withStagnationAndPoorFeedback_returnsTrue() {
        // No progress over 4+ weeks with poor feedback
        let history = [
            createWorkoutLog(date: daysAgo(25), exerciseName: exerciseName, weights: [50], feedback: .hard),
            createWorkoutLog(date: daysAgo(18), exerciseName: exerciseName, weights: [50], feedback: .hard),
            createWorkoutLog(date: daysAgo(11), exerciseName: exerciseName, weights: [50], feedback: .veryHard),
            createWorkoutLog(date: daysAgo(4), exerciseName: exerciseName, weights: [50], feedback: .hard)
        ]
        
        let result = service.shouldDeload(for: exerciseName, in: history)
        
        #expect(result == true)
    }
    
    @Test func shouldDeload_withGoodProgress_returnsFalse() {
        // Weight increased steadily, even with some hard feedback
        let history = [
            createWorkoutLog(date: daysAgo(25), exerciseName: exerciseName, weights: [40], feedback: .moderate),
            createWorkoutLog(date: daysAgo(18), exerciseName: exerciseName, weights: [45], feedback: .moderate),
            createWorkoutLog(date: daysAgo(11), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(4), exerciseName: exerciseName, weights: [55], feedback: .moderate)
        ]
        
        let result = service.shouldDeload(for: exerciseName, in: history)
        
        #expect(result == false)
    }
    
    @Test func shouldDeload_withHighFrequencyAndPoorFeedback_returnsTrue() {
        // More than 21 workouts in 3 weeks with poor feedback
        var history: [WorkoutLog] = []
        
        // Create 22 workouts in the last 3 weeks with mostly poor feedback
        for i in 0..<22 {
            let feedback: FeedbackRating = (i % 3 == 0) ? .moderate : .hard
            history.append(createWorkoutLog(
                date: daysAgo(i),
                exerciseName: exerciseName,
                weights: [50],
                feedback: feedback
            ))
        }
        
        let result = service.shouldDeload(for: exerciseName, in: history)
        
        #expect(result == true)
    }
    
    @Test func shouldDeload_withHighFrequencyButGoodFeedback_returnsFalse() {
        // Many workouts but with good feedback
        var history: [WorkoutLog] = []
        
        // Create many workouts but with good feedback
        for i in 0..<22 {
            history.append(createWorkoutLog(
                date: daysAgo(i),
                exerciseName: exerciseName,
                weights: [50 + Double(i)],  // Progressive weight
                feedback: .easy
            ))
        }
        
        let result = service.shouldDeload(for: exerciseName, in: history)
        
        #expect(result == false)
    }
    
    @Test func shouldDeload_withStagnationButNoFeedback_returnsFalse() {
        // No progress but no feedback to evaluate
        let history = [
            createWorkoutLog(date: daysAgo(25), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(18), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(11), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(4), exerciseName: exerciseName, weights: [50], feedback: nil)
        ]
        
        let result = service.shouldDeload(for: exerciseName, in: history)
        
        #expect(result == false)
    }
    
    // MARK: - getImprovementPercentage Tests
    
    @Test func getImprovementPercentage_withNotEnoughHistory_returnsNil() {
        // Only 2 workouts, need at least 4 by default
        let history = [
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [55], feedback: nil)
        ]
        
        let result = service.getImprovementPercentage(for: exerciseName, in: history, overLast: 4)
        
        #expect(result == nil)
    }
    
    @Test func getImprovementPercentage_withNoChange_returnsZero() {
        // Same weight across all workouts
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: nil)
        ]
        
        let result = service.getImprovementPercentage(for: exerciseName, in: history, overLast: 4)
        
        #expect(result == 0)
    }
    
    @Test func getImprovementPercentage_withPositiveImprovement_returnsCorrectPercentage() {
        // Weight increased from 50 to 60 (20% improvement)
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [52.5], feedback: nil),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [55], feedback: nil),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [60], feedback: nil)
        ]
        
        let result = service.getImprovementPercentage(for: exerciseName, in: history, overLast: 4)
        
        #expect(result == 20.0)
    }
    
    @Test func getImprovementPercentage_withNegativeImprovement_returnsNegativePercentage() {
        // Weight decreased from 60 to 50 (-16.67% improvement)
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [60], feedback: nil),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [57.5], feedback: nil),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [55], feedback: nil),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: nil)
        ]
        
        let result = service.getImprovementPercentage(for: exerciseName, in: history, overLast: 4)
        
        #expect(result != nil)
        if let result = result {
            #expect(result < 0)
            #expect(abs(result - (-16.666666666666668)) < 0.01)
        }
    }
    
    @Test func getImprovementPercentage_withCustomWorkoutCount_usesCorrectWindow() {
        // Test with custom workout count of 2
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [40], feedback: nil),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [55], feedback: nil),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [60], feedback: nil)
        ]
        
        // Over last 2: 55 to 60 = 9.09% increase
        let result = service.getImprovementPercentage(for: exerciseName, in: history, overLast: 2)
        
        #expect(result != nil)
        if let result = result {
            #expect(abs(result - 9.090909090909092) < 0.01)
        }
    }
    
    @Test func getImprovementPercentage_withMultipleSetsUsesMax_returnsCorrectPercentage() {
        // Multiple sets per exercise, should use max weight
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [40, 50, 45], feedback: nil), // max: 50
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [45, 55, 50], feedback: nil), // max: 55
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50, 60, 55], feedback: nil),  // max: 60
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [55, 65, 60], feedback: nil)   // max: 65
        ]
        
        // 50 to 65 = 30% improvement
        let result = service.getImprovementPercentage(for: exerciseName, in: history, overLast: 4)
        
        #expect(result == 30.0)
    }
    
    @Test func getImprovementPercentage_withZeroStartingWeight_returnsNil() {
        // Starting weight is 0, would cause division by zero
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: exerciseName, weights: [0], feedback: nil),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [25], feedback: nil),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: nil),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [60], feedback: nil)
        ]
        
        let result = service.getImprovementPercentage(for: exerciseName, in: history, overLast: 4)
        
        #expect(result == nil)
    }
    
    // MARK: - Edge Case Tests
    
    @Test func getProgressiveOverloadSuggestion_withDifferentExercise_filtersCorrectly() {
        // History contains multiple exercises, should only consider the target exercise
        let otherExercise = "Squat"
        let history = [
            createWorkoutLog(date: daysAgo(21), exerciseName: otherExercise, weights: [100], feedback: .easy),
            createWorkoutLog(date: daysAgo(14), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(7), exerciseName: exerciseName, weights: [50], feedback: .easy),
            createWorkoutLog(date: daysAgo(3), exerciseName: exerciseName, weights: [50], feedback: .easy)
        ]
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result != nil)
        if let result = result {
            // Should suggest based on 50kg, not 100kg from other exercise
            #expect(result.suggestedWeight < 60)
        }
    }
    
    @Test func getProgressiveOverloadSuggestion_withEmptyHistory_returnsNil() {
        let history: [WorkoutLog] = []
        
        let result = service.getProgressiveOverloadSuggestion(
            for: exerciseName,
            in: history,
            smallestWeightIncrement: smallestIncrement
        )
        
        #expect(result == nil)
    }
    
    @Test func shouldDeload_withEmptyHistory_returnsFalse() {
        let history: [WorkoutLog] = []
        
        let result = service.shouldDeload(for: exerciseName, in: history)
        
        #expect(result == false)
    }
    
    @Test func getImprovementPercentage_withEmptyHistory_returnsNil() {
        let history: [WorkoutLog] = []
        
        let result = service.getImprovementPercentage(for: exerciseName, in: history, overLast: 4)
        
        #expect(result == nil)
    }
}
