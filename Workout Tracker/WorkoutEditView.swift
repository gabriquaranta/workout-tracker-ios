// WorkoutEditView.swift

import SwiftUI

struct WorkoutEditView: View {
    @Binding var workout: Workout
    @State private var newExerciseName = ""

    var body: some View {
        List {
            Section(header: Text("WORKOUT NAME")) {
                TextField("e.g., Full Body 1", text: $workout.name)
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
                        TextField("Exercise Name", text: $exercise.name)
                            .font(.headline)
                    }
                }
                .onDelete { indices in
                    workout.exercises.remove(atOffsets: indices)
                }
                
                HStack {
                    TextField("New Exercise Name", text: $newExerciseName)
                    Button(action: addExercise) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newExerciseName.isEmpty)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addExercise() {
        let newExercise = Exercise(name: newExerciseName, sets: [WorkoutSet()])
        workout.exercises.append(newExercise)
        newExerciseName = ""
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
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(.callout)
                    .foregroundColor(.secondary)
                TextField("", value: $set.reps, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 50)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Wt")
                    .font(.callout)
                    .foregroundColor(.secondary)
                TextField("", value: $set.weight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 50)
            }

            HStack(alignment: .bottom, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    TextField("", value: $set.restTimeInSeconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(minWidth: 50)
                }
                Text("s")
                    .font(.callout)
                    .padding(.bottom, 6)
            }
            Spacer()
        }
    }
}
