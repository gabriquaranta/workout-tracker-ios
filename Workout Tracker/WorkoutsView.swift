// WorkoutsView.swift

import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var isAddingWorkout = false
    @State private var path = NavigationPath()
    
    private var formattedTotalTime: String {
        let totalSeconds = store.history.reduce(0) { $0 + $1.duration }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: totalSeconds) ?? "0m"
    }

    var body: some View {
            NavigationStack(path: $path) {
                List {
                    // UPDATED: The stats bar is now the first "row" of the list.
                    // This gives us complete control over its background.
                    HStack(spacing: 30) {
                        StatPillView(value: "\(store.history.count)", label: "Workouts")
                        Divider().frame(height: 30)
                        StatPillView(value: formattedTotalTime, label: "Total Time")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    // These modifiers make this row look like a floating header.
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    // The workouts start from the next row.
                    ForEach($store.workouts) { $workout in
                        WorkoutRowView(workout: $workout, path: $path)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
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


struct StatPillView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}


struct WorkoutRowView: View {
    @Binding var workout: Workout
    @Binding var path: NavigationPath
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    HStack {
                        Text(workout.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                HStack(spacing: 8) {
                    Button { path.append(workout) } label: { Image(systemName: "pencil") }
                        .tint(.accentColor)
                    Button { path.append(workout.id.uuidString) } label: { Image(systemName: "play.fill") }
                        .tint(.green)
                }
                .buttonStyle(.bordered)
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(workout.exercises) { exercise in
                        HStack(spacing: 8) {
                            Circle().frame(width: 6, height: 6).foregroundColor(.secondary.opacity(0.5))
                            Text(exercise.name)
                        }
                    }
                }
                .padding(.leading, 8)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6)) // The background is now on our view
        .cornerRadius(12)
    }
}

// AddWorkoutView is unchanged.
struct AddWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    @State private var newWorkoutName: String = ""
    @Binding var path: NavigationPath
    
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
    
    private func createBlankWorkout() {
        let newWorkout = Workout(name: newWorkoutName, exercises: [])
        store.workouts.append(newWorkout)
        dismiss()
        path.append(newWorkout)
    }
    
    private func clone(workout: Workout) {
        var newWorkout = workout
        newWorkout.id = UUID()
        newWorkout.name = "\(workout.name) (Copy)"
        store.workouts.append(newWorkout)
        dismiss()
        path.append(newWorkout)
    }
}
