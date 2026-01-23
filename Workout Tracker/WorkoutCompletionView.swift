//
//  WorkoutCompletionView.swift
//  Workout Tracker
//

import SwiftUI

struct WorkoutCompletionView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var store: WorkoutStore
    let log: WorkoutLog
    let liveSets: [UUID: [LiveWorkoutSet]]
    let workoutID: UUID
    let onFinish: (WorkoutLog) -> Void
    @State private var notes: String = ""
    @State private var changesSaved: Bool = false
    
    private var modifiedSets: [LiveWorkoutSet] {
        liveSets.values.flatMap { $0 }.filter { $0.wasModified }
    }
    
    // MARK: - Body
    
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
