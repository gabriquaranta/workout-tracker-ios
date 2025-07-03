// StatsView.swift

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: WorkoutStore
    
    @State private var searchText = ""
    @State private var showWorkoutLog = false
    
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
            if store.history.isEmpty {
                ContentUnavailableView(
                    "No Workout History",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Complete a workout to see your stats here.")
                )
                .navigationTitle("Stats")
            } else {
                List {
                    // workout log section
                    Section {
                        Button {
                            showWorkoutLog = true
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.accentColor)
                                Text("Your Workout Log")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    // exercise stats section
                    Section(header: Text("Exercise Stats")) {
                        ForEach(filteredExerciseNames, id: \.self) { exerciseName in
                            NavigationLink(exerciseName) {
                                ExerciseDetailView(exerciseName: exerciseName)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search Exercises")
                .navigationTitle("Stats")
                .background(
                    NavigationLink(destination: WorkoutLogView(), isActive: $showWorkoutLog) { EmptyView() }
                        .hidden()
                )
            }
        }
    }
}
