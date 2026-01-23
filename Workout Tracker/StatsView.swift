//
//  StatsView.swift
//  Workout Tracker
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: WorkoutStore

    @State private var searchText = ""
    @State private var showSettings = false
    @State private var exerciseToDelete: ExerciseToDelete? = nil
    @State private var showLog = false

    private var filteredExerciseNames: [String] {
        let allNames = store.history.flatMap { $0.completedExercises.map(\.name) }
        let uniqueNames = Set(allNames).sorted()
        guard !searchText.isEmpty else { return uniqueNames }
        return uniqueNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView(
                        "No Workout History",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Complete a workout to see your stats here.")
                    )
                    .navigationTitle("Stats")
                } else {
                    List {
                        Section {
                            WorkoutLogButton {
                                showLog = true
                            }
                            .cardStyle()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                        Section(header: Text("Exercise Stats")) {
                            ForEach(filteredExerciseNames, id: \.self) { exerciseName in
                                ExerciseStatRow(
                                    exerciseName: exerciseName,
                                    onDelete: { exerciseToDelete = ExerciseToDelete(name: exerciseName) }
                                )
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
                    .alert(item: $exerciseToDelete) { item in
                        Alert(
                            title: Text("Delete all history for this exercise?"),
                            message: Text("This will remove all stats and history for this exercise. This cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                store.deleteHistory(for: item.name)
                                exerciseToDelete = nil
                            },
                            secondaryButton: .cancel {
                                exerciseToDelete = nil
                            }
                        )
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
                    .accessibilityLabel("Settings")
                }
            }
        }
    }
}

// MARK: - Helper Types

private struct ExerciseToDelete: Identifiable {
    let name: String
    var id: String { name }
}

// MARK: - Subviews

private struct WorkoutLogButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.accentColor)
                Text("Your Workout Log")
                    .font(.headline)
                Spacer()
            }
            .padding()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View your workout log")
    }
}

private struct ExerciseStatRow: View {
    let exerciseName: String
    var onDelete: () -> Void

    var body: some View {
        NavigationLink {
            ExerciseDetailView(exerciseName: exerciseName)
        } label: {
            Text(exerciseName)
                .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete all history for \(exerciseName)")
        }
    }
}
