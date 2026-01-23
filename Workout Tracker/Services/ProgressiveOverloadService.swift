//
//  ProgressiveOverloadService.swift
//  Workout Tracker
//

import Foundation

// MARK: - Progressive Overload Service Protocol

/// Protocol for progressive overload calculations, enabling dependency injection and testability.
///
/// Implement this protocol to provide custom progressive overload logic or mock implementations
/// for unit testing.
protocol ProgressiveOverloadServiceProtocol {
    /// Calculates a suggested weight increase based on recent performance and feedback.
    func getProgressiveOverloadSuggestion(
        for exerciseName: String,
        in history: [WorkoutLog],
        smallestWeightIncrement: Double
    ) -> (suggestedWeight: Double, percentageIncrease: Double)?
    
    /// Determines if the user should take a deload week for this exercise.
    func shouldDeload(for exerciseName: String, in history: [WorkoutLog]) -> Bool
    
    /// Calculates the percentage improvement over the last N workouts.
    func getImprovementPercentage(
        for exerciseName: String,
        in history: [WorkoutLog],
        overLast workoutCount: Int
    ) -> Double?
}

// MARK: - Progressive Overload Service Implementation

/// Service responsible for calculating progressive overload suggestions and deload recommendations.
///
/// ## Overview
///
/// This service implements evidence-based progressive overload logic that analyzes workout history
/// to provide intelligent weight increase suggestions and detect when the user needs a deload.
///
/// ## Architecture
///
/// The service is stateless and accepts workout history as input, making it:
/// - **Testable**: Easy to unit test with mock workout data
/// - **Independent**: No dependency on `WorkoutStore` or persistence layer
/// - **Pure**: Same inputs always produce same outputs
///
/// ## Algorithms
///
/// ### 1. Progressive Overload Suggestion (`getProgressiveOverloadSuggestion`)
///
/// Analyzes the last 4 workouts to determine if the user is ready for more weight:
///
/// ```
/// ┌─────────────────────────────────────────────────────────────────┐
/// │                    SUGGESTION DECISION TREE                     │
/// ├─────────────────────────────────────────────────────────────────┤
/// │ 1. Has ≥3 workouts with this exercise?  ──NO──→  No suggestion │
/// │     │YES                                                        │
/// │     ▼                                                           │
/// │ 2. Has ≥2 rated workouts (with feedback)?  ──NO──→ No suggest. │
/// │     │YES                                                        │
/// │     ▼                                                           │
/// │ 3. Is ≥60% of feedback positive?  ──NO──→  No suggestion       │
/// │     │YES                                                        │
/// │     ▼                                                           │
/// │ 4. Did weight increase in last 2 workouts?  ──YES──→ No sugg.  │
/// │     │NO                                                         │
/// │     ▼                                                           │
/// │ 5. Is ≥80% of feedback positive?                                │
/// │     │YES → Suggest 5% increase (aggressive)                     │
/// │     │NO  → Suggest 2.5% increase (moderate)                     │
/// │     ▼                                                           │
/// │ 6. Round up to nearest weight increment                        │
/// └─────────────────────────────────────────────────────────────────┘
/// ```
///
/// ### 2. Deload Detection (`shouldDeload`)
///
/// Identifies when accumulated fatigue is limiting progress:
///
/// ```
/// ┌─────────────────────────────────────────────────────────────────┐
/// │                    DELOAD DECISION TREE                         │
/// ├─────────────────────────────────────────────────────────────────┤
/// │ Prerequisite: Must have poor feedback (≥50% hard/veryHard)     │
/// │                                                                 │
/// │ Deload if ANY of these conditions are met:                      │
/// │                                                                 │
/// │ A. STAGNATION DETECTION                                         │
/// │    ├─ 4+ workouts in last 28 days                               │
/// │    ├─ Weight hasn't increased >5%                               │
/// │    └─ AND has poor feedback                                     │
/// │                                                                 │
/// │ B. OVERTRAINING DETECTION                                       │
/// │    ├─ 21+ workouts in last 21 days                              │
/// │    └─ AND has poor feedback                                     │
/// └─────────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Usage Example
///
/// ```swift
/// let service = ProgressiveOverloadService()
/// let history: [WorkoutLog] = store.workoutLogs
///
/// // Check for weight suggestion
/// if let suggestion = service.getProgressiveOverloadSuggestion(
///     for: "Bench Press",
///     in: history,
///     smallestWeightIncrement: 2.5
/// ) {
///     print("Suggested: \(suggestion.suggestedWeight)kg (+\(suggestion.percentageIncrease * 100)%)")
/// }
///
/// // Check for deload recommendation
/// if service.shouldDeload(for: "Bench Press", in: history) {
///     print("Consider a deload week")
/// }
/// ```
///
final class ProgressiveOverloadService: ProgressiveOverloadServiceProtocol {
    
