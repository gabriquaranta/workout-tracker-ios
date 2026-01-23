//
//  FeedbackView.swift
//  Workout Tracker
//

import SwiftUI

struct FeedbackView: View {
    
    // MARK: - Properties
    
    let exerciseName: String
    let lastFeedback: FeedbackRating?
    @Binding var currentSelection: FeedbackRating?
    let onFeedbackChanged: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let last = lastFeedback { Text("Last time: \(last.rawValue)").font(.caption).foregroundColor(.secondary) }
            HStack {
                Text("How did it feel?").font(.caption); Spacer()
                ForEach(FeedbackRating.allCases) { rating in
                    Button(action: { 
                        currentSelection = (currentSelection == rating) ? nil : rating
                        onFeedbackChanged?()
                    }) {
                        Text(rating.rawValue)
                            .font(.title2)
                            .scaleEffect(currentSelection == rating ? 1.2 : 1.0)
                            .opacity(currentSelection == rating ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(), value: currentSelection)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
