//
//  ExerciseDetailView.swift
//  Workout Tracker
//

import SwiftUI
import Charts

struct ExerciseDetailView: View {
    @EnvironmentObject var store: WorkoutStore
    let exerciseName: String

    enum ChartType: String, CaseIterable, Identifiable {
        case maxSetVolume = "Max Set Volume"
        case maxWeightBodyweight = "Max Weight / Bodyweight %"
        var id: String { rawValue }
    }
    @State private var chartType: ChartType = .maxSetVolume

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
                let maxVolumeForThisWorkout = exercise.sets.map { Double($0.reps) * $0.weight }.max() ?? 0.0
                return VolumeDataPoint(
                    workoutIndex: index + 1,
                    maxSetVolume: maxVolumeForThisWorkout
                )
            }
            return nil
        }
    }

    private var recordSet: CompletedSet? {
        let allSets = store.history.flatMap { log -> [CompletedSet] in
            log.completedExercises.first { $0.name == exerciseName }?.sets ?? []
        }
        return allSets.max(by: { $0.weight < $1.weight })
    }

    private func epleyFormula(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }
    private func brzyckiFormula(weight: Double, reps: Int) -> Double {
        guard reps > 0 && reps < 37 else { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }
    private func lombardiFormula(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        return weight * pow(Double(reps), 0.10)
    }
    private var estimatedOneRepMax: Double? {
        guard let record = recordSet else { return nil }
        let epley = epleyFormula(weight: record.weight, reps: record.reps)
        let brzycki = brzyckiFormula(weight: record.weight, reps: record.reps)
        let lombardi = lombardiFormula(weight: record.weight, reps: record.reps)
        return (epley + brzycki + lombardi) / 3.0
    }
    private var maxSetVolumeEver: Double {
        volumeData.map { $0.maxSetVolume }.max() ?? 0
    }
    struct MaxWeightBWDataPoint: Identifiable {
        let id = UUID()
        let workoutIndex: Int
        let percent: Double
    }
    private var maxWeightBWData: [MaxWeightBWDataPoint] {
        let relevantLogs = store.history
            .filter { $0.completedExercises.contains(where: { $0.name == exerciseName }) }
            .sorted(by: { $0.date < $1.date })

        return relevantLogs.enumerated().compactMap { (index, log) in
            if let exercise = log.completedExercises.first(where: { $0.name == exerciseName }) {
                let maxWeight = exercise.sets.map { $0.weight }.max() ?? 0.0
                let bw = store.bodyweight
                let percent = (bw > 0) ? (maxWeight / bw) * 100.0 : 0.0
                return MaxWeightBWDataPoint(workoutIndex: index + 1, percent: percent)
            }
            return nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Chart Type", selection: $chartType) {
                    ForEach(ChartType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)
                // Chart
                if chartType == .maxSetVolume {
                    if volumeData.count > 1 {
                        Text("Max Set Volume Over Time")
                            .font(.title2).bold()
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
                } else if chartType == .maxWeightBodyweight {
                    if maxWeightBWData.count > 1 {
                        Text("Max Weight / Bodyweight % Over Time")
                            .font(.title2).bold()
                        Chart(maxWeightBWData) { dataPoint in
                            LineMark(
                                x: .value("Workout #", dataPoint.workoutIndex),
                                y: .value("% of Bodyweight", dataPoint.percent)
                            )
                            .interpolationMethod(.catmullRom)
                            PointMark(
                                x: .value("Workout #", dataPoint.workoutIndex),
                                y: .value("% of Bodyweight", dataPoint.percent)
                            )
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: min(maxWeightBWData.count, 10)))
                        }
                        .frame(height: 250)
                    } else {
                        ContentUnavailableView(
                            "Not Enough Data",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Complete at least two workouts with this exercise to see a chart.")
                        )
                    }
                }
                StatCard {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Personal Records").font(.title2).bold()
                        if chartType == .maxSetVolume {
                            StatRow(title: "Max Set Volume", value: "\(String(format: "%.1f", maxSetVolumeEver)) kg")
                            if let record = recordSet {
                                StatRow(title: "Max Weight Lifted", value: "\(String(format: "%.1f", record.weight)) kg")
                                StatRow(title: "Reps at Max Weight", value: "\(record.reps) reps")
                            } else {
                                Text("No completed sets found for this exercise.")
                                    .foregroundColor(.secondary)
                            }
                        } else if chartType == .maxWeightBodyweight {
                            let maxPercent = maxWeightBWData.map { $0.percent }.max() ?? 0
                            StatRow(title: "Max Weight / Bodyweight %", value: "\(String(format: "%.1f", maxPercent))%")
                            if let record = recordSet {
                                let percent = (store.bodyweight > 0) ? (record.weight / store.bodyweight) * 100.0 : 0.0
                                StatRow(title: "Best Set %", value: "\(String(format: "%.1f", percent))%")
                                StatRow(title: "Best Set Weight", value: "\(String(format: "%.1f", record.weight)) kg")
                                StatRow(title: "Best Set Reps", value: "\(record.reps) reps")
                            } else {
                                Text("No completed sets found for this exercise.")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                StatCard {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Progressive Overload").font(.title2).bold()
                        if let improvement = store.getImprovementPercentage(for: exerciseName) {
                            HStack {
                                Text("4-Workout Improvement")
                                Spacer()
                                Text("\(improvement >= 0 ? "+" : "")\(String(format: "%.1f", improvement))%")
                                    .foregroundColor(improvement >= 0 ? .green : .red)
                                    .fontWeight(.semibold)
                            }
                        }
                        if store.shouldDeload(exerciseName: exerciseName) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Consider a Deload Week")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                    Text("You've been training hard. Consider reducing weight by 40-60% for recovery.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        if let suggestion = store.getProgressiveOverloadSuggestion(for: exerciseName),
                            let suggestedWeight = suggestion.suggestedWeight,
                            let percentageIncrease = suggestion.percentageIncrease {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Suggested Weight Increase")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    Text("Try \(String(format: "%.1f", suggestedWeight)) kg next time (+\(String(format: "%.1f", percentageIncrease * 100))%)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        if store.getImprovementPercentage(for: exerciseName) == nil &&
                            !store.shouldDeload(exerciseName: exerciseName) &&
                            store.getProgressiveOverloadSuggestion(for: exerciseName) == nil &&
                            !store.getHistory(for: exerciseName).isEmpty {
                            Text("Complete more workouts to get personalized progression suggestions.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                if let record = recordSet, let estimated1RM = estimatedOneRepMax {
                    StatCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("1RM Estimation").font(.title2).bold()
                            StatRow(title: "Estimated 1RM (Average)", value: "\(String(format: "%.1f", estimated1RM)) kg")
                            let epley = epleyFormula(weight: record.weight, reps: record.reps)
                            let brzycki = brzyckiFormula(weight: record.weight, reps: record.reps)
                            let lombardi = lombardiFormula(weight: record.weight, reps: record.reps)
                            StatRow(title: "Epley Formula", value: "\(String(format: "%.1f", epley)) kg", color: .secondary)
                            StatRow(title: "Brzycki Formula", value: "\(String(format: "%.1f", brzycki)) kg", color: .secondary)
                            StatRow(title: "Lombardi Formula", value: "\(String(format: "%.1f", lombardi)) kg", color: .secondary)
                            Text("Based on \(record.reps) reps at \(String(format: "%.1f", record.weight)) kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
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
