// ActiveWorkoutView.swift

import SwiftUI
import UserNotifications
import ActivityKit

struct ActiveWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    
    let workout: Workout
    @State private var completedSets: [UUID: CompletedSet] = [:]
    @State private var exerciseFeedback: [String: FeedbackRating] = [:]
    
    @State private var workoutStartTime = Date()
    @State private var workoutTimer: Timer?
    @State private var totalElapsedTime: TimeInterval = 0
    
    @State private var uiRestTimer: Timer?
    @State private var restTimeRemaining: Int = 0
    @State private var isResting = false
    
    // UPDATED: We no longer need a separate boolean for the sheet.
    // The sheet's presentation will be tied directly to this optional object.
    @State private var finalLog: WorkoutLog?
    
    @State private var activity: Activity<WorkoutActivityAttributes>? = nil
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
                        HStack {
                            Spacer().frame(width: 40)
                            Text("Reps").frame(maxWidth: .infinity)
                            Text("Weight").frame(maxWidth: .infinity)
                            Text("Rest").frame(maxWidth: .infinity)
                            Spacer().frame(width: 40)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            ActiveSetRow(
                                setNumber: index + 1,
                                plannedSet: set,
                                isCompleted: completedSets[set.id] != nil
                            ) {
                                completeSet(set: set)
                            }
                        }
                        
                        FeedbackView(
                            exerciseName: exercise.name,
                            lastFeedback: store.getLastFeedback(for: exercise.name),
                            currentSelection: $exerciseFeedback[exercise.name]
                        )
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
        // UPDATED: Use the item-based sheet modifier.
        // It presents when $finalLog is not nil and passes the unwrapped log to the content closure.
        .sheet(item: $finalLog) { log in
            WorkoutCompletionView(log: log) { notes in
                // This closure is called when the user taps "Done" in the sheet.
                var finalLogWithNotes = log
                finalLogWithNotes.notes = notes.isEmpty ? nil : notes
                store.addWorkoutLog(finalLogWithNotes)
                
                // Set finalLog back to nil to programmatically dismiss the sheet.
                finalLog = nil
                
                // Dismiss the main workout view.
                dismiss()
            }
        }
    }
    
    // MARK: - Haptics
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // MARK: - Live Activity Management
    private func startWorkoutActivity() {
        let attributes = WorkoutActivityAttributes(workoutName: workout.name)
        let initialState = WorkoutActivityAttributes.ContentState(
            timerEndDate: Date.now,
            workoutTimerText: "00:00",
            isResting: false
        )
        do {
            activity = try Activity<WorkoutActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("Live Activity started.")
        } catch (let error) {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func updateActivity(isResting: Bool, restEndDate: Date? = nil) {
        Task {
            let state = WorkoutActivityAttributes.ContentState(
                timerEndDate: restEndDate ?? Date(),
                workoutTimerText: formattedTime(totalElapsedTime),
                isResting: isResting
            )
            let content = ActivityContent(state: state, staleDate: nil)
            await activity?.update(content)
        }
    }
    
    private func endWorkoutActivity() {
        Task {
            let finalState = WorkoutActivityAttributes.ContentState(
                timerEndDate: Date.now,
                workoutTimerText: formattedTime(totalElapsedTime),
                isResting: false
            )
            let content = ActivityContent(state: finalState, staleDate: nil)
            await activity?.end(content, dismissalPolicy: .immediate)
            print("Live Activity ended.")
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
        startWorkoutActivity()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            totalElapsedTime = Date().timeIntervalSince(workoutStartTime)
            updateActivity(isResting: false)
        }
    }
    
    private func stopAllTimersAndNotifications() {
        workoutTimer?.invalidate()
        uiRestTimer?.invalidate()
        workoutTimer = nil
        uiRestTimer = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restNotificationIdentifier])
        endWorkoutActivity()
    }
    
    private func completeSet(set: WorkoutSet) {
        hapticFeedback(style: .light)
        
        completedSets[set.id] = CompletedSet(reps: set.reps, weight: set.weight)
        restTimeRemaining = set.restTimeInSeconds
        if restTimeRemaining > 0 {
            let restEndDate = Date().addingTimeInterval(TimeInterval(restTimeRemaining))
            updateActivity(isResting: true, restEndDate: restEndDate)
            scheduleRestNotification(in: TimeInterval(restTimeRemaining))
            withAnimation { isResting = true }
            uiRestTimer?.invalidate()
            uiRestTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if restTimeRemaining > 0 {
                    restTimeRemaining -= 1
                } else {
                    uiRestTimer?.invalidate()
                    withAnimation { isResting = false }
                    updateActivity(isResting: false)
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
        hapticFeedback(style: .heavy)
        
        var completedExercisesLog: [CompletedExercise] = []
        for exercise in workout.exercises {
            let setsForThisExercise = exercise.sets.compactMap { completedSets[$0.id] }
            if !setsForThisExercise.isEmpty {
                let feedback = exerciseFeedback[exercise.name]
                completedExercisesLog.append(
                    CompletedExercise(name: exercise.name, sets: setsForThisExercise, feedback: feedback)
                )
            }
        }
        
        let log = WorkoutLog(
            date: Date(),
            workoutName: workout.name,
            duration: totalElapsedTime,
            completedExercises: completedExercisesLog,
            notes: nil
        )
        
        // UPDATED: The only action needed to show the sheet is to set this variable.
        self.finalLog = log
        
        // Timers and activities are now stopped AFTER the sheet is presented.
        stopAllTimersAndNotifications()
    }
}


// These sub-views are unchanged and correct.
struct WorkoutCompletionView: View {
    let log: WorkoutLog
    let onDone: (String) -> Void
    @State private var notes: String = ""
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Workout Completed!").font(.largeTitle).bold()
                VStack {
                    Text(log.formattedDuration).font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("Total Time").font(.caption).foregroundStyle(.secondary)
                }
                List {
                    Section("Volume Per Exercise") {
                        ForEach(log.completedExercises) { exercise in
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Text("\(String(format: "%.1f", exercise.totalVolume)) kg").foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Workout Notes") {
                        TextField("Optional: e.g., Felt strong, gym was busy...", text: $notes, axis: .vertical).lineLimit(3...6)
                    }
                }
                .listStyle(.insetGrouped)
                Button(action: { onDone(notes) }) { Text("Done").font(.headline).frame(maxWidth: .infinity) }
                    .tint(.green).buttonStyle(.borderedProminent).padding()
            }
            .padding(.top)
        }
    }
}

