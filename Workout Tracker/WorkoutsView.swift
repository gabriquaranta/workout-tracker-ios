// WorkoutsView.swift

import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var isAddingWorkout = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach($store.workouts) { $workout in
                    WorkoutRowView(workout: $workout, path: $path)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: deleteWorkout)
            }
            .listStyle(.plain)
            .navigationTitle("My Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingWorkout = true }) {
                        Label("Add Workout", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isAddingWorkout) {
                AddWorkoutView(path: $path)
            }
            .navigationDestination(for: Workout.self) { workout in
                if let index = store.workouts.firstIndex(where: { $0.id == workout.id }) {
                    WorkoutEditView(workout: $store.workouts[index])
                }
            }
            .navigationDestination(for: String.self) { workoutIdString in
                if let workoutId = UUID(uuidString: workoutIdString),
                   let workout = store.workouts.first(where: { $0.id == workoutId }) {
                    ActiveWorkoutView(workout: workout)
                }
            }
        }
    }
    
    private func deleteWorkout(at offsets: IndexSet) {
        store.workouts.remove(atOffsets: offsets)
    }
}


// UPDATED: Removed the redundant exercise preview text from the main row.
struct WorkoutRowView: View {
    @Binding var workout: Workout
    @Binding var path: NavigationPath
    @State private var isExpanded = false
    
    // REMOVED: The `exercisePreview` computed property is no longer needed.
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // This is the always-visible top row
            HStack(spacing: 8) {
                // Button to control the expansion
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    HStack {
                        Text(workout.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Image(systemName: "chevron.down") // Changed to chevron.down for better UX
                            .font(.caption.weight(.bold))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button { path.append(workout) } label: {
                        Image(systemName: "pencil")
                    }
                    .tint(.accentColor)
                    
                    Button { path.append(workout.id.uuidString) } label: {
                        Image(systemName: "play.fill")
                    }
                    .tint(.green)
                }
                .buttonStyle(.bordered)
            }
            
            // This is the collapsible content area
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(workout.exercises) { exercise in
                        HStack(spacing: 8) {
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.secondary.opacity(0.5))
                            Text(exercise.name)
                        }
                    }
                }
                .padding(.leading, 8)
                .padding(.top, 4) // Add a little space between the top row and the list
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


// This struct is unchanged but required for the file to compile
struct AddWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    @State private var newWorkoutName: String = ""
    @Binding var path: NavigationPath
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Workout Name (e.g., Push Day)", text: $newWorkoutName)
            }
            .navigationTitle("New Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let newWorkout = Workout(name: newWorkoutName, exercises: [])
                        store.workouts.append(newWorkout)
                        dismiss()
                        path.append(newWorkout)
                    }
                    .disabled(newWorkoutName.isEmpty)
                }
            }
        }
    }
}
