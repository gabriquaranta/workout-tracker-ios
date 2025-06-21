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
    
    @State private var uiRestTimer: Timer? // Renamed to clarify its purpose
    @State private var restTimeRemaining: Int = 0
    @State private var isResting = false
    
    @State private var showCompletionAlert = false
    @State private var finalLog: WorkoutLog?
    
    // NEW: A unique identifier for our pending rest notification
    private let restNotificationIdentifier = "workout_rest_notification"

    var body: some View {
        VStack {
            // ... (The rest of the body view is unchanged)
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
        .onDisappear(perform: stopAllTimersAndNotifications) // UPDATED
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
    
    // UPDATED: Renamed to be more descriptive
    private func stopAllTimersAndNotifications() {
        workoutTimer?.invalidate()
        uiRestTimer?.invalidate()
        workoutTimer = nil
        uiRestTimer = nil
        // NEW: Also cancel any pending rest notification if the view disappears
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restNotificationIdentifier])
    }
    
    private func completeSet(set: WorkoutSet) {
        completedSets[set.id] = CompletedSet(reps: set.reps, weight: set.weight)
        
        restTimeRemaining = set.restTimeInSeconds
        if restTimeRemaining > 0 {
            // UPDATED: Schedule the real notification first
            scheduleRestNotification(in: TimeInterval(restTimeRemaining))
            
            withAnimation { isResting = true }
            
            // This timer is now ONLY for updating the UI
            uiRestTimer?.invalidate()
            uiRestTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if restTimeRemaining > 0 {
                    restTimeRemaining -= 1
                } else {
                    uiRestTimer?.invalidate()
                    withAnimation { isResting = false }
                    // We no longer send the notification from here.
                }
            }
        }
    }
    
    // UPDATED: The notification is now scheduled with a time-based trigger.
    private func scheduleRestNotification(in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Workout Tracker"
        content.body = "Rest time Over!"
        content.sound = .default

        // The trigger is the key change: it tells the OS *when* to deliver.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        // Use a specific identifier so we can cancel it if needed.
        let request = UNNotificationRequest(identifier: restNotificationIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func finishWorkout() {
        stopAllTimersAndNotifications()
        
        var completedExercisesLog: [CompletedExercise] = []
        for exercise in workout.exercises {
            let setsForThisExercise = exercise.sets
                .compactMap { completedSets[$0.id] }
            
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


// Unchanged, required for compilation
struct ActiveSetRow: View {
    let setNumber: Int
    let plannedSet: WorkoutSet
    let lastPerformance: CompletedSet?
    let isCompleted: Bool
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(isCompleted ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(isCompleted ? .white : .primary)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text("\(plannedSet.reps) reps at \(String(format: "%.1f", plannedSet.weight)) kg")
                    .font(.body)
                if let last = lastPerformance {
                    Text("Last: \(last.reps) x \(String(format: "%.1f", last.weight)) kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(isCompleted ? .green : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(isCompleted)
        }
        .padding(.vertical, 5)
    }
}
