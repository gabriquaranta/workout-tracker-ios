//
//  CardStyle.swift
//  Workout Tracker
//

import SwiftUI

// MARK: - CardStyle ViewModifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
    }
}

// MARK: - View Extension

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
