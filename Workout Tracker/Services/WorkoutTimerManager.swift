//
//  WorkoutTimerManager.swift
//  Workout Tracker
//

import Foundation
import Combine

/// Manages workout and rest timers for active workout sessions.
/// Separates timer logic from view layer for better testability and reusability.
final class WorkoutTimerManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Total elapsed workout time in seconds
    @Published private(set) var workoutElapsedTime: TimeInterval = 0
    
    /// Remaining rest time in seconds
    @Published private(set) var restTimeRemaining: Int = 0
    
    /// Whether the rest timer is currently running
    @Published private(set) var isRestTimerRunning: Bool = false
    
    // MARK: - Internal Properties
    
    /// The date when the workout started
    private(set) var workoutStartTime: Date = Date()
    
    /// The date when the current rest period ends
    private(set) var restEndDate: Date?
    
    // MARK: - Private Properties
    
    private var workoutTimer: Timer?
    private var restTimer: Timer?
    
    /// Callback invoked on each workout timer tick (for state saving, activity updates, etc.)
    var onWorkoutTimerTick: (() -> Void)?
    
    /// Callback invoked when rest timer completes
    var onRestTimerComplete: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        invalidateAll()
    }
    
    // MARK: - Workout Timer Methods
    
    /// Starts the workout timer from the specified start time.
    /// - Parameter startTime: The date when the workout started. Defaults to now.
    func startWorkoutTimer(from startTime: Date = Date()) {
        workoutStartTime = startTime
        workoutTimer?.invalidate()
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.workoutElapsedTime = Date().timeIntervalSince(self.workoutStartTime)
            self.onWorkoutTimerTick?()
        }
    }
    
    /// Stops the workout timer but preserves the elapsed time.
    func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    /// Sets the elapsed time (used when restoring from saved state).
    /// - Parameter elapsed: The elapsed time to restore.
    func setElapsedTime(_ elapsed: TimeInterval) {
        workoutElapsedTime = elapsed
    }
    
    /// Sets the workout start time (used when restoring from saved state).
    /// - Parameter startTime: The start time to restore.
    func setStartTime(_ startTime: Date) {
        workoutStartTime = startTime
    }
    
    // MARK: - Rest Timer Methods
    
    /// Starts the rest timer for the specified duration.
    /// - Parameter duration: Rest duration in seconds.
    func startRestTimer(duration: Int) {
        let endDate = Date().addingTimeInterval(TimeInterval(duration))
        startRestTimer(endDate: endDate)
    }
    
    /// Starts the rest timer to end at a specific date.
    /// - Parameter endDate: The date when rest should end.
    func startRestTimer(endDate: Date) {
        restEndDate = endDate
        restTimer?.invalidate()
        isRestTimerRunning = true
        
        // Calculate initial remaining time
        let remaining = Int(round(endDate.timeIntervalSince(Date())))
        restTimeRemaining = max(0, remaining)
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let validEndDate = self.restEndDate else {
                self.stopRestTimer()
                return
            }
            
            let remaining = Int(round(validEndDate.timeIntervalSince(Date())))
            self.restTimeRemaining = max(0, remaining)
            
            if self.restTimeRemaining == 0 {
                self.stopRestTimer()
                self.onRestTimerComplete?()
            }
        }
    }
    
    /// Stops the rest timer and resets rest-related state.
    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerRunning = false
        restEndDate = nil
    }
    
    /// Sets the rest time remaining (used when restoring from saved state).
    /// - Parameter remaining: The remaining rest time in seconds.
    func setRestTimeRemaining(_ remaining: Int) {
        restTimeRemaining = remaining
    }
    
    // MARK: - Cleanup
    
    /// Invalidates all timers and resets state.
    func invalidateAll() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        workoutTimer = nil
        restTimer = nil
        isRestTimerRunning = false
        restEndDate = nil
    }
}
