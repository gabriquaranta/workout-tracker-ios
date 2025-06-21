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
                        
                        Button("Add Set") {
                            exercise.sets.append(WorkoutSet())
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
}


// UPDATED: Replaced the generic helper view with an explicit layout.
// This resolves the compiler error by being specific about the data types.
struct SetEditRow: View {
    @Binding var set: WorkoutSet
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // Reps Input (for Int)
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(.callout)
                    .foregroundColor(.secondary)
                TextField("", value: $set.reps, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 50)
            }
            
            // Weight Input (for Double)
            VStack(alignment: .leading, spacing: 2) {
                Text("Wt")
                    .font(.callout)
                    .foregroundColor(.secondary)
                TextField("", value: $set.weight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 50)
            }

            // Rest Input (for Int) with unit
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
                    .padding(.bottom, 6) // Align with the text field's baseline
            }
            Spacer()
        }
    }
}
