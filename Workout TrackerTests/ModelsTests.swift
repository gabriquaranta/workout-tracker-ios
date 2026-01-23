// ModelsTests.swift

import Testing
import Foundation
@testable import Workout_Tracker

// MARK: - Weekday Enum Tests (TE5)

struct WeekdayTests {
    
    // MARK: - Case Naming Tests
    
    @Test func allCases_areCorrectlyNamed() {
        let expectedCases: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        #expect(Weekday.allCases.count == 7)
        for expectedCase in expectedCases {
            #expect(Weekday.allCases.contains(expectedCase))
        }
    }
    
    @Test func rawValues_matchCalendarWeekdays() {
        // Calendar weekday: Sunday = 1, Monday = 2, etc.
        #expect(Weekday.sunday.rawValue == 1)
        #expect(Weekday.monday.rawValue == 2)
        #expect(Weekday.tuesday.rawValue == 3)
        #expect(Weekday.wednesday.rawValue == 4)
        #expect(Weekday.thursday.rawValue == 5)
        #expect(Weekday.friday.rawValue == 6)
        #expect(Weekday.saturday.rawValue == 7)
    }
    
    // MARK: - Abbreviation (shortName) Tests
    
    @Test func shortName_returnsCorrectAbbreviation() {
        #expect(Weekday.monday.shortName == "M")
        #expect(Weekday.tuesday.shortName == "T")
        #expect(Weekday.wednesday.shortName == "W")
        #expect(Weekday.thursday.shortName == "T")
        #expect(Weekday.friday.shortName == "F")
        #expect(Weekday.saturday.shortName == "S")
        #expect(Weekday.sunday.shortName == "S")
    }
    
    @Test func fullName_returnsCorrectName() {
        #expect(Weekday.monday.fullName == "Monday")
        #expect(Weekday.tuesday.fullName == "Tuesday")
        #expect(Weekday.wednesday.fullName == "Wednesday")
        #expect(Weekday.thursday.fullName == "Thursday")
        #expect(Weekday.friday.fullName == "Friday")
        #expect(Weekday.saturday.fullName == "Saturday")
        #expect(Weekday.sunday.fullName == "Sunday")
    }
    
    // MARK: - Codable Tests
    
    @Test func weekday_encodesAndDecodesCorrectly() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for weekday in Weekday.allCases {
            let data = try encoder.encode(weekday)
            let decoded = try decoder.decode(Weekday.self, from: data)
            #expect(decoded == weekday)
        }
    }
    
    @Test func weekday_encodesToRawValue() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(Weekday.monday)
        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString == "2") // Monday's raw value
    }
    
    @Test func weekday_decodesFromRawValue() throws {
        let decoder = JSONDecoder()
        let data = "6".data(using: .utf8)!
        let decoded = try decoder.decode(Weekday.self, from: data)
        #expect(decoded == .friday)
    }
    
    // MARK: - CaseIterable Tests
    
    @Test func allCases_containsAllSevenDays() {
        #expect(Weekday.allCases.count == 7)
    }
    
    @Test func allCases_iterationOrder() {
        // CaseIterable should iterate in declaration order
        let orderedCases = Array(Weekday.allCases)
        #expect(orderedCases[0] == .monday)
        #expect(orderedCases[1] == .tuesday)
        #expect(orderedCases[2] == .wednesday)
        #expect(orderedCases[3] == .thursday)
        #expect(orderedCases[4] == .friday)
        #expect(orderedCases[5] == .saturday)
        #expect(orderedCases[6] == .sunday)
    }
}

// MARK: - WorkoutSet Validation Tests (T5)

struct WorkoutSetValidationTests {
    
    // MARK: - Negative Value Clamping Tests
    
    @Test func init_withNegativeReps_clampsToZero() {
        let set = WorkoutSet(reps: -5, weight: 50.0, restTimeInSeconds: 60)
        #expect(set.reps == 0)
    }
    
    @Test func init_withNegativeWeight_clampsToZero() {
        let set = WorkoutSet(reps: 10, weight: -25.0, restTimeInSeconds: 60)
        #expect(set.weight == 0.0)
    }
    
    @Test func init_withNegativeRestTime_clampsToZero() {
        let set = WorkoutSet(reps: 10, weight: 50.0, restTimeInSeconds: -30)
        #expect(set.restTimeInSeconds == 0)
    }
    
    @Test func init_withAllNegativeValues_clampsAllToZero() {
        let set = WorkoutSet(reps: -10, weight: -100.0, restTimeInSeconds: -90)
        #expect(set.reps == 0)
        #expect(set.weight == 0.0)
        #expect(set.restTimeInSeconds == 0)
    }
    
    // MARK: - Valid Values Pass Through Tests
    
