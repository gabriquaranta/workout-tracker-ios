// WorkoutWidgets.swift

import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutWidgets: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // MARK: Lock Screen UI
            VStack(alignment: .leading) {
                Text(context.attributes.workoutName)
                    .font(.headline)
                
                if context.state.isResting {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("Resting:")
                        Text(timerInterval: context.state.timerEndDate...Date.distantFuture, countsDown: true)
                            .monospacedDigit()
                            .frame(width: 60)
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                } else {
                    HStack {
                        Image(systemName: "figure.walk")
                        Text(context.state.workoutTimerText)
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            // MARK: Dynamic Island UI
            DynamicIsland {
                // Expanded UI (when user long-presses the island)
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.workoutName).font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isResting {
                        Label {
                            Text(timerInterval: context.state.timerEndDate...Date.distantFuture, countsDown: true)
                                .monospacedDigit()
                        } icon: {
                            Image(systemName: "timer")
                        }.foregroundColor(.yellow)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isResting {
                        Text("Rest Period").font(.caption).foregroundColor(.secondary)
                    } else {
                        HStack {
                            Image(systemName: "figure.walk")
                            Text("Total Time: \(context.state.workoutTimerText)")
                        }
                    }
                }
            } compactLeading: {
                // Compact UI (left side of the notch)
                Image(systemName: context.state.isResting ? "timer" : "figure.walk")
                    .foregroundColor(context.state.isResting ? .yellow : .green)
            } compactTrailing: {
                // Compact UI (right side of the notch)
                if context.state.isResting {
                    Text(timerInterval: context.state.timerEndDate...Date.distantFuture, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 40)
                        .foregroundColor(.yellow)
                }
            } minimal: {
                // Minimal UI (when two activities are active)
                Image(systemName: "timer")
                    .foregroundColor(context.state.isResting ? .yellow : .green)
            }
        }
    }
}
