// StatsView.swift

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: WorkoutStore
    
    @State private var searchText = ""
    
    private var filteredExerciseNames: [String] {
        let allNames = store.history.flatMap { $0.completedExercises.map { $0.name } }
        let uniqueNames = Array(Set(allNames)).sorted()
        
        if searchText.isEmpty {
            return uniqueNames
        } else {
            return uniqueNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            // UPDATED: The structure is corrected to apply modifiers inside each branch.
            if store.history.isEmpty {
                ContentUnavailableView(
                    "No Workout History",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Complete a workout to see your stats here.")
                )
                .navigationTitle("Stats")
                // Apply toolbar to this branch
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
                List(filteredExerciseNames, id: \.self) { exerciseName in
                    NavigationLink(exerciseName) {
                        ExerciseDetailView(exerciseName: exerciseName)
                    }
                }
                .navigationTitle("Exercise Stats")
                .searchable(text: $searchText, prompt: "Search Exercises")
                // Apply toolbar to this branch
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
