// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        HStack {
                            Text(theme.displayName)
                            Spacer()
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeManager.currentTheme = theme
                        }
                    }
                }
                Section(header: Text("Bodyweight")) {
                    HStack {
                        Text("Bodyweight")
                        Spacer()
                        Stepper(value: $store.bodyweight, in: 30...250, step: 0.5) {
                            Text("\(String(format: "%.1f", store.bodyweight)) kg")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 