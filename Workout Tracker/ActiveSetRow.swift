//
//  ActiveSetRow.swift
//  Workout Tracker
//

import SwiftUI

struct ActiveSetRow: View {
    
    // MARK: - Properties
    
    let setNumber: Int
    let liveSet: LiveWorkoutSet
    let onEdit: () -> Void
    let onComplete: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Text("\(setNumber)").bold().frame(width: 30, height: 30)
                .background(liveSet.isCompleted ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(liveSet.isCompleted ? .white : .primary).clipShape(Circle()).padding(.trailing, 10)
            Button(action: onEdit) { Text("\(liveSet.reps)").frame(maxWidth: .infinity) }.disabled(liveSet.isCompleted)
            Button(action: onEdit) { Text(String(format: "%.1f", liveSet.weight)).frame(maxWidth: .infinity) }.disabled(liveSet.isCompleted)
            Text("\(liveSet.restTimeInSeconds)s").frame(maxWidth: .infinity).foregroundColor(.secondary)
            Button(action: onComplete) { Image(systemName: "checkmark.circle").font(.title).foregroundColor(liveSet.isCompleted ? .green : .accentColor) }
                .buttonStyle(.plain).disabled(liveSet.isCompleted)
        }
        .font(.title3).buttonStyle(.plain).multilineTextAlignment(.center).padding(.vertical, 8)
    }
}
