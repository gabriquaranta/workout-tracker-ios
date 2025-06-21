// WorkoutLogView.swift

import SwiftUI

struct WorkoutLogView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var showingClearAlert = false // State to control the alert

    private var groupedLogs: [Date: [WorkoutLog]] {
        Dictionary(grouping: store.history) { log in
            return Calendar.current.startOfDay(for: log.date)
        }
    }
    
    private var sortedDates: [Date] {
        groupedLogs.keys.sorted(by: >)
    }

    var body: some View {
        List {
            if store.history.isEmpty {
                ContentUnavailableView("No Logs Yet", systemImage: "list.bullet.clipboard", description: Text("Your completed workouts will appear here."))
            } else {
                ForEach(sortedDates, id: \.self) { date in
                    Section(header: Text(date, style: .date).bold()) {
                        ForEach(groupedLogs[date] ?? []) { log in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(log.workoutName)
                                        .font(.headline)
                                    Spacer()
                                    Text(log.formattedDuration)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                ForEach(log.completedExercises) { exercise in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(exercise.name)
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.top, 4)
                                        
                                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                                            Text("Set \(index + 1):  \(set.reps) reps at \(String(format: "%.1f", set.weight)) kg")
                                                .font(.callout)
                                                .foregroundStyle(.secondary)
                                                .padding(.leading, 8)
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
        .navigationBarTitleDisplayMode(.inline)
        // UPDATED: Added a toolbar with the "Clear History" button
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(store.history.isEmpty) // Disable button if there's no history
            }
        }
        // UPDATED: Added the confirmation alert
        .alert("Clear All Workout History?", isPresented: $showingClearAlert) {
            Button("Clear History", role: .destructive) {
                store.clearHistory()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All recorded stats and completed workout data will be permanently deleted. Your workout plans will not be affected.")
        }
    }
}
