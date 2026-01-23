//
//  ThemeManager.swift
//  Workout Tracker
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case automatic = "automatic"
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .automatic:
            return "Automatic"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .automatic:
            return nil
        }
    }
}

class ThemeManager: ObservableObject {
    
    // MARK: - Properties
    
    private let persistence: PersistenceProtocol
    
    @Published var currentTheme: AppTheme {
        didSet {
            persistence.saveTheme(currentTheme.rawValue)
        }
    }
    
    // MARK: - Initialization
    
    init(persistence: PersistenceProtocol = UserDefaultsPersistenceManager()) {
        self.persistence = persistence
        let savedTheme = persistence.loadTheme() ?? AppTheme.automatic.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .automatic
    }
} 