    // MARK: - Public Methods
    
    // MARK: Progressive Overload Suggestion Algorithm
    
    /// Analyzes recent workout history to suggest a weight increase for an exercise.
    ///
    /// ## Algorithm Steps
    ///
    /// 1. **Filter History**: Extract only workouts containing the target exercise
    /// 2. **Check Minimum Data**: Require ≥3 workouts total, ≥2 with feedback ratings
    /// 3. **Analyze Feedback**: Calculate ratio of positive feedback (veryEasy, easy, moderate)
    /// 4. **Check Recent Progress**: Skip if weight already increased in last 2 workouts
    /// 5. **Calculate Suggestion**: Apply 2.5% or 5% increase based on feedback quality
    /// 6. **Round to Increment**: Round up to nearest available weight increment
    ///
    /// ## Data Analyzed
    ///
    /// - **Last 4 workouts**: Window for feedback analysis
    /// - **Maximum weight per workout**: Used as baseline for suggestion
    /// - **Feedback ratings**: User's subjective effort assessment
    ///
    /// ## Return Conditions
    ///
    /// Returns `nil` (no suggestion) when:
    /// - Fewer than 3 workouts with this exercise exist
    /// - Fewer than 2 workouts have feedback ratings
    /// - Less than 60% of feedback is positive
    /// - Weight was already increased in the last 2 workouts
    /// - Current weight is zero or negative
    /// - Rounding doesn't produce a meaningful increase
    ///
    /// - Parameters:
    ///   - exerciseName: The exact name of the exercise to analyze (case-sensitive).
    ///   - history: The complete workout history array.
    ///   - smallestWeightIncrement: The smallest weight increment available (e.g., 2.5kg, 1.25kg).
    /// - Returns: A tuple with `suggestedWeight` and `percentageIncrease`, or `nil` if no suggestion.
    func getProgressiveOverloadSuggestion(
        for exerciseName: String,
        in history: [WorkoutLog],
        smallestWeightIncrement: Double
    ) -> (suggestedWeight: Double, percentageIncrease: Double)? {
        // Step 1: Filter history to only workouts containing this exercise
        let exerciseHistory = getHistory(for: exerciseName, in: history)
        
        // Step 2: Require minimum workout count for statistical significance
        // Without enough data points, suggestions would be unreliable
        guard exerciseHistory.count >= OverloadConstants.minWorkoutsForSuggestion else { return nil }
        
        // Step 3: Analyze feedback from the last 4 workouts
        // Using 4 workouts balances recency with noise reduction
        let recentWorkouts = exerciseHistory.sorted(by: { $0.date > $1.date }).prefix(4)
        
        // Step 4: Count workouts with feedback and classify as positive/negative
        // Positive feedback = veryEasy, easy, moderate (user felt capable)
        // Negative feedback = hard, veryHard (user was struggling)
        var ratedWorkoutsCount = 0
        var positiveFeedbackCount = 0
        
        for workout in recentWorkouts {
            if let exercise = workout.completedExercises.first(where: { $0.name == exerciseName }),
               let feedback = exercise.feedback {
                ratedWorkoutsCount += 1
                // Classify feedback: veryEasy/easy/moderate = positive (ready for more)
                if feedback == .veryEasy || feedback == .easy || feedback == .moderate {
                    positiveFeedbackCount += 1
                }
            }
        }
        
        // Step 5: Require minimum rated workouts for reliable feedback analysis
        guard ratedWorkoutsCount >= OverloadConstants.minRatedWorkoutsForSuggestion else { return nil }
        
        // Step 6: Calculate feedback ratio and check threshold
        // Example: 3 positive out of 4 rated = 0.75 (75%) → passes 60% threshold
        let goodFeedbackRatio = Double(positiveFeedbackCount) / Double(ratedWorkoutsCount)
        guard goodFeedbackRatio >= OverloadConstants.goodFeedbackThreshold else { return nil }
        
        // Get the maximum weight used in the most recent workout
        guard let mostRecentWorkout = recentWorkouts.first,
              let mostRecentExercise = mostRecentWorkout.completedExercises.first(where: { $0.name == exerciseName }),
              let maxRecentWeight = mostRecentExercise.sets.map({ $0.weight }).max() else {
            return nil
        }
        
        // Validate that current weight is usable (non-zero positive value)
        guard maxRecentWeight > 0 else { return nil }
        
        // Step 8: Check for recent weight increase to avoid stacking suggestions
        // If user already increased weight in the last 2 workouts, let them adapt first
        // This prevents the algorithm from constantly suggesting increases
        let lastTwoWorkouts = recentWorkouts.prefix(2)
        var hasRecentIncrease = false
        
        if lastTwoWorkouts.count == 2,
           let workout1 = lastTwoWorkouts.first,  // Most recent
           let workout2 = lastTwoWorkouts.last {   // Second most recent
            
            if let exercise1 = workout1.completedExercises.first(where: { $0.name == exerciseName }),
               let exercise2 = workout2.completedExercises.first(where: { $0.name == exerciseName }),
               let maxWeight1 = exercise1.sets.map({ $0.weight }).max(),
               let maxWeight2 = exercise2.sets.map({ $0.weight }).max() {
                // Compare: was the most recent workout heavier than the one before?
                hasRecentIncrease = maxWeight1 > maxWeight2
            }
        }
        
        // Skip suggestion if user just increased weight - allow adaptation time
        if hasRecentIncrease {
            return nil
        }
        
        // Step 9: Determine increase percentage based on feedback quality
        // ≥80% positive feedback → aggressive 5% increase (user is clearly under-challenged)
        // 60-79% positive → moderate 2.5% increase (standard progression)
        let increasePercentage = goodFeedbackRatio >= OverloadConstants.excellentFeedbackThreshold ?
            OverloadConstants.aggressiveIncrease :  // 5% for excellent feedback
            OverloadConstants.moderateIncrease      // 2.5% for good feedback
        
        // Step 10: Calculate raw suggested weight
        // Example: 100kg × 1.025 = 102.5kg (moderate) or 100kg × 1.05 = 105kg (aggressive)
        let rawSuggestedWeight = maxRecentWeight * (1 + increasePercentage)
        
        // Step 11: Round up to the nearest available weight increment
        // This accounts for real-world plate availability (e.g., can't load 102.3kg)
        // Always round UP to ensure we're actually suggesting an increase
        let increment = max(0.0001, smallestWeightIncrement) // Guard against division by zero
        let roundedSuggestedWeight = (rawSuggestedWeight / increment).rounded(.up) * increment
        
        // Step 12: Validate that rounding produced a meaningful increase
        // If the suggested weight rounds to the same as current, skip the suggestion
        // Using small epsilon (0.0001) to handle floating-point comparison
        if roundedSuggestedWeight <= maxRecentWeight + 0.0001 {
            return nil
        }
        
        // Calculate actual percentage increase after rounding
        // This may differ from the target percentage due to rounding
        let roundedIncreasePercentage = (roundedSuggestedWeight - maxRecentWeight) / maxRecentWeight
        
        return (suggestedWeight: roundedSuggestedWeight, percentageIncrease: roundedIncreasePercentage)
    }
    
