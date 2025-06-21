// StatsView.swift

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: WorkoutStore
    
    private var uniqueExerciseNames: [String] {
        let allNames = store.history.flatMap { $0.completedExercises.map { $0.name } }
        return Array(Set(allNames)).sorted()
    }
    
    var body: some View {
        NavigationStack {
            // UPDATED: The structure is changed to apply modifiers correctly.
            if uniqueExerciseNames.isEmpty {
                ContentUnavailableView(
                    "No Workout History",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Complete a workout to see your stats here.")
                )
                // Apply modifiers to this branch of the if statement
                .navigationTitle("Stats")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            WorkoutLogView()
                        } label: {
                            Label("Workout Log", systemImage: "clock.arrow.circlepath")
                        }
                    }
                }
                
            } else {
                List(uniqueExerciseNames, id: \.self) { exerciseName in
                    NavigationLink(exerciseName) {
                        ExerciseDetailView(exerciseName: exerciseName)
                    }
                }
                // Apply modifiers to THIS branch of the if statement as well
                .navigationTitle("Exercise Stats")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            WorkoutLogView()
                        } label: {
                            Label("Workout Log", systemImage: "clock.arrow.circlepath")
                        }
                    }
                }
            }
        }
    }
}
