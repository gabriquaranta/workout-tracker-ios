//
//  WorkoutWidgetsBundle.swift
//  WorkoutWidgets
//
//  Created by Gabriele Quaranta on 21/06/25.
//

import WidgetKit
import SwiftUI

@main
struct WorkoutWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutWidgets()
        WorkoutWidgetsControl()
        WorkoutWidgetsLiveActivity()
    }
}
