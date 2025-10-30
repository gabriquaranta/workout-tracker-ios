// ActiveWorkoutView.swift

import SwiftUI
import UserNotifications
import ActivityKit

struct ActiveWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    
    let workout: Workout
    
    @State private var liveSetsByExercise: [UUID: [LiveWorkoutSet]] = [:]
    @State private var exerciseFeedback: [String: FeedbackRating] = [:]
    
    @State private var setBeingEdited: LiveWorkoutSet? = nil
    
    @State private var workoutStartTime = Date()
    @State private var workoutTimer: Timer?
    @State private var totalElapsedTime: TimeInterval = 0
    
    @State private var uiRestTimer: Timer?
    @State private var restTimeRemaining: Int = 0
    @State private var restEndDate: Date? = nil
    @State private var isResting = false
    
    @State private var finalLog: WorkoutLog?
    
    @State private var activity: Activity<WorkoutActivityAttributes>? = nil
    private let restNotificationIdentifier = "workout_rest_notification"

    // NEW: State for info popover
    @State private var infoPopover: SuggestionPopoverInfo? = nil

    // MARK: - Body and Sub-Views
    
    var body: some View {
        VStack {
            timerBar
            if isResting {
                restOverlay
            }
            workoutList
            finishButton
        }
        .navigationTitle(workout.name)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: setupLiveWorkout)
        .onDisappear(perform: stopAllTimersAndNotifications)
        .sheet(item: $finalLog) { log in
            WorkoutCompletionView(
                store: store,
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
    }
    
    private var timerBar: some View {
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
    }
    
    private var restOverlay: some View {
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
    
    private var workoutList: some View {
        List {
            ForEach(workout.exercises) { exercise in
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
        // ensure notification permission is requested once
        requestNotificationAuthorizationIfNeeded()
        
        // check if there's an active workout to restore
        if let activeWorkout = store.activeWorkout, activeWorkout.workoutID == workout.id {
            // restore from active workout
            liveSetsByExercise = activeWorkout.liveSetsByExercise
            exerciseFeedback = activeWorkout.exerciseFeedback
            workoutStartTime = activeWorkout.startTime
            totalElapsedTime = activeWorkout.totalElapsedTime
            isResting = activeWorkout.isResting
            restTimeRemaining = activeWorkout.restTimeRemaining
            restEndDate = activeWorkout.restEndDate
            
            // restart timers
            startWorkoutTimer()
            
            // restart rest timer if needed
            if isResting && restTimeRemaining > 0 {
                startRestTimer()
            }
        } else {
            // start new workout
            for exercise in workout.exercises {
                liveSetsByExercise[exercise.id] = exercise.sets.map { planSet in
                    LiveWorkoutSet(id: planSet.id, reps: planSet.reps, weight: planSet.weight, restTimeInSeconds: planSet.restTimeInSeconds)
                }
            }
            workoutStartTime = Date()
            startWorkoutTimer()
            
            // save initial state
            saveActiveWorkoutState()
        }
    }
    
    private func saveActiveWorkoutState() {
        let activeWorkout = ActiveWorkout(
            workoutID: workout.id,
            workoutName: workout.name,
            startTime: workoutStartTime,
            totalElapsedTime: totalElapsedTime,
            liveSetsByExercise: liveSetsByExercise,
            exerciseFeedback: exerciseFeedback,
            isResting: isResting,
            restEndDate: restEndDate,
            restTimeRemaining: restTimeRemaining
        )
        store.activeWorkout = activeWorkout
    }
    
    private func update(liveSet: LiveWorkoutSet) {
        guard let exerciseID = liveSetsByExercise.first(where: { $0.value.contains(where: { $0.id == liveSet.id }) })?.key,
              let setIndex = liveSetsByExercise[exerciseID]?.firstIndex(where: { $0.id == liveSet.id }) else {
            return
        }
        liveSetsByExercise[exerciseID]?[setIndex] = liveSet
        saveActiveWorkoutState()
    }
    
    private func completeSet(exerciseID: UUID, setID: UUID) {
        hapticFeedback(style: .light)
        guard let setIndex = liveSetsByExercise[exerciseID]?.firstIndex(where: { $0.id == setID }) else { return }
        
        liveSetsByExercise[exerciseID]?[setIndex].isCompleted = true
        let setToComplete = liveSetsByExercise[exerciseID]![setIndex]
        
        if setToComplete.restTimeInSeconds > 0 {
            let endDate = Date().addingTimeInterval(TimeInterval(setToComplete.restTimeInSeconds))
            self.restEndDate = endDate
            updateActivity(isResting: true, restEndDate: endDate)
            scheduleRestNotification(in: TimeInterval(setToComplete.restTimeInSeconds))
            withAnimation { isResting = true }
            startRestTimer()
        }
        
        saveActiveWorkoutState()
    }
    
    private func startRestTimer() {
        uiRestTimer?.invalidate()
        uiRestTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let validEndDate = self.restEndDate else {
                self.uiRestTimer?.invalidate()
                withAnimation { self.isResting = false }
                self.saveActiveWorkoutState()
                return
            }
            let remaining = Int(round(validEndDate.timeIntervalSince(Date())))
            self.restTimeRemaining = max(0, remaining)
            if self.restTimeRemaining == 0 {
                self.uiRestTimer?.invalidate()
                withAnimation { self.isResting = false }
                self.updateActivity(isResting: false, restEndDate: nil)
                self.saveActiveWorkoutState()
            }
        }
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
        let log = WorkoutLog(date: Date(), workoutName: workout.name, duration: totalElapsedTime, completedExercises: completedExercisesLog, notes: nil)
        self.finalLog = log
        stopAllTimersAndNotifications()
    }
    
    // MARK: - Haptics, Timers, Live Activities
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) { let g = UIImpactFeedbackGenerator(style: style); g.impactOccurred() }
    private func startWorkoutActivity() {
        guard activity == nil else { return } // <-- prevents duplicates
        let a = WorkoutActivityAttributes(workoutName: workout.name)
        let i = WorkoutActivityAttributes.ContentState(timerEndDate: Date.now, workoutTimerText: "00:00", isResting: false)
        do {
            activity = try Activity<WorkoutActivityAttributes>.request(attributes: a, content: .init(state: i, staleDate: nil), pushType: nil)
        } catch {
            print("Failed to start workout activity:", error)
        }
    }
    private func updateActivity(isResting: Bool, restEndDate: Date?) { Task { let s = WorkoutActivityAttributes.ContentState(timerEndDate: restEndDate ?? Date(), workoutTimerText: formattedTime(totalElapsedTime), isResting: isResting); let c = ActivityContent(state: s, staleDate: nil); await activity?.update(c) } }
    private func endWorkoutActivity() {
        Task {
            guard let a = activity else { return }
            let f = WorkoutActivityAttributes.ContentState(timerEndDate: Date(), workoutTimerText: formattedTime(totalElapsedTime), isResting: false)
            let c = ActivityContent(state: f, staleDate: nil)
            await a.end(c, dismissalPolicy: .immediate)
            // Clear local state
            await MainActor.run { activity = nil }
        }
    }
    private func formattedTime(_ interval: TimeInterval) -> String { let f = DateComponentsFormatter(); f.allowedUnits = [.hour, .minute, .second]; f.unitsStyle = .positional; f.zeroFormattingBehavior = .pad; return f.string(from: interval) ?? "00:00" }
    private func startWorkoutTimer() { 
        startWorkoutActivity() 
        workoutTimer?.invalidate()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in 
            totalElapsedTime = Date().timeIntervalSince(workoutStartTime) 
            updateActivity(isResting: false, restEndDate: nil)
            saveActiveWorkoutState()
        } 
    }
    private func stopAllTimersAndNotifications() { workoutTimer?.invalidate(); uiRestTimer?.invalidate(); workoutTimer = nil; uiRestTimer = nil; UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restNotificationIdentifier]); endWorkoutActivity() }
    private func scheduleRestNotification(in seconds: TimeInterval) { let c = UNMutableNotificationContent(); c.title = "Workout Tracker"; c.body = "Rest time Over!"; c.sound = .default; let t = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false); let r = UNNotificationRequest(identifier: restNotificationIdentifier, content: c, trigger: t); UNUserNotificationCenter.current().add(r) }
    private func requestNotificationAuthorizationIfNeeded() { 
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
}

