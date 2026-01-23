//
//  AddWorkoutView.swift
//  Workout Tracker
//

import SwiftUI

struct AddWorkoutView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    @State private var newWorkoutName: String = ""
    @Binding var path: NavigationPath
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Create a New Workout")) {
                    TextField("Workout Name (e.g., Leg Day)", text: $newWorkoutName)
                    Button("Create and Edit") { createBlankWorkout() }
                        .disabled(newWorkoutName.isEmpty)
                }
                Section(header: Text("Or Copy an Existing Workout")) {
                    if store.workouts.isEmpty {
                        Text("No workouts to copy yet.").foregroundColor(.secondary)
                    } else {
                        ForEach(store.workouts) { workoutToCopy in
                            HStack {
                                Text(workoutToCopy.name)
                                Spacer()
                                Button("Copy") { clone(workout: workoutToCopy) }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createBlankWorkout() {
        let newWorkout = Workout(name: newWorkoutName, exercises: [])
        store.workouts.append(newWorkout)
        dismiss()
        path.append(newWorkout)
    }
    
    private func clone(workout: Workout) {
        let newWorkout = Workout(
            id: UUID(),
            name: "\(workout.name) (Copy)",
            exercises: workout.exercises,
            scheduledDays: workout.scheduledDays
        )
        store.workouts.append(newWorkout)
        dismiss()
        path.append(newWorkout)
    }
}
