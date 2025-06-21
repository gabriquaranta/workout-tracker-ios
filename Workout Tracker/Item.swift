//
//  Item.swift
//  Workout Tracker
//
//  Created by Gabriele Quaranta on 20/06/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
