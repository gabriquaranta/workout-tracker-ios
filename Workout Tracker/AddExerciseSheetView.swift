//
//  AddExerciseSheetView.swift
//  Workout Tracker
//

import SwiftUI

struct AddExerciseSheetView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss

    let workoutID: UUID
    let onAdded: (Exercise) -> Void

    @State private var selectedName: String? = nil
    @State private var newExerciseName: String = ""
    @State private var setCount: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose Existing") {
                    let names = store.getAllExerciseNames()
                    if names.isEmpty {
                        Text("No existing exercises found.")
                    } else {
                        ForEach(names, id: \.self) { name in
                            HStack {
                                Text(name)
                                Spacer()
                                if selectedName == name { Image(systemName: "checkmark") }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedName = name; newExerciseName = "" }
                        }
                    }
                }
                Section("Or Create New") {
                    TextField("New exercise name", text: $newExerciseName)
                        .onChange(of: newExerciseName) { new, _ in
                            if !new.isEmpty { selectedName = nil }
                        }
                    Stepper("Sets: \(setCount)", value: $setCount, in: 1...12)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmedSelectedName = selectedName?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let nameToUse = (trimmedSelectedName?.isEmpty == false) ? (trimmedSelectedName ?? "") : newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !nameToUse.isEmpty else { return }

                        // Try to find a template for the selected name in the store
                        var templateSets: [WorkoutSet]? = nil
                        if let sel = selectedName {
                            outer: for workout in store.workouts {
                                for ex in workout.exercises where ex.name == sel {
                                    templateSets = ex.sets
                                    break outer
                                }
                            }
                        }

                        var finalSets: [WorkoutSet]
                        if let template = templateSets, !template.isEmpty {
                            finalSets = template
                        } else {
                            finalSets = [WorkoutSet()]
                        }

                        if finalSets.count > setCount {
                            finalSets = Array(finalSets.prefix(setCount))
                        } else if finalSets.count < setCount {
                            while finalSets.count < setCount {
                                if let last = finalSets.last {
                                    finalSets.append(WorkoutSet(reps: last.reps, weight: last.weight, restTimeInSeconds: last.restTimeInSeconds))
                                } else {
                                    finalSets.append(WorkoutSet())
                                }
                            }
                        }

                        if let created = store.addExercise(named: nameToUse, sets: finalSets, to: workoutID) {
                            onAdded(created)
                        }
                        dismiss()
                    }
                    .disabled((selectedName?.isEmpty ?? true) && newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    AddExerciseSheetView(workoutID: UUID()) { _ in }
        .environmentObject(WorkoutStore.preview)
}
#endif
