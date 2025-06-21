// ActiveWorkoutView.swift

import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    
    let workout: Workout
    @State private var completedSets: [UUID: CompletedSet] = [:] // [SetID: CompletedSet]
    @State private var workoutStartTime = Date()
    @State private var workoutTimer: Timer?
    @State private var totalElapsedTime: TimeInterval = 0
    
    @State private var restTimer: Timer?
    @State private var restTimeRemaining: Int = 0
    @State private var isResting = false
    
    @State private var showCompletionAlert = false
    @State private var finalLog: WorkoutLog?

    var body: some View {
        VStack {
            // Top Timer Bar
            HStack {
                Text("Total Time")
                Spacer()
                Text(formattedTime(totalElapsedTime))
            }
            .font(.headline)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Rest Timer Overlay
            if isResting {
                HStack {
                    Text("REST")
                        .font(.title).bold()
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(restTimeRemaining)s")
                        .font(.title).bold().monospacedDigit()
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color.yellow)
                .cornerRadius(10)
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity))
            }

            // Exercises List
            List {
                ForEach(workout.exercises) { exercise in
                    Section(header: Text(exercise.name).font(.title2)) {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            ActiveSetRow(
                                setNumber: index + 1,
                                plannedSet: set,
                                lastPerformance: store.getLastPerformance(for: exercise.name),
                                isCompleted: completedSets[set.id] != nil
                            ) {
                                completeSet(set: set)
                            }
                        }
                    }
                }
            }
            
            Button(action: finishWorkout) {
                Text("Finish Workout")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
        }
        .navigationTitle(workout.name)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: startWorkoutTimer)
        .onDisappear(perform: stopWorkoutTimer)
        .alert("Workout Completed!", isPresented: $showCompletionAlert, presenting: finalLog) { log in
            Button("OK") {
                dismiss()
            }
        } message: { log in
            VStack(alignment: .leading) {
                Text("Total Time: \(log.formattedDuration)\n")
                Text("Volume per Exercise:").bold()
                ForEach(log.completedExercises) { exercise in
                    Text("\(exercise.name): \(String(format: "%.1f", exercise.totalVolume)) kg")
                }
            }
        }
    }
    
    // MARK: - Timer and Logic
    
    private func formattedTime(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "00:00"
    }

    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            totalElapsedTime = Date().timeIntervalSince(workoutStartTime)
        }
    }
    
    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        restTimer?.invalidate()
        restTimer = nil
    }
    
    private func completeSet(set: WorkoutSet) {
        completedSets[set.id] = CompletedSet(reps: set.reps, weight: set.weight)
        
        // Start rest timer
        restTimeRemaining = set.restTimeInSeconds
        if restTimeRemaining > 0 {
            withAnimation {
                isResting = true
            }
            restTimer?.invalidate()
            restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if restTimeRemaining > 0 {
                    restTimeRemaining -= 1
                } else {
                    restTimer?.invalidate()
                    withAnimation {
                        isResting = false
                    }
                }
            }
        }
    }
    
    private func finishWorkout() {
        stopWorkoutTimer()
        
        var completedExercisesLog: [CompletedExercise] = []
        for exercise in workout.exercises {
            let setsForThisExercise = exercise.sets
                .compactMap { completedSets[$0.id] }
            
            if !setsForThisExercise.isEmpty {
                completedExercisesLog.append(CompletedExercise(name: exercise.name, sets: setsForThisExercise))
            }
        }
        
        let log = WorkoutLog(
            date: Date(),
            workoutName: workout.name,
            duration: totalElapsedTime,
            completedExercises: completedExercisesLog
        )
        
        self.finalLog = log
        store.addWorkoutLog(log)
        showCompletionAlert = true
    }
}

struct ActiveSetRow: View {
    let setNumber: Int
    let plannedSet: WorkoutSet
    let lastPerformance: CompletedSet?
    let isCompleted: Bool
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            // Set Number Circle
            Text("\(setNumber)")
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(isCompleted ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(isCompleted ? .white : .primary)
                .clipShape(Circle())
            
            // Set Details
            VStack(alignment: .leading) {
                // CORRECTED: Use String(format:) for weight display
                Text("\(plannedSet.reps) reps at \(String(format: "%.1f", plannedSet.weight)) kg")
                    .font(.body)
                if let last = lastPerformance {
                    Text("Last: \(last.reps) x \(String(format: "%.1f", last.weight)) kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Completion Button
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(isCompleted ? .green : .accentColor)
            }
            .buttonStyle(.plain) // Prevents the whole row from being a button
            .disabled(isCompleted)
        }
        .padding(.vertical, 5)
    }
}
