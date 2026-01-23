//
//  WorkoutsView.swift
//  Workout Tracker
//

import SwiftUI
import Charts

struct WorkoutsView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var store: WorkoutStore
    @State private var isAddingWorkout = false
    @State private var path = NavigationPath()
    @State private var showingDeleteAlert = false
    @State private var workoutOffsetsToDelete: IndexSet?
    
    // MARK: - Computed Properties
    
    private var formattedTotalTime: String {
        let totalSeconds = store.history.reduce(0) { $0 + $1.duration }
        return DateComponentsFormatter.abbreviatedHoursMinutesString(from: totalSeconds)
    }
    
    private var averageImprovementText: String {
        let allExerciseNames = store.getAllExerciseNames()
        let improvements = allExerciseNames.compactMap { store.getImprovementPercentage(for: $0) }
        
        guard !improvements.isEmpty else { return "--" }
        
        let averageImprovement = improvements.reduce(0, +) / Double(improvements.count)
        return averageImprovement >= 0 ? 
            "+\(String(format: "%.1f", averageImprovement))%" : 
            "\(String(format: "%.1f", averageImprovement))%"
    }

    private var weekAxisFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MM/dd"
        return formatter
    }
    
    // MARK: - Body

    var body: some View {
            NavigationStack(path: $path) {
                List {
                    // Active workout resume section
                    if let activeWorkout = store.activeWorkout {
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                    Text("Active Workout")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    Spacer()
                                    Text(formattedTime(activeWorkout.totalElapsedTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(activeWorkout.workoutName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Button("Resume") {
                                        if let workout = store.workouts.first(where: { $0.id == activeWorkout.workoutID }) {
                                            path.append(workout.id.uuidString)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                    
                                    Button("End Workout") {
                                        store.clearActiveWorkout()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                    
                    // UPDATED: The stats bar is now the first "row" of the list.
                    // This gives us complete control over its background.
                    HStack(spacing: 20) {
                        StatPillView(value: "\(store.history.count)", label: "Workouts")
                        Divider().frame(height: 30)
                        StatPillView(value: formattedTotalTime, label: "Total Time")
                        Divider().frame(height: 30)
                        StatPillView(value: averageImprovementText, label: "Avg Progress")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    // These modifiers make this row look like a floating header.
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    if !store.getWeeklyVolumeData().isEmpty {
                        let weeklyVolumeData = store.getWeeklyVolumeData()
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Weekly Volume")
                                    .font(.headline)
                                Spacer()
                                Text("kg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Chart(weeklyVolumeData) { point in
                                LineMark(
                                    x: .value("Week", point.weekStart),
                                    y: .value("Total Volume", point.totalVolume)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.accentColor)

                                PointMark(
                                    x: .value("Week", point.weekStart),
                                    y: .value("Total Volume", point.totalVolume)
                                )
                                .foregroundStyle(Color.accentColor)
                                .symbolSize(40)
                            }
                            .chartXAxis {
                                let formatter = weekAxisFormatter
                                AxisMarks(values: weeklyVolumeData.map { $0.weekStart }) { value in
                                    AxisGridLine()
                                    if let date = value.as(Date.self) {
                                        AxisValueLabel(formatter.string(from: date))
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 140)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    // The workouts start from the next row.
                    ForEach($store.workouts) { $workout in
                        WorkoutRowView(workout: $workout, path: $path)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteWorkout)
                    .onMove(perform: moveWorkout)
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
                .alert("Delete Workout?", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        confirmDeleteWorkout()
                    }
                    Button("Cancel", role: .cancel) { 
                        workoutOffsetsToDelete = nil
                    }
                } message: {
                    Text("This will permanently delete the selected workout and cannot be undone.")
                }
            }
        }
    
    // MARK: - Private Methods
    
    private func deleteWorkout(at offsets: IndexSet) {
        workoutOffsetsToDelete = offsets
        showingDeleteAlert = true
    }
    
    private func confirmDeleteWorkout() {
        if let offsets = workoutOffsetsToDelete {
            store.workouts.remove(atOffsets: offsets)
        }
        workoutOffsetsToDelete = nil
    }
    
    private func moveWorkout(from source: IndexSet, to destination: Int) {
        store.workouts.move(fromOffsets: source, toOffset: destination)
    }
    
    private func formattedTime(_ interval: TimeInterval) -> String {
        DateComponentsFormatter.positionalString(from: interval)
    }
}