// MARK: - Suggestion Popover Information & View

enum SuggestionPopoverInfo: Identifiable, Equatable {
    case deload(exerciseName: String)
    case overload(exerciseName: String, suggestedWeight: Double, percent: Double)
    var id: String {
        switch self {
        case .deload(let name): return "deload:\(name)"
        case .overload(let name, _, _): return "overload:\(name)"
        }
    }
}

struct SuggestionPopoverView: View {
    let info: SuggestionPopoverInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            switch info {
            case .deload(let exerciseName):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text("Deload Needed")
                            .font(.title3).bold()
                            .foregroundColor(.orange)
                        Text(exerciseName)
                            .font(.headline)
                    }
                }
                Text("You've been training hard or not progressing enough on this exercise. Consider a deload week: reduce the weight by **40-60%** to allow for recovery.")
                    .font(.body)
            case .overload(let exerciseName, let suggestedWeight, let percent):
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text("Progressive Overload")
                            .font(.title3).bold()
                            .foregroundColor(.blue)
                        Text(exerciseName)
                            .font(.headline)
                    }
                }
                Text("Based on your recent performance, try increasing the weight to:")
                    .font(.body)
                HStack {
                    Text("\(String(format: "%.1f", suggestedWeight)) kg")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                    Spacer()
                    Text("(+\(String(format: "%.1f", percent * 100))%)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Text("Make sure you maintain good form. If it feels too hard, it's okay to stay at your previous weight.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Subviews

private struct ChipView: View {
    let text: String
    let color: Color
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .foregroundColor(color)
        .background(color.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(8)
        .fixedSize()
    }
}

struct SetEditingSheetView: View {
    @State private var setCopy: LiveWorkoutSet
    let onDone: (LiveWorkoutSet) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @FocusState private var weightIsFocused: Bool
    @FocusState private var repsIsFocused: Bool

    init(setCopy: LiveWorkoutSet, onDone: @escaping (LiveWorkoutSet) -> Void) {
        self._setCopy = State(initialValue: setCopy)
        self.onDone = onDone
        self._repsText = State(initialValue: "\(setCopy.reps)")
        self._weightText = State(initialValue: String(format: "%.1f", setCopy.weight))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Edit Reps") {
                    VStack(spacing: 12) {
                        TextField("Reps", text: $repsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .focused($repsIsFocused)
                            .onSubmit {
                                applyRepsChange()
                            }
                            .onChange(of: repsIsFocused) { _, focused in
                                if !focused { applyRepsChange() }
                            }
                        Stepper("", value: $setCopy.reps, in: 0...100)
                            .labelsHidden()
                            .onChange(of: setCopy.reps) { _, newValue in
                                repsText = "\(newValue)"
                            }
                    }
                }
                Section("Edit Weight") {
                    VStack(spacing: 12) {
                        TextField("Weight (kg)", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .focused($weightIsFocused)
                            .onSubmit {
                                applyWeightChange()
                            }
                            .onChange(of: weightIsFocused) { _, focused in
                                if !focused { applyWeightChange() }
                            }
                        Stepper("", value: $setCopy.weight, in: 0...500, step: 0.5)
                            .labelsHidden()
                            .onChange(of: setCopy.weight) { _, newValue in
                                weightText = String(format: "%.1f", newValue)
                            }
                    }
                }
            }
            .navigationTitle("Edit Set").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { setCopy.wasModified = true; onDone(setCopy) } } }
        }
    }

    private func applyRepsChange() {
        if let reps = Int(repsText), reps >= 0, reps <= 100 {
            setCopy.reps = reps
            repsText = "\(reps)"
        } else {
            // revert to last valid
            repsText = "\(setCopy.reps)"
        }
    }

    private func applyWeightChange() {
        if let weight = Double(weightText), weight >= 0, weight <= 500 {
            setCopy.weight = weight
            weightText = String(format: "%.1f", weight)
        } else {
            // revert to last valid
            weightText = String(format: "%.1f", setCopy.weight)
        }
    }
}