    @Test func init_withValidValues_passesThrough() {
        let set = WorkoutSet(reps: 12, weight: 80.5, restTimeInSeconds: 90)
        #expect(set.reps == 12)
        #expect(set.weight == 80.5)
        #expect(set.restTimeInSeconds == 90)
    }
    
    @Test func init_withZeroValues_passesThrough() {
        let set = WorkoutSet(reps: 0, weight: 0.0, restTimeInSeconds: 0)
        #expect(set.reps == 0)
        #expect(set.weight == 0.0)
        #expect(set.restTimeInSeconds == 0)
    }
    
    @Test func init_withDefaultValues_usesDefaults() {
        let set = WorkoutSet()
        #expect(set.reps == 10)
        #expect(set.weight == 20.0)
        #expect(set.restTimeInSeconds == 60)
    }
    
    @Test func init_withLargeValues_passesThrough() {
        let set = WorkoutSet(reps: 100, weight: 500.0, restTimeInSeconds: 600)
        #expect(set.reps == 100)
        #expect(set.weight == 500.0)
        #expect(set.restTimeInSeconds == 600)
    }
}

// MARK: - Model Equatable Conformance Tests

struct ModelEquatableTests {
    
    // MARK: - CompletedSet Equality Tests
    
    @Test func completedSet_withSameValues_areEqual() {
        let id = UUID()
        let set1 = CompletedSet(id: id, reps: 10, weight: 50.0)
        let set2 = CompletedSet(id: id, reps: 10, weight: 50.0)
        #expect(set1 == set2)
    }
    
    @Test func completedSet_withDifferentId_areNotEqual() {
        let set1 = CompletedSet(id: UUID(), reps: 10, weight: 50.0)
        let set2 = CompletedSet(id: UUID(), reps: 10, weight: 50.0)
        #expect(set1 != set2)
    }
    
    @Test func completedSet_withDifferentReps_areNotEqual() {
        let id = UUID()
        let set1 = CompletedSet(id: id, reps: 10, weight: 50.0)
        let set2 = CompletedSet(id: id, reps: 12, weight: 50.0)
        #expect(set1 != set2)
    }
    
    @Test func completedSet_withDifferentWeight_areNotEqual() {
        let id = UUID()
        let set1 = CompletedSet(id: id, reps: 10, weight: 50.0)
        let set2 = CompletedSet(id: id, reps: 10, weight: 60.0)
        #expect(set1 != set2)
    }
    
    // MARK: - CompletedExercise Equality Tests
    
    @Test func completedExercise_withSameValues_areEqual() {
        let id = UUID()
        let setId = UUID()
        let sets = [CompletedSet(id: setId, reps: 10, weight: 50.0)]
        let exercise1 = CompletedExercise(id: id, name: "Bench Press", sets: sets, feedback: .moderate)
        let exercise2 = CompletedExercise(id: id, name: "Bench Press", sets: sets, feedback: .moderate)
        #expect(exercise1 == exercise2)
    }
    
    @Test func completedExercise_withDifferentName_areNotEqual() {
        let id = UUID()
        let sets = [CompletedSet(reps: 10, weight: 50.0)]
        let exercise1 = CompletedExercise(id: id, name: "Bench Press", sets: sets)
        let exercise2 = CompletedExercise(id: id, name: "Squat", sets: sets)
        #expect(exercise1 != exercise2)
    }
    
    @Test func completedExercise_withDifferentFeedback_areNotEqual() {
        let id = UUID()
        let setId = UUID()
        let sets = [CompletedSet(id: setId, reps: 10, weight: 50.0)]
        let exercise1 = CompletedExercise(id: id, name: "Bench Press", sets: sets, feedback: .easy)
        let exercise2 = CompletedExercise(id: id, name: "Bench Press", sets: sets, feedback: .hard)
        #expect(exercise1 != exercise2)
    }
    
    @Test func completedExercise_withDifferentSets_areNotEqual() {
        let id = UUID()
        let sets1 = [CompletedSet(reps: 10, weight: 50.0)]
        let sets2 = [CompletedSet(reps: 12, weight: 60.0)]
        let exercise1 = CompletedExercise(id: id, name: "Bench Press", sets: sets1)
        let exercise2 = CompletedExercise(id: id, name: "Bench Press", sets: sets2)
        #expect(exercise1 != exercise2)
    }
    
    // MARK: - WorkoutLog Equality Tests
    