    // MARK: Deload Detection Algorithm
    
    /// Determines if an exercise should have a deload week based on fatigue signals.
    ///
    /// ## Algorithm Overview
    ///
    /// A deload is recommended when the user shows signs of accumulated fatigue:
    /// - Consistently struggling (poor feedback) AND
    /// - Not making progress (stagnation) OR training too frequently
    ///
    /// ## Deload Triggers
    ///
    /// ### Trigger A: Stagnation + Poor Feedback
    /// ```
    /// Conditions:
    /// - 4+ workouts in the last 28 days (4-week window)
    /// - Weight hasn't increased more than 5% from start to end of window
    /// - ≥50% of recent feedback is hard or veryHard
    ///
    /// Rationale: If training consistently but not progressing and feeling bad,
    /// accumulated fatigue is likely limiting performance.
    /// ```
    ///
    /// ### Trigger B: Overtraining + Poor Feedback
    /// ```
    /// Conditions:
    /// - 21+ workouts in the last 21 days (daily training for 3 weeks)
    /// - ≥50% of recent feedback is hard or veryHard
    ///
    /// Rationale: Extremely high frequency + poor feedback = overreaching.
    /// Recovery time is needed before performance degrades further.
    /// ```
    ///
    /// ## Why Poor Feedback is Required
    ///
    /// Poor feedback is a prerequisite for both triggers because:
    /// - Stagnation alone might be intentional (maintenance phase)
    /// - High frequency alone might be sustainable for some users
    /// - Subjective strain confirms objective data
    ///
    /// - Parameters:
    ///   - exerciseName: The exact name of the exercise to analyze.
    ///   - history: The complete workout history array.
    /// - Returns: `true` if a deload week is recommended, `false` otherwise.
    func shouldDeload(for exerciseName: String, in history: [WorkoutLog]) -> Bool {
        // Filter to only workouts containing this exercise
        let exerciseHistory = getHistory(for: exerciseName, in: history)
        
        // Require minimum 4 workouts for meaningful stagnation analysis
        guard exerciseHistory.count >= 4 else { return false }
        
        // PREREQUISITE: Check for poor feedback first
        // Both deload triggers require poor feedback as a confirming signal
        let recentFeedback = exerciseHistory
            .sorted(by: { $0.date > $1.date })  // Most recent first
            .prefix(OverloadConstants.recentFeedbackSample)  // Last 3 workouts
            .compactMap { workout -> FeedbackRating? in
                // Extract feedback rating for this specific exercise
                workout.completedExercises.first(where: { $0.name == exerciseName })?.feedback
            }
        
        // Calculate if user has been struggling recently
        // Poor feedback = hard or veryHard ratings
        let hasPoorFeedback: Bool = {
            // Need at least 2 feedback ratings to establish a pattern
            guard recentFeedback.count >= 2 else { return false }
            
            // Count how many recent workouts felt hard/veryHard
            let poorFeedbackCount = recentFeedback.filter { $0 == .hard || $0 == .veryHard }.count
            
            // Check if ≥50% of recent feedback is poor
            // Example: 2 poor out of 3 = 0.67 (67%) → exceeds 50% threshold
            return Double(poorFeedbackCount) / Double(recentFeedback.count) >= OverloadConstants.poorFeedbackFractionThreshold
        }()
        
        // TRIGGER A: Stagnation Detection
        // Check for no progress in 4+ weeks combined with poor feedback
        // Calculate the 4-week stagnation window (28 days back from now)
        let fourWeeksAgo = Date().addingTimeInterval(-OverloadConstants.stagnationWindow)
        let progressWindow = exerciseHistory.filter { $0.date > fourWeeksAgo }
        
        // Stagnation check: 4+ workouts in window, no meaningful weight increase
        if progressWindow.count >= 4 && hasPoorFeedback {
            // Sort by date (oldest first) to compare start vs end of window
            let sortedProgress = progressWindow.sorted(by: { $0.date < $1.date })
            
            if let firstWorkout = sortedProgress.first,   // Oldest in window
               let lastWorkout = sortedProgress.last,      // Most recent
               let firstExercise = firstWorkout.completedExercises.first(where: { $0.name == exerciseName }),
               let lastExercise = lastWorkout.completedExercises.first(where: { $0.name == exerciseName }),
               let firstMaxWeight = firstExercise.sets.map({ $0.weight }).max(),
               let lastMaxWeight = lastExercise.sets.map({ $0.weight }).max() {
                
                // Check if weight hasn't increased more than 5% (stagnation tolerance)
                // Example: Started at 100kg, now at 104kg = 4% increase → STAGNANT
                // Example: Started at 100kg, now at 106kg = 6% increase → NOT stagnant
                if lastMaxWeight <= firstMaxWeight * (1 + OverloadConstants.stagnationTolerance) {
                    // Stagnation detected + poor feedback = recommend deload
                    return true
                }
            }
        }
        
        // TRIGGER B: Overtraining Detection
        // Check for excessively high training frequency combined with poor feedback
        // Calculate the 3-week high-frequency window (21 days back from now)
        let threeWeeksAgo = Date().addingTimeInterval(-OverloadConstants.highFrequencyWindow)
        let highFrequencyWorkouts = exerciseHistory.filter { $0.date > threeWeeksAgo }
        
        // High frequency check: 21+ workouts in 21 days = daily training
        // Combined with poor feedback, this indicates overreaching
        if highFrequencyWorkouts.count >= OverloadConstants.highFrequencyThreshold && hasPoorFeedback {
            // Overtraining detected + poor feedback = recommend deload
            return true
        }
        
        // Neither trigger met - no deload recommended
        return false
    }
    
