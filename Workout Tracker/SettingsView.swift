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
                        .accessibilityLabel("\(theme.displayName) theme")
                        .accessibilityAddTraits(themeManager.currentTheme == theme ? .isSelected : .isButton)
                    }
                }
                Section(header: Text("Bodyweight")) {
                    Stepper(value: $store.bodyweight, in: 30...250, step: 0.5) {
                        HStack {
                            Text("Bodyweight")
                            Spacer()
                            Text("\(String(format: "%.1f", store.bodyweight)) kg")
                        }
                    }
                    .accessibilityLabel("Bodyweight stepper")
                }
                
                Section(header: Text("Equipment")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Smallest weight increment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Stepper(value: $store.smallestWeightIncrement, in: 0.25...5.0, step: 0.25) {
                            HStack {
                                Text("\(String(format: "%.2f", store.smallestWeightIncrement)) kg")
                                Spacer()
                                Text("Used to round recommendations")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .accessibilityLabel("Smallest weight increment")
                    }
                }
                #if DEBUG
                Section(header: Text("Debug")) {
                    Button(role: .destructive) {
                        ActivityManager.endAllWorkoutsNow()
                    } label: {
                        Text("End All Live Activities (debug)")
                    }
                    .accessibilityLabel("End all live activities")
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Dismiss settings")
                }
            }
        }
    }
}
