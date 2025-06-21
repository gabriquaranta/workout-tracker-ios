// ExerciseDetailView.swift

import SwiftUI
import Charts

struct ExerciseDetailView: View {
    @EnvironmentObject var store: WorkoutStore
    let exerciseName: String
    
    // UPDATED: The data point's value now represents the max set volume.
    struct VolumeDataPoint: Identifiable {
        let id = UUID()
        let workoutIndex: Int
        let maxSetVolume: Double
    }
    
    private var volumeData: [VolumeDataPoint] {
        let relevantLogs = store.history
            .filter { $0.completedExercises.contains(where: { $0.name == exerciseName }) }
            .sorted(by: { $0.date < $1.date })

        return relevantLogs.enumerated().compactMap { (index, log) in
            if let exercise = log.completedExercises.first(where: { $0.name == exerciseName }) {
                // UPDATED: Calculate the max volume of a SINGLE SET for this workout.
                let maxVolumeForThisWorkout = exercise.sets.map { Double($0.reps) * $0.weight }.max() ?? 0.0
                
                return VolumeDataPoint(
                    workoutIndex: index + 1,
                    maxSetVolume: maxVolumeForThisWorkout
                )
            }
            return nil
        }
    }
    
    // NEW: Computed property to find the single best set based on weight.
    private var recordSet: CompletedSet? {
        let allSets = store.history.flatMap { log -> [CompletedSet] in
            log.completedExercises.first { $0.name == exerciseName }?.sets ?? []
        }
        return allSets.max(by: { $0.weight < $1.weight })
    }

    private var maxSetVolumeEver: Double {
        volumeData.map { $0.maxSetVolume }.max() ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Chart
                if volumeData.count > 1 {
                    Text("Max Set Volume Over Time")
                        .font(.title2).bold()
                    
                    // UPDATED: Chart now uses maxSetVolume for the Y-axis.
                    Chart(volumeData) { dataPoint in
                        LineMark(
                            x: .value("Workout #", dataPoint.workoutIndex),
                            y: .value("Max Set Volume (kg)", dataPoint.maxSetVolume)
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Workout #", dataPoint.workoutIndex),
                            y: .value("Max Set Volume (kg)", dataPoint.maxSetVolume)
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: min(volumeData.count, 10)))
                    }
                    .frame(height: 250)
                } else {
                    ContentUnavailableView(
                        "Not Enough Data",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Complete at least two workouts with this exercise to see a chart.")
                    )
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 15) {
                    Text("Personal Records").font(.title2).bold()
                    
                    // UPDATED: Stat rows now show the new metrics.
                    StatRow(title: "Max Set Volume", value: "\(String(format: "%.1f", maxSetVolumeEver)) kg")
                    
                    if let record = recordSet {
                        StatRow(title: "Max Weight Lifted", value: "\(String(format: "%.1f", record.weight)) kg")
                        StatRow(title: "Reps at Max Weight", value: "\(record.reps) reps")
                    } else {
                        Text("No completed sets found for this exercise.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct StatRow: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}
