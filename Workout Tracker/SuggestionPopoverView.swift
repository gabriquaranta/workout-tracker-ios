//
//  SuggestionPopoverView.swift
//  Workout Tracker
//

import SwiftUI

// MARK: - Suggestion Popover Information & View

enum SuggestionPopoverInfo: Identifiable, Equatable {
    case deload(exerciseName: String)
    case overload(exerciseName: String, suggestedWeight: Double, percent: Double)
    var id: String {
        switch self {
        case .deload(let name): return "deload:\(name)"
        case .overload(let name, _, _): return "overload:\(name)"
        }
    }
}

struct SuggestionPopoverView: View {
    let info: SuggestionPopoverInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            switch info {
            case .deload(let exerciseName):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text("Deload Needed")
                            .font(.title3).bold()
                            .foregroundColor(.orange)
                        Text(exerciseName)
                            .font(.headline)
                    }
                }
                Text("You've been training hard or not progressing enough on this exercise. Consider a deload week: reduce the weight by **40-60%** to allow for recovery.")
                    .font(.body)
            case .overload(let exerciseName, let suggestedWeight, let percent):
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text("Progressive Overload")
                            .font(.title3).bold()
                            .foregroundColor(.blue)
                        Text(exerciseName)
                            .font(.headline)
                    }
                }
                Text("Based on your recent performance, try increasing the weight to:")
                    .font(.body)
                HStack {
                    Text("\(String(format: "%.1f", suggestedWeight)) kg")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                    Spacer()
                    Text("(+\(String(format: "%.1f", percent * 100))%)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Text("Make sure you maintain good form. If it feels too hard, it's okay to stay at your previous weight.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