struct FeedbackView: View {
    let exerciseName: String
    let lastFeedback: FeedbackRating?
    @Binding var currentSelection: FeedbackRating?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let last = lastFeedback {
                Text("Last time: \(last.rawValue)").font(.caption).foregroundColor(.secondary)
            }
            HStack {
                Text("How did it feel?").font(.caption)
                Spacer()
                ForEach(FeedbackRating.allCases) { rating in
                    Button(action: {
                        if currentSelection == rating { currentSelection = nil } else { currentSelection = rating }
                    }) {
                        Text(rating.rawValue).font(.title2).scaleEffect(currentSelection == rating ? 1.2 : 1.0).opacity(currentSelection == rating ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain).animation(.spring(), value: currentSelection)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct ActiveSetRow: View {
    let setNumber: Int
    let plannedSet: WorkoutSet
    let isCompleted: Bool
    let onComplete: () -> Void
    var body: some View {
        HStack {
            Text("\(setNumber)").bold().frame(width: 30, height: 30)
                .background(isCompleted ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(isCompleted ? .white : .primary).clipShape(Circle()).padding(.trailing, 10)
            Text("\(plannedSet.reps)").frame(maxWidth: .infinity)
            Text(String(format: "%.1f", plannedSet.weight)).frame(maxWidth: .infinity)
            Text("\(plannedSet.restTimeInSeconds)s").frame(maxWidth: .infinity)
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle").font(.title).foregroundColor(isCompleted ? .green : .accentColor)
            }
            .buttonStyle(.plain).disabled(isCompleted)
        }
        .font(.title3).multilineTextAlignment(.center).padding(.vertical, 8)
    }
}
