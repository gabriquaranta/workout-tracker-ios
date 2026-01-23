//
//  SetEditingSheetView.swift
//  Workout Tracker
//

import SwiftUI

struct SetEditingSheetView: View {
    
    // MARK: - Properties
    
    @State private var setCopy: LiveWorkoutSet
    let onDone: (LiveWorkoutSet) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @FocusState private var weightIsFocused: Bool
    @FocusState private var repsIsFocused: Bool

    // MARK: - Init
    
    init(setCopy: LiveWorkoutSet, onDone: @escaping (LiveWorkoutSet) -> Void) {
        self._setCopy = State(initialValue: setCopy)
        self.onDone = onDone
        self._repsText = State(initialValue: "\(setCopy.reps)")
        self._weightText = State(initialValue: String(format: "%.1f", setCopy.weight))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Edit Reps") {
                    VStack(spacing: 12) {
                        TextField("Reps", text: $repsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .focused($repsIsFocused)
                            .onSubmit {
                                applyRepsChange()
                            }
                            .onChange(of: repsIsFocused) { _, focused in
                                if !focused { applyRepsChange() }
                            }
                        Stepper("", value: $setCopy.reps, in: 0...100)
                            .labelsHidden()
                            .onChange(of: setCopy.reps) { _, newValue in
                                repsText = "\(newValue)"
                            }
                    }
                }
                Section("Edit Weight") {
                    VStack(spacing: 12) {
                        TextField("Weight (kg)", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .focused($weightIsFocused)
                            .onSubmit {
                                applyWeightChange()
                            }
                            .onChange(of: weightIsFocused) { _, focused in
                                if !focused { applyWeightChange() }
                            }
                        Stepper("", value: $setCopy.weight, in: 0...500, step: 0.5)
                            .labelsHidden()
                            .onChange(of: setCopy.weight) { _, newValue in
                                weightText = String(format: "%.1f", newValue)
                            }
                    }
                }
            }
            .navigationTitle("Edit Set").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { setCopy.wasModified = true; onDone(setCopy) } } }
        }
    }

    // MARK: - Private Methods
    
    private func applyRepsChange() {
        if let reps = Int(repsText), reps >= 0, reps <= 100 {
            setCopy.reps = reps
            repsText = "\(reps)"
        } else {
            // Revert to last valid
            repsText = "\(setCopy.reps)"
        }
    }

    private func applyWeightChange() {
        if let weight = Double(weightText), weight >= 0, weight <= 500 {
            setCopy.weight = weight
            weightText = String(format: "%.1f", weight)
        } else {
            // Revert to last valid
            weightText = String(format: "%.1f", setCopy.weight)
        }
    }
}