struct ActiveSetRow: View {
    let setNumber: Int
    let liveSet: LiveWorkoutSet
    let onEdit: () -> Void
    let onComplete: () -> Void
    var body: some View {
        HStack {
            Text("\(setNumber)").bold().frame(width: 30, height: 30)
                .background(liveSet.isCompleted ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(liveSet.isCompleted ? .white : .primary).clipShape(Circle()).padding(.trailing, 10)
            Button(action: onEdit) { Text("\(liveSet.reps)").frame(maxWidth: .infinity) }.disabled(liveSet.isCompleted)
            Button(action: onEdit) { Text(String(format: "%.1f", liveSet.weight)).frame(maxWidth: .infinity) }.disabled(liveSet.isCompleted)
            Text("\(liveSet.restTimeInSeconds)s").frame(maxWidth: .infinity).foregroundColor(.secondary)
            Button(action: onComplete) { Image(systemName: "checkmark.circle").font(.title).foregroundColor(liveSet.isCompleted ? .green : .accentColor) }
                .buttonStyle(.plain).disabled(liveSet.isCompleted)
        }
        .font(.title3).buttonStyle(.plain).multilineTextAlignment(.center).padding(.vertical, 8)
    }
}

struct WorkoutCompletionView: View {
    @ObservedObject var store: WorkoutStore
    let log: WorkoutLog
    let liveSets: [UUID: [LiveWorkoutSet]]
    let workoutID: UUID
    let onFinish: (WorkoutLog) -> Void
    @State private var notes: String = ""
    @State private var changesSaved: Bool = false
    private var modifiedSets: [LiveWorkoutSet] {
        liveSets.values.flatMap { $0 }.filter { $0.wasModified }
    }
    var body: some View {
        NavigationStack {
            VStack {
                Text("Workout Completed!").font(.largeTitle).bold().padding(.top)
                List {
                    Section("Session Stats") { HStack { Text("Total Time"); Spacer(); Text(log.formattedDuration) } }
                    if !modifiedSets.isEmpty {
                        Section("Update Workout Plan?") {
                            Text("You beat your plan! Save these new values for next time?").font(.callout)
                            Button(action: {
                                store.updateWorkoutPlan(from: liveSets, for: workoutID)
                                withAnimation { changesSaved = true }
                            }) {
                                HStack {
                                    Text("Save Changes to Plan")
                                    Spacer()
                                    if changesSaved { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .tint(.blue).buttonStyle(.bordered).disabled(changesSaved)
                        }
                    }
                    Section("Workout Notes") {
                        TextField("Optional: e.g., Felt strong, gym was busy...", text: $notes, axis: .vertical).lineLimit(3...6)
                    }
                }
                .listStyle(.insetGrouped)
                Button(action: {
                    var finalLog = log
                    finalLog.notes = notes.isEmpty ? nil : notes
                    onFinish(finalLog)
                }) {
                    Text("Finish Workout").font(.headline).frame(maxWidth: .infinity)
                }
                .tint(.green).buttonStyle(.borderedProminent).padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// CORRECTED: The type is now consistently FeedbackRating
struct FeedbackView: View {
    let exerciseName: String
    let lastFeedback: FeedbackRating?
    @Binding var currentSelection: FeedbackRating?
    let onFeedbackChanged: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let last = lastFeedback { Text("Last time: \(last.rawValue)").font(.caption).foregroundColor(.secondary) }
            HStack {
                Text("How did it feel?").font(.caption); Spacer()
                ForEach(FeedbackRating.allCases) { rating in
                    Button(action: { 
                        currentSelection = (currentSelection == rating) ? nil : rating
                        onFeedbackChanged?()
                    }) {
                        Text(rating.rawValue)
                            .font(.title2)
                            .scaleEffect(currentSelection == rating ? 1.2 : 1.0)
                            .opacity(currentSelection == rating ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(), value: currentSelection)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

