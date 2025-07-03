// WorkoutEditView.swift

import SwiftUI

struct WorkoutEditView: View {
    @Binding var workout: Workout
    @EnvironmentObject var store: WorkoutStore
    @State private var newExerciseName = ""
    @State private var filteredSuggestions: [String] = []

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
                        
                        // UPDATED: The logic for this button has been changed.
                        Button("Add Set") {
                            addSet(to: $exercise)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    } label: {
                        ExerciseNameField(exerciseName: $exercise.name, store: store)
                            .font(.headline)
                    }
                }
                .onDelete { indices in
                    workout.exercises.remove(atOffsets: indices)
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
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    newExerciseName = suggestion
                                }) {
                                    HStack {
                                        Text(suggestion)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)

    }
    
    private func updateSuggestions(for input: String) {
        if input.isEmpty {
            filteredSuggestions = []
            return
        }
        
        let allExerciseNames = store.getAllExerciseNames()
        filteredSuggestions = allExerciseNames.filter { name in
            name.lowercased().contains(input.lowercased()) && 
            name.lowercased() != input.lowercased()
        }
        
        // debug print to see what's happening
        print("Input: '\(input)', Found suggestions: \(filteredSuggestions)")
    }
    
    private func addExercise() {
        print("Adding exercise: \(newExerciseName)")
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
    @ObservedObject var store: WorkoutStore
    @State private var filteredSuggestions: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Exercise Name", text: $exerciseName)
                .onChange(of: exerciseName) { _, newValue in
                    updateSuggestions(for: newValue)
                }
            
            // autocomplete suggestions for existing exercises
            if !filteredSuggestions.isEmpty && !exerciseName.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredSuggestions, id: \.self) { suggestion in
                        Button(action: {
                            exerciseName = suggestion
                        }) {
                            HStack {
                                Text(suggestion)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                    }
                }
            }
        }
    }
    
    private func updateSuggestions(for input: String) {
        if input.isEmpty {
            filteredSuggestions = []
            return
        }
        
        let allExerciseNames = store.getAllExerciseNames()
        filteredSuggestions = allExerciseNames.filter { name in
            name.lowercased().contains(input.lowercased()) && 
            name.lowercased() != input.lowercased()
        }
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
