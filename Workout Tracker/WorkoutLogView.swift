import SwiftUI

struct WorkoutLogView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var showingClearAlert = false

    private var groupedLogs: [Date: [WorkoutLog]] {
        Dictionary(grouping: store.history) { log in
            Calendar.current.startOfDay(for: log.date)
        }
    }
    
    private var sortedDates: [Date] {
        groupedLogs.keys.sorted(by: >)
    }
    
    private func deleteLog(at offsets: IndexSet, date: Date) {
        guard let logs = groupedLogs[date] else { return }
        let logsToDelete = offsets.map { logs[$0] }
        store.history.removeAll { log in
            logsToDelete.contains(where: { $0.id == log.id })
        }
    }
    
    // Extract the section view to ease the compiler load
    private var logSections: some View {
        ForEach(sortedDates, id: \.self) { date in
            Section(header:
                VStack {
                    Text(date, style: .date)
                        .bold()
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            ) {
                ForEach(groupedLogs[date] ?? []) { log in
                    WorkoutLogCard(log: log)
                        .cardStyle()
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                }
                .onDelete { offsets in
                    deleteLog(at: offsets, date: date)
                }
            }
        }
    }

    var body: some View {
        List {
            if store.history.isEmpty {
                ContentUnavailableView(
                    "No Logs Yet",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Your completed workouts will appear here.")
                )
            } else {
                logSections
            }
        }
        .navigationTitle("Workout Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(store.history.isEmpty)
                .accessibilityLabel("Clear all workout history")
            }
        }
        .alert("Clear All Workout History?", isPresented: $showingClearAlert) {
            Button("Clear History", role: .destructive) {
                store.clearHistory()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All recorded stats and completed workout data will be permanently deleted. Your workout plans will not be affected.")
        }
    }
}

private struct WorkoutLogCard: View {
    let log: WorkoutLog

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(log.workoutName)
                    .font(.headline)
                Spacer()
                Text(log.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let notes = log.notes, !notes.isEmpty {
                Text(notes)
                    .font(.callout)
                    .italic()
                    .padding(.bottom, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(log.completedExercises) { exercise in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(exercise.name)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        if let feedback = exercise.feedback {
                            Text(feedback.rawValue)
                        }
                    }
                    .padding(.top, 4)
                    
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        Text("Set \(index + 1):  \(set.reps) reps at \(String(format: "%.1f", set.weight)) kg")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - CardStyle Modifier

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
    }
}

private extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}
