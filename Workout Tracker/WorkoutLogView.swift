//
//  WorkoutLogView.swift
//  Workout Tracker
//
//  Created by Gabriele Quaranta on 20/06/25.
//


// WorkoutLogView.swift

import SwiftUI

struct WorkoutLogView: View {
    @EnvironmentObject var store: WorkoutStore

    var body: some View {
        // Group history by date for cleaner sections
        let groupedByDate = Dictionary(grouping: store.history) { log -> Date in
            return Calendar.current.startOfDay(for: log.date)
        }
        
        // Sort the dates so the most recent is at the top
        let sortedDates = groupedByDate.keys.sorted(by: >)
        
        List {
            if store.history.isEmpty {
                ContentUnavailableView("No Logs Yet", systemImage: "list.bullet.clipboard")
            } else {
                ForEach(sortedDates, id: \.self) { date in
                    Section(header: Text(date, style: .date).bold()) {
                        ForEach(groupedByDate[date] ?? []) { log in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(log.workoutName)
                                    .font(.headline)
                                Text("Duration: \(log.formattedDuration)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ForEach(log.completedExercises) { exercise in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(exercise.name)
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.top, 4)
                                        
                                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                                            Text("Set \(index + 1):  \(set.reps) reps at \(String(format: "%.1f", set.weight)) kg")
                                                .font(.callout)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("Workout Log")
    }
}