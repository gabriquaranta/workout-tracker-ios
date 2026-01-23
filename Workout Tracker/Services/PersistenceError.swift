//
//  PersistenceError.swift
//  Workout Tracker
//

import Foundation

// MARK: - Persistence Errors

/// Custom error types for persistence operations in the Workout Tracker app.
/// Provides meaningful error context for JSON encoding/decoding failures
/// and data access issues.
enum PersistenceError: Error, LocalizedError {
    
    /// Failed to encode data to JSON format
    case encodingFailed(type: String, underlyingError: Error)
    
    /// Failed to decode JSON data to the expected type
    case decodingFailed(type: String, underlyingError: Error)
    
    /// Requested data was not found in storage
    case dataNotFound(key: String)
    
    /// Data exists but is corrupted or in an unexpected format
    case dataCorrupted(key: String)
    
    // MARK: - LocalizedError Conformance
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let type, let underlyingError):
            return "Failed to encode \(type): \(underlyingError.localizedDescription)"
        case .decodingFailed(let type, let underlyingError):
            return "Failed to decode \(type): \(underlyingError.localizedDescription)"
        case .dataNotFound(let key):
            return "No data found for key: \(key)"
        case .dataCorrupted(let key):
            return "Data corrupted for key: \(key)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .encodingFailed(_, let underlyingError):
            return underlyingError.localizedDescription
        case .decodingFailed(_, let underlyingError):
            return underlyingError.localizedDescription
        case .dataNotFound:
            return "The requested data does not exist in storage"
        case .dataCorrupted:
            return "The stored data could not be interpreted correctly"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .encodingFailed:
            return "Check that all properties conform to Codable correctly"
        case .decodingFailed:
            return "The stored data may be from an older version. Consider clearing app data."
        case .dataNotFound:
            return "This may be expected for first-time users"
        case .dataCorrupted:
            return "Try clearing the app data and restarting"
        }
    }
}

// MARK: - Persistence Logger

/// Simple logging utility for persistence operations.
/// Logs errors with meaningful context to help diagnose issues.
enum PersistenceLogger {
    
    /// Logs a persistence error with context
    static func log(_ error: PersistenceError, function: String = #function) {
        #if DEBUG
        print("⚠️ [Persistence] \(function): \(error.localizedDescription)")
        if let reason = error.failureReason {
            print("   Reason: \(reason)")
        }
        if let suggestion = error.recoverySuggestion {
            print("   Suggestion: \(suggestion)")
        }
        #endif
    }
    
    /// Logs a general message for persistence operations
    static func logInfo(_ message: String, function: String = #function) {
        #if DEBUG
        print("ℹ️ [Persistence] \(function): \(message)")
        #endif
    }
}
