//
//  WorkoutWidgetsLiveActivity.swift
//  WorkoutWidgets
//
//  Created by Gabriele Quaranta on 21/06/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WorkoutWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WorkoutWidgetsAttributes {
    fileprivate static var preview: WorkoutWidgetsAttributes {
        WorkoutWidgetsAttributes(name: "World")
    }
}

extension WorkoutWidgetsAttributes.ContentState {
    fileprivate static var smiley: WorkoutWidgetsAttributes.ContentState {
        WorkoutWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WorkoutWidgetsAttributes.ContentState {
         WorkoutWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WorkoutWidgetsAttributes.preview) {
   WorkoutWidgetsLiveActivity()
} contentStates: {
    WorkoutWidgetsAttributes.ContentState.smiley
    WorkoutWidgetsAttributes.ContentState.starEyes
}
