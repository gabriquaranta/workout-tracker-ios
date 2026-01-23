//
//  ActiveWorkoutView.swift
//  Workout Tracker
//

import SwiftUI
import UserNotifications
import ActivityKit

struct ActiveWorkoutView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    
    let workout: Workout
    
    @State private var liveSetsByExercise: [UUID: [LiveWorkoutSet]] = [:]
    @State private var exerciseFeedback: [String: FeedbackRating] = [:]
    
    @State private var setBeingEdited: LiveWorkoutSet? = nil
    
    // MARK: - Timer Manager
    @StateObject private var timerManager = WorkoutTimerManager()
    
    @State private var finalLog: WorkoutLog?
    
    @State private var activity: Activity<WorkoutActivityAttributes>? = nil
    private let restNotificationIdentifier = "workout_rest_notification"

    // NEW: State for info popover
    @State private var infoPopover: SuggestionPopoverInfo? = nil

    // NEW: show add exercise sheet
    @State private var showingAddExercise: Bool = false

    // MARK: - Save Debouncing
    
    /// Tracks the last time state was saved (for debouncing timer-based saves)
    @State private var lastSaveTime: Date = .distantPast
    
    /// Minimum interval between timer-triggered saves (in seconds)
    private let saveDebounceInterval: TimeInterval = 30

    // MARK: - Body
    
    var body: some View {
        VStack {
            timerBar
            if timerManager.isRestTimerRunning {
                restOverlay
            }
            workoutList
            finishButton
        }
        .navigationTitle(workout.name)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddExercise = true }) {
                    Image(systemName: "plus")
                    Text("Add")
                }
            }
        }
        .onAppear(perform: setupLiveWorkout)
        .onDisappear(perform: stopAllTimersAndNotifications)
        .sheet(item: $finalLog) { log in
            WorkoutCompletionView(
                log: log,
                liveSets: liveSetsByExercise,
                workoutID: workout.id,
                onFinish: { finalLogWithNotes in
                    store.addWorkoutLog(finalLogWithNotes)
                    store.clearActiveWorkout()
                    finalLog = nil
                    dismiss()
                }
            )
        }
        .sheet(item: $setBeingEdited) { setToEdit in
            SetEditingSheetView(setCopy: setToEdit) { updatedSet in
                update(liveSet: updatedSet)
                setBeingEdited = nil
            }
        }
        // NEW: Popover for overload/deload details
        .popover(item: $infoPopover) { info in
            SuggestionPopoverView(info: info)
                .frame(width: 320)
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheetView(workoutID: workout.id) { added in
                // Append to live sets for the active session
                let liveSets = added.sets.map { planSet in
                    LiveWorkoutSet(id: planSet.id, reps: planSet.reps, weight: planSet.weight, restTimeInSeconds: planSet.restTimeInSeconds)
                }
                liveSetsByExercise[added.id] = liveSets
                saveActiveWorkoutState()
                showingAddExercise = false
            }
        }
    }
    
    // MARK: - Subviews
    
    private var timerBar: some View {
        HStack {
            Text("Total Time")
            Spacer()
            Text(formattedTime(timerManager.workoutElapsedTime))
        }
        .font(.headline)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var restOverlay: some View {
        HStack {
            Text("REST")
                .font(.title).bold()
                .foregroundColor(.black)
            Spacer()
            Text("\(timerManager.restTimeRemaining)s")
                .font(.title).bold().monospacedDigit()
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.yellow)
        .cornerRadius(10)
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var workoutList: some View {
        List {
            ForEach(planExercises) { exercise in
                Section(
                    header: HStack {
                        Text(exercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        // Right-aligned compact suggestion/deload badges
                        if store.shouldDeload(exerciseName: exercise.name) {
                            // Deload has priority if both apply
                            Button(action: {
                                infoPopover = .deload(exerciseName: exercise.name)
                            }) {
                                ChipView(text: "Deload", color: .orange, systemImage: "exclamationmark.triangle.fill")
                            }
                            .buttonStyle(.plain)
                        } else if let suggestion = store.getProgressiveOverloadSuggestion(for: exercise.name),
                                  let percentageIncrease = suggestion.percentageIncrease,
                                  let suggestedWeight = suggestion.suggestedWeight {
                            Button(action: {
                                infoPopover = .overload(exerciseName: exercise.name,
                                                        suggestedWeight: suggestedWeight,
                                                        percent: percentageIncrease)
                            }) {
                                ChipView(
                                    text: "Increase",
                                    color: .blue,
                                    systemImage: "arrow.up.circle.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                ) {
                    // Column headers
                    HStack {
                        Spacer().frame(width: 40)
                        Text("Reps").frame(maxWidth: .infinity)
                        Text("Weight").frame(maxWidth: .infinity)
                        Text("Rest").frame(maxWidth: .infinity)
                        Spacer().frame(width: 40)
                    }
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    
                    if let sets = liveSetsByExercise[exercise.id] {
                        ForEach(sets.indices, id: \.self) { index in
                            let liveSet = sets[index]
                            ActiveSetRow(setNumber: index + 1, liveSet: liveSet) {
                                setBeingEdited = liveSet
                            } onComplete: {
                                completeSet(exerciseID: exercise.id, setID: liveSet.id)
                            }
                        }
                        HStack(spacing: 12) {
                            Spacer()
                            Button(action: { addSetToExercise(exerciseID: exercise.id) }) {
                                Label("Add Set", systemImage: "plus.circle")
                            }
                            .buttonStyle(.bordered)
                            Button(action: { removeLastSetFromExercise(exerciseID: exercise.id) }) {
                                Label("Remove Set", systemImage: "minus.circle")
                            }
                            .buttonStyle(.bordered)
                            .disabled(liveSetsByExercise[exercise.id]?.isEmpty ?? true)
                        }
                    }
                }
                Section {
                    FeedbackView(
                        exerciseName: exercise.name,
                        lastFeedback: store.getLastFeedback(for: exercise.name),
                        currentSelection: $exerciseFeedback[exercise.name],
                        onFeedbackChanged: {
                            saveActiveWorkoutState()
                        }
                    )
                }
            }
        }
        .listStyle(.grouped)
    }

    // Use the latest workout plan from the store if available so UI reflects additions
    private var planExercises: [Exercise] {
        if let updated = store.workouts.first(where: { $0.id == workout.id }) {
            return updated.exercises
        }
        return workout.exercises
    }
    
    private var finishButton: some View {
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
    
    // MARK: - Helper Functions
    
    private func setupLiveWorkout() {
        // Ensure notification permission is requested once
        requestNotificationAuthorizationIfNeeded()
        
        // Configure timer manager callbacks
        timerManager.onWorkoutTimerTick = { [self] in
            updateActivity(isResting: false, restEndDate: nil)
            saveActiveWorkoutStateDebounced()
        }
        timerManager.onRestTimerComplete = { [self] in
            updateActivity(isResting: false, restEndDate: nil)
            saveActiveWorkoutState()
        }
        
        // Check if there's an active workout to restore
        if let activeWorkout = store.activeWorkout, activeWorkout.workoutID == workout.id {
            // Restore from active workout
            liveSetsByExercise = activeWorkout.liveSetsByExercise
            exerciseFeedback = activeWorkout.exerciseFeedback
            timerManager.setStartTime(activeWorkout.startTime)
            timerManager.setElapsedTime(activeWorkout.totalElapsedTime)
            timerManager.setRestTimeRemaining(activeWorkout.restTimeRemaining)
            
            // Restart timers
            startWorkoutTimer()
            
            // Restart rest timer if needed
            if activeWorkout.isResting, let restEndDate = activeWorkout.restEndDate {
                timerManager.startRestTimer(endDate: restEndDate)
            }
        } else {
            // Start new workout
            for exercise in workout.exercises {
                liveSetsByExercise[exercise.id] = exercise.sets.map { planSet in
                    LiveWorkoutSet(id: planSet.id, reps: planSet.reps, weight: planSet.weight, restTimeInSeconds: planSet.restTimeInSeconds)
                }
            }
            startWorkoutTimer()
            
            // Save initial state
            saveActiveWorkoutState()
        }
    }
    
    private func saveActiveWorkoutState() {
        let activeWorkout = ActiveWorkout(
            workoutID: workout.id,
            workoutName: workout.name,
            startTime: timerManager.workoutStartTime,
            totalElapsedTime: timerManager.workoutElapsedTime,
            liveSetsByExercise: liveSetsByExercise,
            exerciseFeedback: exerciseFeedback,
            isResting: timerManager.isRestTimerRunning,
            restEndDate: timerManager.restEndDate,
            restTimeRemaining: timerManager.restTimeRemaining
        )
        store.activeWorkout = activeWorkout
        lastSaveTime = Date()
    }
    
    /// Debounced version of saveActiveWorkoutState for timer-triggered calls.
    /// Only saves if enough time has passed since the last save.
    private func saveActiveWorkoutStateDebounced() {
        guard Date().timeIntervalSince(lastSaveTime) >= saveDebounceInterval else { return }
        saveActiveWorkoutState()
    }
    
    private func update(liveSet: LiveWorkoutSet) {
        guard let exerciseID = liveSetsByExercise.first(where: { $0.value.contains(where: { $0.id == liveSet.id }) })?.key,
              let setIndex = liveSetsByExercise[exerciseID]?.firstIndex(where: { $0.id == liveSet.id }) else {
            return
        }
        liveSetsByExercise[exerciseID]?[setIndex] = liveSet
        saveActiveWorkoutState()
    }
    
    // MARK: - Private Methods

    private func addSetToExercise(exerciseID: UUID) {
        // Prefer using last live set values as template, otherwise sensible defaults
        let template = liveSetsByExercise[exerciseID]?.last
        let newSet = LiveWorkoutSet(id: UUID(), reps: template?.reps ?? 10, weight: template?.weight ?? 20.0, restTimeInSeconds: template?.restTimeInSeconds ?? 60)
        if liveSetsByExercise[exerciseID] != nil {
            liveSetsByExercise[exerciseID]?.append(newSet)
        } else {
            liveSetsByExercise[exerciseID] = [newSet]
        }
        saveActiveWorkoutState()
    }

    private func removeLastSetFromExercise(exerciseID: UUID) {
        guard var sets = liveSetsByExercise[exerciseID], !sets.isEmpty else { return }
        sets.removeLast()
        liveSetsByExercise[exerciseID] = sets
        saveActiveWorkoutState()
    }
    
    private func completeSet(exerciseID: UUID, setID: UUID) {
        hapticFeedback(style: .light)
        guard let setIndex = liveSetsByExercise[exerciseID]?.firstIndex(where: { $0.id == setID }) else { return }
        
        liveSetsByExercise[exerciseID]?[setIndex].isCompleted = true
        guard let setToComplete = liveSetsByExercise[exerciseID]?[setIndex] else { return }
        
        if setToComplete.restTimeInSeconds > 0 {
            let endDate = Date().addingTimeInterval(TimeInterval(setToComplete.restTimeInSeconds))
            updateActivity(isResting: true, restEndDate: endDate)
            scheduleRestNotification(in: TimeInterval(setToComplete.restTimeInSeconds))
            withAnimation {
                timerManager.startRestTimer(duration: setToComplete.restTimeInSeconds)
            }
        }
        
        saveActiveWorkoutState()
    }
    

    
    private func finishWorkout() {
        hapticFeedback(style: .heavy)
        var completedExercisesLog: [CompletedExercise] = []
        for exercise in workout.exercises {
            let completedLiveSets = liveSetsByExercise[exercise.id]?.filter { $0.isCompleted } ?? []
            if !completedLiveSets.isEmpty {
                let feedback = exerciseFeedback[exercise.name]
                let completedSetsForLog = completedLiveSets.map { liveSet in
                    CompletedSet(reps: liveSet.reps, weight: liveSet.weight)
                }
                completedExercisesLog.append(CompletedExercise(name: exercise.name, sets: completedSetsForLog, feedback: feedback))
            }
        }
        let log = WorkoutLog(date: Date(), workoutName: workout.name, duration: timerManager.workoutElapsedTime, completedExercises: completedExercisesLog, notes: nil)
        self.finalLog = log
        stopAllTimersAndNotifications()
    }
    
    // MARK: - Live Activities & Notifications
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) { let hapticGenerator = UIImpactFeedbackGenerator(style: style); hapticGenerator.impactOccurred() }
    private func startWorkoutActivity() {
        guard activity == nil else { return } // <-- prevents duplicates
        let workoutAttributes = WorkoutActivityAttributes(workoutName: workout.name)
        let initialState = WorkoutActivityAttributes.ContentState(timerEndDate: Date.now, workoutTimerText: "00:00", isResting: false)
        do {
            activity = try Activity<WorkoutActivityAttributes>.request(attributes: workoutAttributes, content: .init(state: initialState, staleDate: nil), pushType: nil)
        } catch {
            // Error starting workout activity - handled silently
        }
    }
    private func updateActivity(isResting: Bool, restEndDate: Date?) { Task { let contentState = WorkoutActivityAttributes.ContentState(timerEndDate: restEndDate ?? Date(), workoutTimerText: formattedTime(timerManager.workoutElapsedTime), isResting: isResting); let activityContent = ActivityContent(state: contentState, staleDate: nil); await activity?.update(activityContent) } }
    private func endWorkoutActivity() {
        Task {
            guard let currentActivity = activity else { return }
            let finalState = WorkoutActivityAttributes.ContentState(timerEndDate: Date(), workoutTimerText: formattedTime(timerManager.workoutElapsedTime), isResting: false)
            let activityContent = ActivityContent(state: finalState, staleDate: nil)
            await currentActivity.end(activityContent, dismissalPolicy: .immediate)
            // Clear local state
            await MainActor.run { activity = nil }
        }
    }
    private func formattedTime(_ interval: TimeInterval) -> String {
        DateComponentsFormatter.positionalString(from: interval)
    }
    
    private func startWorkoutTimer() {
        startWorkoutActivity()
        timerManager.startWorkoutTimer(from: timerManager.workoutStartTime)
    }
    
    private func stopAllTimersAndNotifications() {
        timerManager.invalidateAll()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restNotificationIdentifier])
        endWorkoutActivity()
    }
    private func scheduleRestNotification(in seconds: TimeInterval) { let notificationContent = UNMutableNotificationContent(); notificationContent.title = "Workout Tracker"; notificationContent.body = "Rest time Over!"; notificationContent.sound = .default; let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false); let notificationRequest = UNNotificationRequest(identifier: restNotificationIdentifier, content: notificationContent, trigger: notificationTrigger); UNUserNotificationCenter.current().add(notificationRequest) }
    private func requestNotificationAuthorizationIfNeeded() { 
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
}
