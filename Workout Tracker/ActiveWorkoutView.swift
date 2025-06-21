// ActiveWorkoutView.swift

import SwiftUI
import UserNotifications

struct ActiveWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    
    let workout: Workout
    @State private var completedSets: [UUID: CompletedSet] = [:]
    @State private var workoutStartTime = Date()
    @State private var workoutTimer: Timer?
    @State private var totalElapsedTime: TimeInterval = 0
    
    @State private var uiRestTimer: Timer?
    @State private var restTimeRemaining: Int = 0
    @State private var isResting = false
    
    @State private var showCompletionAlert = false
    @State private var finalLog: WorkoutLog?
    
    private let restNotificationIdentifier = "workout_rest_notification"

    var body: some View {
        VStack {
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

            List {
                ForEach(workout.exercises) { exercise in
                    Section(header: Text(exercise.name).font(.title2)) {
                        // Display header for the columns
                        HStack {
                            Spacer().frame(width: 40) // Spacer for the set number circle
                            Text("Reps").frame(maxWidth: .infinity)
                            Text("Weight").frame(maxWidth: .infinity)
                            Text("Rest").frame(maxWidth: .infinity)
                            Spacer().frame(width: 40) // Spacer for the checkmark
                        }
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        
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
        .onDisappear(perform: stopAllTimersAndNotifications)
        .alert("Workout Completed!", isPresented: $showCompletionAlert, presenting: finalLog) { log in
            Button("OK") { dismiss() }
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
    
    private func stopAllTimersAndNotifications() {
        workoutTimer?.invalidate()
        uiRestTimer?.invalidate()
        workoutTimer = nil
        uiRestTimer = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restNotificationIdentifier])
    }
    
    private func completeSet(set: WorkoutSet) {
        completedSets[set.id] = CompletedSet(reps: set.reps, weight: set.weight)
        restTimeRemaining = set.restTimeInSeconds
        if restTimeRemaining > 0 {
            scheduleRestNotification(in: TimeInterval(restTimeRemaining))
            withAnimation { isResting = true }
            uiRestTimer?.invalidate()
            uiRestTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if restTimeRemaining > 0 {
                    restTimeRemaining -= 1
                } else {
                    uiRestTimer?.invalidate()
                    withAnimation { isResting = false }
                }
            }
        }
    }
    
    private func scheduleRestNotification(in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Workout Tracker"
        content.body = "Rest time Over!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: restNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Error scheduling notification: \(error)") }
        }
    }
    
    private func finishWorkout() {
        stopAllTimersAndNotifications()
        var completedExercisesLog: [CompletedExercise] = []
        for exercise in workout.exercises {
            let setsForThisExercise = exercise.sets.compactMap { completedSets[$0.id] }
            if !setsForThisExercise.isEmpty {
                completedExercisesLog.append(CompletedExercise(name: exercise.name, sets: setsForThisExercise))
            }
        }
        let log = WorkoutLog(date: Date(), workoutName: workout.name, duration: totalElapsedTime, completedExercises: completedExercisesLog)
        self.finalLog = log
        store.addWorkoutLog(log)
        showCompletionAlert = true
    }
}


// UPDATED: This view now uses a compact, column-based layout.
struct ActiveSetRow: View {
    let setNumber: Int
    let plannedSet: WorkoutSet
    let lastPerformance: CompletedSet? // This is now unused but kept for potential future use
    let isCompleted: Bool
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            // Set Number Circle
            Text("\(setNumber)")
                .bold()
                .frame(width: 30, height: 30)
                .background(isCompleted ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(isCompleted ? .white : .primary)
                .clipShape(Circle())
                .padding(.trailing, 10)
            
            // Set Details in Columns
            Text("\(plannedSet.reps)")
                .frame(maxWidth: .infinity)
            
            Text(String(format: "%.1f", plannedSet.weight))
                .frame(maxWidth: .infinity)
                
            Text("\(plannedSet.restTimeInSeconds)s")
                .frame(maxWidth: .infinity)

            // Completion Button
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(isCompleted ? .green : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(isCompleted)
        }
        .font(.title3) // Larger font for better readability
        .multilineTextAlignment(.center)
        .padding(.vertical, 8)
    }
}
