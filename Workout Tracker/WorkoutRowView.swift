//
//  WorkoutRowView.swift
//  Workout Tracker
//

import SwiftUI

struct WorkoutRowView: View {
    
    // MARK: - Properties
    
    @Binding var workout: Workout
    @Binding var path: NavigationPath
    @EnvironmentObject var store: WorkoutStore
    @State private var isExpanded = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Today's workout indicator
            if store.isWorkoutScheduledForToday(workout) {
                HStack {
                    Text("🏋️ Today's Workout:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.bottom, -4)
            }
            
            HStack(spacing: 8) {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    HStack {
                        Text(workout.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                HStack(spacing: 8) {
                    Button { path.append(workout) } label: { Image(systemName: "pencil") }
                        .tint(.accentColor)
                    Button { path.append(workout.id.uuidString) } label: { Image(systemName: "play.fill") }
                        .tint(.green)
                }
                .buttonStyle(.bordered)
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(workout.exercises) { exercise in
                        HStack(spacing: 8) {
                            Circle().frame(width: 6, height: 6).foregroundColor(.secondary.opacity(0.5))
                            Text(exercise.name)
                            Spacer()
                            if !exercise.sets.isEmpty {
                                let firstSet = exercise.sets[0]
                                Text("\(exercise.sets.count) × \(firstSet.reps) × \(Int(firstSet.weight))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.leading, 8)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
