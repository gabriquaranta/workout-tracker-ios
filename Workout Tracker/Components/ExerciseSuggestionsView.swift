//
//  ExerciseSuggestionsView.swift
//  Workout Tracker
//

import SwiftUI

// MARK: - Exercise Suggestions View

/// A reusable view component that displays autocomplete suggestions for exercise names.
/// Use this wherever you need to show a list of tappable exercise name suggestions.
struct ExerciseSuggestionsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    /// Vertical spacing between suggestion items
    var itemSpacing: CGFloat = 4
    
    /// Vertical padding inside each suggestion button
    var itemVerticalPadding: CGFloat = 4
    
    /// Horizontal padding inside each suggestion button
    var itemHorizontalPadding: CGFloat = 8
    
    /// Corner radius of suggestion items
    var itemCornerRadius: CGFloat = 6
    
    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: itemSpacing) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        onSelect(suggestion)
                    }) {
                        HStack {
                            Text(suggestion)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, itemVerticalPadding)
                    .padding(.horizontal, itemHorizontalPadding)
                    .background(Color(.systemGray6))
                    .cornerRadius(itemCornerRadius)
                }
            }
        }
    }
}

// MARK: - Convenience Initializer

extension ExerciseSuggestionsView {
    /// Creates an ExerciseSuggestionsView with compact styling.
    /// Suitable for inline use within form fields.
    static func compact(
        suggestions: [String],
        onSelect: @escaping (String) -> Void
    ) -> ExerciseSuggestionsView {
        var view = ExerciseSuggestionsView(suggestions: suggestions, onSelect: onSelect)
        view.itemSpacing = 2
        view.itemVerticalPadding = 2
        view.itemHorizontalPadding = 6
        view.itemCornerRadius = 4
        return view
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        Text("Standard Style")
            .font(.headline)
        ExerciseSuggestionsView(
            suggestions: ["Bench Press", "Bicep Curls", "Bulgarian Split Squats"],
            onSelect: { _ in }
        )
        
        Divider()
        
        Text("Compact Style")
            .font(.headline)
        ExerciseSuggestionsView.compact(
            suggestions: ["Deadlift", "Dumbbell Rows"],
            onSelect: { _ in }
        )
    }
    .padding()
}