    @Test func workoutLog_withSameValues_areEqual() {
        let id = UUID()
        let date = Date()
        let exercises = [CompletedExercise(name: "Bench Press", sets: [])]
        let log1 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 3600, completedExercises: exercises, notes: "Good workout")
        let log2 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 3600, completedExercises: exercises, notes: "Good workout")
        #expect(log1 == log2)
    }
    
    @Test func workoutLog_withDifferentWorkoutName_areNotEqual() {
        let id = UUID()
        let date = Date()
        let exercises = [CompletedExercise(name: "Bench Press", sets: [])]
        let log1 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 3600, completedExercises: exercises)
        let log2 = WorkoutLog(id: id, date: date, workoutName: "Pull Day", duration: 3600, completedExercises: exercises)
        #expect(log1 != log2)
    }
    
    @Test func workoutLog_withDifferentDuration_areNotEqual() {
        let id = UUID()
        let date = Date()
        let exercises = [CompletedExercise(name: "Bench Press", sets: [])]
        let log1 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 3600, completedExercises: exercises)
        let log2 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 7200, completedExercises: exercises)
        #expect(log1 != log2)
    }
    
    @Test func workoutLog_withDifferentNotes_areNotEqual() {
        let id = UUID()
        let date = Date()
        let exercises = [CompletedExercise(name: "Bench Press", sets: [])]
        let log1 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 3600, completedExercises: exercises, notes: "Good")
        let log2 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 3600, completedExercises: exercises, notes: "Bad")
        #expect(log1 != log2)
    }
    
    @Test func workoutLog_withNilVsNonNilNotes_areNotEqual() {
        let id = UUID()
        let date = Date()
        let exercises = [CompletedExercise(name: "Bench Press", sets: [])]
        let log1 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 3600, completedExercises: exercises, notes: nil)
        let log2 = WorkoutLog(id: id, date: date, workoutName: "Push Day", duration: 3600, completedExercises: exercises, notes: "Note")
        #expect(log1 != log2)
    }
}

// MARK: - 1RM Estimation Tests (TE4)

/// Tests for 1RM calculation formulas.
/// These formulas are extracted from ExerciseDetailView for testing.
struct OneRepMaxEstimationTests {
    
    // MARK: - Formula Implementations (mirrored from ExerciseDetailView)
    
    /// Epley formula: weight * (1 + reps/30)
    private func epleyFormula(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }
    
    /// Brzycki formula: weight * (36 / (37 - reps))
    private func brzyckiFormula(weight: Double, reps: Int) -> Double {
        guard reps > 0 && reps < 37 else { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }
    
    /// Lombardi formula: weight * reps^0.10
    private func lombardiFormula(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        return weight * pow(Double(reps), 0.10)
    }
    
    /// Average of all three formulas
    private func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        let epley = epleyFormula(weight: weight, reps: reps)
        let brzycki = brzyckiFormula(weight: weight, reps: reps)
        let lombardi = lombardiFormula(weight: weight, reps: reps)
        return (epley + brzycki + lombardi) / 3.0
    }
    
    // MARK: - Epley Formula Tests
    
    @Test func epleyFormula_withZeroReps_returnsWeight() {
        let result = epleyFormula(weight: 100.0, reps: 0)
        #expect(result == 100.0)
    }
    
    @Test func epleyFormula_withOneRep_calculatesCorrectly() {
        // 100 * (1 + 1/30) = 100 * 1.0333... = 103.33...
        let result = epleyFormula(weight: 100.0, reps: 1)
        #expect(abs(result - 103.333) < 0.01)
    }
    
    @Test func epleyFormula_withTenReps_calculatesCorrectly() {
        // 100 * (1 + 10/30) = 100 * 1.333... = 133.33...
        let result = epleyFormula(weight: 100.0, reps: 10)
        #expect(abs(result - 133.333) < 0.01)
    }
    
    // MARK: - Brzycki Formula Tests
    
    @Test func brzyckiFormula_withZeroReps_returnsWeight() {
        let result = brzyckiFormula(weight: 100.0, reps: 0)
        #expect(result == 100.0)
    }
    
    @Test func brzyckiFormula_withOneRep_calculatesCorrectly() {
        // 100 * (36 / (37 - 1)) = 100 * (36/36) = 100
        let result = brzyckiFormula(weight: 100.0, reps: 1)
        #expect(result == 100.0)
    }
    
    @Test func brzyckiFormula_withTenReps_calculatesCorrectly() {
        // 100 * (36 / (37 - 10)) = 100 * (36/27) = 133.33...
        let result = brzyckiFormula(weight: 100.0, reps: 10)
        #expect(abs(result - 133.333) < 0.01)
    }
    
    @Test func brzyckiFormula_with37OrMoreReps_returnsWeight() {
        // Edge case: reps >= 37 would cause division issues
        let result37 = brzyckiFormula(weight: 100.0, reps: 37)
        let result50 = brzyckiFormula(weight: 100.0, reps: 50)
        #expect(result37 == 100.0)
        #expect(result50 == 100.0)
    }
    
