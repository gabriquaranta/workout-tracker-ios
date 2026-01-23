//
//  WorkoutEditView.swift
//  Workout Tracker
//

import SwiftUI

struct WorkoutEditView: View {
    @Binding var workout: Workout
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @State private var newExerciseName = ""
    @State private var filteredSuggestions: [String] = []
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var exportURL: URL? = nil

    var body: some View {
        List {
            Section(header: Text("WORKOUT NAME")) {
                TextField("e.g., Full Body 1", text: $workout.name)
            }
            
            Section(header: Text("SCHEDULE")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select days to do this workout:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            DaySelectionButton(
                                day: day,
                                isSelected: workout.scheduledDays.contains(day),
                                onTap: {
                                    if workout.scheduledDays.contains(day) {
                                        workout.scheduledDays.remove(day)
                                    } else {
                                        workout.scheduledDays.insert(day)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("EXERCISES")) {
                ForEach($workout.exercises) { $exercise in
                    DisclosureGroup {
                        ForEach($exercise.sets) { $set in
                            SetEditRow(set: $set)
                                .padding(.vertical, 4)
                        }
                        .onDelete { indices in
                            exercise.sets.remove(atOffsets: indices)
                        }
                        
                        // Progressive Overload Suggestions
                        if let suggestion = store.getProgressiveOverloadSuggestion(for: exercise.name),
                           let suggestedWeight = suggestion.suggestedWeight,
                           let percentageIncrease = suggestion.percentageIncrease {
                            HStack {
                                Image(systemName: "arrow.up.circle")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Suggested: \(String(format: "%.1f", suggestedWeight)) kg")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    Text("+\(String(format: "%.1f", percentageIncrease * 100))% increase")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Apply") {
                                    // Apply the suggested weight to the first set
                                    if let firstSetIndex = exercise.sets.indices.first {
                                        exercise.sets[firstSetIndex].weight = suggestedWeight
                                    }
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .tint(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if store.shouldDeload(exerciseName: exercise.name) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Consider Deload")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                    Text("Reduce weight by 40-60% for recovery")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // UPDATED: The logic for this button has been changed.
                        Button("Add Set") {
                            addSet(to: $exercise)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    } label: {
                        ExerciseNameField(exerciseName: $exercise.name)
                            .font(.headline)
                    }
                }
                .onDelete { indices in
                    workout.exercises.remove(atOffsets: indices)
                }
                .onMove { from, to in
                    workout.exercises.move(fromOffsets: from, toOffset: to)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("New Exercise Name", text: $newExerciseName)
                            .onChange(of: newExerciseName) { _, newValue in
                                updateSuggestions(for: newValue)
                            }
                        Button(action: addExercise) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(newExerciseName.isEmpty)
                    }
                    
                    // autocomplete suggestions
                    if !filteredSuggestions.isEmpty && !newExerciseName.isEmpty {
                        ExerciseSuggestionsView(
                            suggestions: filteredSuggestions,
                            onSelect: { suggestion in
                                newExerciseName = suggestion
                            }
                        )
                        .padding(.top, 4)
                    }
                }
            }
            // add a new section at the end for the import/export buttons
            Section {
                HStack(spacing: 8) {
                    Button {
                        exportWorkout()
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                        Text("Export")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                    .frame(height: 32)
                    
                    Button {
                        showImportPicker = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title3)
                        Text("Import")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .frame(height: 32)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            // share sheet for exporting workout
            if let exportURL = exportURL {
                ShareSheet(activityItems: [exportURL])
            } else {
                Text("error exporting workout")
            }
        }
        .sheet(isPresented: $showImportPicker) {
            DocumentPicker { url in
                handleImport(url: url)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func updateSuggestions(for input: String) {
        let allExerciseNames = store.getAllExerciseNames()
        filteredSuggestions = ExerciseSuggestionService.filterSuggestions(
            for: input,
            from: allExerciseNames
        )
    }
    
    private func addExercise() {
        let newExercise = Exercise(name: newExerciseName, sets: [WorkoutSet()])
        workout.exercises.append(newExercise)
        newExerciseName = ""
        filteredSuggestions = []
    }
    
    // NEW: Extracted the "Add Set" logic into its own function for clarity.
    private func addSet(to exercise: Binding<Exercise>) {
        // Check if there is a last set to copy from.
        if let lastSet = exercise.wrappedValue.sets.last {
            // If yes, create a new set with the same values.
            // A new UUID is generated automatically.
            let newSet = WorkoutSet(
                reps: lastSet.reps,
                weight: lastSet.weight,
                restTimeInSeconds: lastSet.restTimeInSeconds
            )
            exercise.wrappedValue.sets.append(newSet)
        } else {
            // If no, add a brand new set with the default values.
            exercise.wrappedValue.sets.append(WorkoutSet())
        }
    }

    // export workout as json to temp file
    private func exportWorkout() {
        do {
            let data = try JSONEncoder().encode(workout)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Workout-\(workout.name).json")
            try data.write(to: tempURL)
            exportURL = tempURL
        } catch {
            exportURL = nil
        }
    }

    // handle imported workout json
    private func handleImport(url: URL?) {
        guard let url = url else { return }
        do {
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder().decode(Workout.self, from: data)
            workout = imported
        } catch {
            // Import error - handled silently
        }
    }
}


struct SetEditRow: View {
    @Binding var set: WorkoutSet
    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @State private var restText: String = ""
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(.callout)
                    .foregroundColor(.secondary)
                TextField("", text: $repsText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 50)
                    .onAppear {
                        repsText = "\(set.reps)"
                    }
                    .onChange(of: repsText) { _, newValue in
                        if let reps = Int(newValue) {
                            set.reps = reps
                        } else if newValue.isEmpty {
                            set.reps = 0
                        }
                    }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Wt")
                    .font(.callout)
                    .foregroundColor(.secondary)
                TextField("", text: $weightText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 50)
                    .onAppear {
                        weightText = String(format: "%.1f", set.weight)
                    }
                    .onChange(of: weightText) { _, newValue in
                        if let weight = Double(newValue) {
                            set.weight = weight
                        } else if newValue.isEmpty {
                            set.weight = 0.0
                        }
                    }
            }

            HStack(alignment: .bottom, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    TextField("", text: $restText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(minWidth: 50)
                        .onAppear {
                            restText = "\(set.restTimeInSeconds)"
                        }
                        .onChange(of: restText) { _, newValue in
                            if let rest = Int(newValue) {
                                set.restTimeInSeconds = rest
                            } else if newValue.isEmpty {
                                set.restTimeInSeconds = 0
                            }
                        }
                }
                Text("s")
                    .font(.callout)
                    .padding(.bottom, 6)
            }
            Spacer()
        }
    }
}

struct ExerciseNameField: View {
    @Binding var exerciseName: String
    @EnvironmentObject var store: WorkoutStore
    @State private var filteredSuggestions: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Exercise Name", text: $exerciseName)
                .onChange(of: exerciseName) { _, newValue in
                    updateSuggestions(for: newValue)
                }
            
            // autocomplete suggestions for existing exercises
            if !filteredSuggestions.isEmpty && !exerciseName.isEmpty {
                ExerciseSuggestionsView.compact(
                    suggestions: filteredSuggestions,
                    onSelect: { suggestion in
                        exerciseName = suggestion
                    }
                )
            }
        }
    }
    
    private func updateSuggestions(for input: String) {
        let allExerciseNames = store.getAllExerciseNames()
        filteredSuggestions = ExerciseSuggestionService.filterSuggestions(
            for: input,
            from: allExerciseNames
        )
    }
}

struct DaySelectionButton: View {
    let day: Weekday
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(day.shortName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}
