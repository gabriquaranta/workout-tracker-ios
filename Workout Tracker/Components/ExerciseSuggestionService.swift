//
//  ExerciseSuggestionService.swift
//  Workout Tracker
//

import Foundation

// MARK: - Exercise Name Filtering

/// A shared utility for filtering exercise names based on user input.
/// Consolidates the autocomplete/suggestion logic used across the app.
enum ExerciseSuggestionService {
    
    /// Filters exercise names that contain the input text (case-insensitive),
    /// excluding exact matches.
    ///
    /// - Parameters:
    ///   - input: The user's search/filter text
    ///   - allExerciseNames: The complete list of exercise names to filter from
    /// - Returns: An array of matching exercise names, excluding exact matches
    static func filterSuggestions(
        for input: String,
        from allExerciseNames: [String]
    ) -> [String] {
        guard !input.isEmpty else {
            return []
        }
        
        let lowercasedInput = input.lowercased()
        return allExerciseNames.filter { name in
            let lowercasedName = name.lowercased()
            return lowercasedName.contains(lowercasedInput) &&
                   lowercasedName != lowercasedInput
        }
    }
    
    /// Filters exercise names using localized case-insensitive matching.
    /// Does not exclude exact matches - suitable for search interfaces.
    ///
    /// - Parameters:
    ///   - searchText: The user's search text
    ///   - exerciseNames: The list of exercise names to search
    /// - Returns: Filtered exercise names, or all names if search text is empty
    static func searchExercises(
        matching searchText: String,
        in exerciseNames: [String]
    ) -> [String] {
        guard !searchText.isEmpty else {
            return exerciseNames
        }
        
        return exerciseNames.filter { name in
            name.localizedCaseInsensitiveContains(searchText)
        }
    }
}
