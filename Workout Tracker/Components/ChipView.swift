//
//  ChipView.swift
//  Workout Tracker
//

import SwiftUI

// MARK: - ChipView

/// A compact chip/badge style view for displaying metadata labels.
///
/// Use this component to display small, colored tags with an icon and text.
/// Common use cases include status indicators, category labels, or metadata badges.
///
/// Example usage:
/// ```swift
/// ChipView(text: "Deload", color: .orange, systemImage: "exclamationmark.triangle.fill")
/// ChipView(text: "5 sets", color: .blue, systemImage: "number")
/// ```
struct ChipView: View {
    
    // MARK: - Properties
    
    /// The text to display in the chip
    let text: String
    
    /// The accent color for the chip (text, icon, and background tint)
    let color: Color
    
    /// SF Symbol name for the leading icon
    let systemImage: String
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .foregroundColor(color)
        .background(color.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(8)
        .fixedSize()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        ChipView(text: "Deload", color: .orange, systemImage: "exclamationmark.triangle.fill")
        ChipView(text: "5 sets", color: .blue, systemImage: "number")
        ChipView(text: "Completed", color: .green, systemImage: "checkmark.circle.fill")
        ChipView(text: "Rest Day", color: .purple, systemImage: "moon.fill")
    }
    .padding()
}
