//
//  DateComponentsFormatter+Extensions.swift
//  Workout Tracker
//

import Foundation

// MARK: - DateComponentsFormatter Extensions

extension DateComponentsFormatter {
    
    // MARK: - Shared Formatters
    
    /// Positional format with zero padding: "01:30:45" or "00:05:30"
    /// Used for workout timers and rest timers.
    static let positionalTimer: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    /// Abbreviated format with hours, minutes, seconds: "1h 30m 45s"
    /// Used for displaying workout durations in history.
    static let abbreviatedDuration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    /// Abbreviated format with hours and minutes only: "1h 30m"
    /// Used for aggregate time displays (total workout time).
    static let abbreviatedHoursMinutes: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    // MARK: - Convenience Methods
    
    /// Formats a TimeInterval as a positional timer string (e.g., "01:30:45").
    /// - Parameter interval: The time interval to format.
    /// - Returns: A formatted string, or "00:00" if formatting fails.
    static func positionalString(from interval: TimeInterval) -> String {
        positionalTimer.string(from: interval) ?? "00:00"
    }
    
    /// Formats a TimeInterval as an abbreviated duration (e.g., "1h 30m 45s").
    /// - Parameter interval: The time interval to format.
    /// - Returns: A formatted string, or "0s" if formatting fails.
    static func abbreviatedString(from interval: TimeInterval) -> String {
        abbreviatedDuration.string(from: interval) ?? "0s"
    }
    
    /// Formats a TimeInterval as abbreviated hours and minutes (e.g., "1h 30m").
    /// - Parameter interval: The time interval to format.
    /// - Returns: A formatted string, or "0m" if formatting fails.
    static func abbreviatedHoursMinutesString(from interval: TimeInterval) -> String {
        abbreviatedHoursMinutes.string(from: interval) ?? "0m"
    }
}