    // MARK: - Lombardi Formula Tests
    
    @Test func lombardiFormula_withZeroReps_returnsWeight() {
        let result = lombardiFormula(weight: 100.0, reps: 0)
        #expect(result == 100.0)
    }
    
    @Test func lombardiFormula_withOneRep_returnsWeight() {
        // 100 * 1^0.10 = 100 * 1 = 100
        let result = lombardiFormula(weight: 100.0, reps: 1)
        #expect(result == 100.0)
    }
    
    @Test func lombardiFormula_withTenReps_calculatesCorrectly() {
        // 100 * 10^0.10 ≈ 100 * 1.2589 ≈ 125.89
        let result = lombardiFormula(weight: 100.0, reps: 10)
        #expect(abs(result - 125.89) < 0.1)
    }
    
    // MARK: - Combined 1RM Estimation Tests
    
    @Test func estimatedOneRepMax_withTenReps_calculatesAverageCorrectly() {
        // Using 100kg for 10 reps:
        // Epley: 133.33
        // Brzycki: 133.33
        // Lombardi: ~125.89
        // Average: ~130.85
        let result = estimatedOneRepMax(weight: 100.0, reps: 10)
        #expect(abs(result - 130.85) < 0.5)
    }
    
    @Test func estimatedOneRepMax_withFiveReps_calculatesCorrectly() {
        // Using 100kg for 5 reps:
        // Epley: 100 * (1 + 5/30) = 116.67
        // Brzycki: 100 * (36/32) = 112.5
        // Lombardi: 100 * 5^0.10 ≈ 117.46
        // Average: ~115.54
        let result = estimatedOneRepMax(weight: 100.0, reps: 5)
        #expect(abs(result - 115.5) < 1.0)
    }
    
    @Test func estimatedOneRepMax_withZeroWeight_returnsZero() {
        let result = estimatedOneRepMax(weight: 0.0, reps: 10)
        #expect(result == 0.0)
    }
}

// MARK: - CompletedSet Volume Calculation Tests

struct CompletedSetVolumeTests {
    
    @Test func volume_calculatesCorrectly() {
        let set = CompletedSet(reps: 10, weight: 50.0)
        #expect(set.volume == 500.0)
    }
    
    @Test func volume_withZeroReps_returnsZero() {
        let set = CompletedSet(reps: 0, weight: 50.0)
        #expect(set.volume == 0.0)
    }
    
    @Test func volume_withZeroWeight_returnsZero() {
        let set = CompletedSet(reps: 10, weight: 0.0)
        #expect(set.volume == 0.0)
    }
}

// MARK: - CompletedExercise Total Volume Tests

struct CompletedExerciseTotalVolumeTests {
    
    @Test func totalVolume_sumsAllSetVolumes() {
        let sets = [
            CompletedSet(reps: 10, weight: 50.0),  // 500
            CompletedSet(reps: 8, weight: 60.0),   // 480
            CompletedSet(reps: 6, weight: 70.0)    // 420
        ]
        let exercise = CompletedExercise(name: "Bench Press", sets: sets)
        #expect(exercise.totalVolume == 1400.0)
    }
    
    @Test func totalVolume_withEmptySets_returnsZero() {
        let exercise = CompletedExercise(name: "Bench Press", sets: [])
        #expect(exercise.totalVolume == 0.0)
    }
    
    @Test func totalVolume_withSingleSet_returnsSetVolume() {
        let sets = [CompletedSet(reps: 12, weight: 40.0)]
        let exercise = CompletedExercise(name: "Curl", sets: sets)
        #expect(exercise.totalVolume == 480.0)
    }
}

// MARK: - FeedbackRating Tests

struct FeedbackRatingTests {
    
    @Test func allCases_containsFiveRatings() {
        #expect(FeedbackRating.allCases.count == 5)
    }
    
    @Test func rawValues_areCorrectEmojis() {
        #expect(FeedbackRating.veryEasy.rawValue == "😄")
        #expect(FeedbackRating.easy.rawValue == "🙂")
        #expect(FeedbackRating.moderate.rawValue == "😐")
        #expect(FeedbackRating.hard.rawValue == "🥵")
        #expect(FeedbackRating.veryHard.rawValue == "💀")
    }
    
    @Test func id_matchesRawValue() {
        for rating in FeedbackRating.allCases {
            #expect(rating.id == rating.rawValue)
        }
    }
    
    @Test func feedbackRating_encodesAndDecodesCorrectly() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for rating in FeedbackRating.allCases {
            let data = try encoder.encode(rating)
            let decoded = try decoder.decode(FeedbackRating.self, from: data)
            #expect(decoded == rating)
        }
    }
}
