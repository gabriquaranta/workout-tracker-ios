// StatsView.swift

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: WorkoutStore
    
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var exerciseToDelete: String? = nil
    @State private var showLog = false // Controls the sheet for Workout Log

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
            Group { // Wrap the content in a Group
                if store.history.isEmpty {
                    ContentUnavailableView(
                        "No Workout History",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Complete a workout to see your stats here.")
                    )
                    .navigationTitle("Stats")
                } else {
                    List {
                        // workout log section (Button and sheet; not NavigationLink)
                        Section {
                            Button(action: {
                                showLog = true
                            }) {
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        exerciseToDelete = exerciseName
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search Exercises")
                    .navigationTitle("Stats")
                    .sheet(isPresented: $showLog) {
                        WorkoutLogView()
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsView()
                    }
                    .alert("delete all history for this exercise?", isPresented: Binding<Bool>(
                        get: { exerciseToDelete != nil },
                        set: { if !$0 { exerciseToDelete = nil } }
                    )) {
                        Button("delete", role: .destructive) {
                            if let name = exerciseToDelete {
                                store.deleteHistory(for: name)
                                exerciseToDelete = nil
                            }
                        }
                        Button("cancel", role: .cancel) { exerciseToDelete = nil }
                    } message: {
                        Text("this will remove all stats and history for this exercise. this cannot be undone.")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}