    // MARK: Improvement Tracking
    
    /// Calculates the percentage improvement in max weight over the last N workouts.
    ///
    /// ## Calculation Method
    ///
    /// ```
    /// Improvement % = ((newestMaxWeight - oldestMaxWeight) / oldestMaxWeight) × 100
    /// ```
    ///
    /// ## Example
    ///
    /// ```
    /// 4 workouts with max weights: [100kg, 102.5kg, 102.5kg, 105kg]
    ///                                ↑ oldest              newest ↑
    ///
    /// Improvement = ((105 - 100) / 100) × 100 = 5%
    /// ```
    ///
    /// ## Use Cases
    ///
    /// - Displaying progress statistics to the user
    /// - Determining long-term trends for an exercise
    /// - Motivating users by showing tangible improvement
    ///
    /// - Parameters:
    ///   - exerciseName: The exact name of the exercise to analyze.
    ///   - history: The complete workout history array.
    ///   - workoutCount: The number of recent workouts to compare (default: 4).
    /// - Returns: The percentage improvement (can be negative), or `nil` if insufficient data.
    func getImprovementPercentage(
        for exerciseName: String,
        in history: [WorkoutLog],
        overLast workoutCount: Int = 4
    ) -> Double? {
        let exerciseHistory = getHistory(for: exerciseName, in: history)
        
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
    
    // MARK: - Private Helper Methods
    
    /// Filters workout history to only include logs containing a specific exercise.
    ///
    /// This is the foundation for all analysis methods - it extracts the relevant
    /// subset of workout history for a specific exercise.
    ///
    /// - Parameters:
    ///   - exerciseName: The exact name of the exercise (case-sensitive).
    ///   - history: The complete workout history array.
    /// - Returns: Array of `WorkoutLog` entries that include the specified exercise.
    private func getHistory(for exerciseName: String, in history: [WorkoutLog]) -> [WorkoutLog] {
        history.filter { log in
            log.completedExercises.contains(where: { $0.name == exerciseName })
        }
    }
}
