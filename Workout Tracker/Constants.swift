//
//  Constants.swift
//  Workout Tracker
//

import Foundation

// MARK: - Progressive Overload Constants

/// Constants used by the `ProgressiveOverloadService` for calculating weight suggestions
/// and deload recommendations.
///
/// ## Algorithm Overview
///
/// The progressive overload system analyzes workout history to determine:
/// 1. **When to suggest weight increases** - Based on consistent positive feedback
/// 2. **When to recommend deloads** - Based on stagnation or overtraining signals
///
/// ## Tuning Guidelines
///
/// - **Conservative approach**: Increase thresholds, decrease increase percentages
/// - **Aggressive approach**: Decrease thresholds, increase increase percentages
/// - **Injury prevention**: Lower `highFrequencyThreshold`, increase `stagnationWindow`
///
enum OverloadConstants {
    
    // MARK: - Progressive Overload Suggestion Thresholds
    
    /// Minimum number of workouts containing this exercise before suggestions are made.
    ///
    /// **Why 3?** Ensures the algorithm has a baseline to compare against.
    /// A single workout isn't enough to establish a pattern. Three workouts provides
    /// a small but meaningful sample to detect trends.
    ///
    /// - Impact: Higher value = more conservative, slower to suggest increases
    static let minWorkoutsForSuggestion = 3
    
    /// Minimum number of workouts with feedback ratings required for a suggestion.
    ///
    /// **Why 2?** Not all workouts may have feedback. Requiring at least 2 rated
    /// workouts ensures the algorithm has enough subjective data to make a safe
    /// recommendation.
    ///
    /// - Impact: Higher value = requires more user engagement before suggesting
    static let minRatedWorkoutsForSuggestion = 2
    
    /// Fraction of recent workouts that must have positive feedback (veryEasy, easy, moderate)
    /// before suggesting a weight increase.
    ///
    /// **Why 0.6 (60%)?** Balances progression with safety. If more than half of recent
    /// workouts felt manageable, the user is likely ready for more weight.
    ///
    /// - Calculation: `positiveFeedbackCount / ratedWorkoutsCount >= 0.6`
    /// - Impact: Lower value = more aggressive suggestions; higher = more conservative
    static let goodFeedbackThreshold = 0.6
    
    /// Fraction of positive feedback required for "aggressive" weight increases.
    ///
    /// **Why 0.8 (80%)?** When nearly all workouts feel easy, the user is clearly
    /// under-challenged and can handle a larger jump (5% vs 2.5%).
    ///
    /// - Impact: Determines when `aggressiveIncrease` vs `moderateIncrease` is used
    static let excellentFeedbackThreshold = 0.8
    
    // MARK: - Weight Increase Percentages
    
    /// Standard weight increase percentage when feedback is good but not excellent.
    ///
    /// **Why 2.5%?** Industry-standard "microloading" percentage. For a 100kg lift,
    /// this suggests 102.5kg. Small enough to be sustainable, large enough to drive
    /// adaptation.
    ///
    /// - Example: 100kg × 1.025 = 102.5kg suggested weight
    static let moderateIncrease = 0.025
    
    /// Larger weight increase percentage when feedback is excellent (≥80% positive).
    ///
    /// **Why 5%?** When the user consistently reports exercises as easy, they can
    /// handle a more aggressive jump. Still conservative compared to some programs
    /// that suggest 10% jumps.
    ///
    /// - Example: 100kg × 1.05 = 105kg suggested weight
    static let aggressiveIncrease = 0.05
    
    // MARK: - Deload Detection Thresholds
    
    /// Tolerance for considering weight as "stagnant" (no progress).
    ///
    /// **Why 5%?** Small fluctuations (1-2kg on a 40kg lift) shouldn't count as
    /// "progress." This threshold accounts for:
    /// - Rounding to available plate increments
    /// - Day-to-day performance variation
    /// - Minor technique adjustments
    ///
    /// - Calculation: `lastMaxWeight <= firstMaxWeight × 1.05` = stagnant
    static let stagnationTolerance = 0.05
    
    /// Time window (in seconds) for detecting weight stagnation.
    ///
    /// **Why 28 days (4 weeks)?** Standard mesocycle length in periodization.
    /// If weight hasn't increased meaningfully in 4 weeks despite training,
    /// accumulated fatigue may be limiting progress.
    ///
    /// - Value: 28 days × 24 hours × 60 minutes × 60 seconds = 2,419,200 seconds
    static let stagnationWindow: TimeInterval = 28 * 24 * 60 * 60
    
    /// Time window (in seconds) for detecting high training frequency.
    ///
    /// **Why 21 days (3 weeks)?** Captures recent training density. Combined with
    /// `highFrequencyThreshold`, identifies potential overreaching.
    ///
    /// - Value: 21 days × 24 hours × 60 minutes × 60 seconds = 1,814,400 seconds
    static let highFrequencyWindow: TimeInterval = 21 * 24 * 60 * 60
    
    /// Number of workouts within `highFrequencyWindow` that indicates overtraining risk.
    ///
    /// **Why 21?** Equals daily training for 3 weeks. In practice, hitting this
    /// threshold means the user is training the same exercise almost every day,
    /// which combined with poor feedback suggests overreaching.
    ///
    /// - Trigger: `workoutsInLast3Weeks >= 21 AND hasPoorFeedback → deload`
    static let highFrequencyThreshold = 21
    
    /// Number of most recent workouts to sample for feedback analysis in deload detection.
    ///
    /// **Why 3?** Balances recency with noise reduction. A single bad workout
    /// shouldn't trigger deload; 3 provides a pattern.
    ///
    /// - Used by: `shouldDeload()` to assess recent subjective strain
    static let recentFeedbackSample = 3
    
    /// Fraction of recent feedback that must be poor (hard, veryHard) to consider deload.
    ///
    /// **Why 0.5 (50%)?** If half or more of recent workouts felt hard/very hard,
    /// the user may be accumulating fatigue. Combined with stagnation or high
    /// frequency, this triggers a deload recommendation.
    ///
    /// - Calculation: `poorFeedbackCount / recentFeedbackCount >= 0.5`
    static let poorFeedbackFractionThreshold = 0.5
}
