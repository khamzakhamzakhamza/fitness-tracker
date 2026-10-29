import SwiftUI

public struct WeightInput: View {
    @Binding private var selectedWeightSI: Double
    private let unit: String
    private let siConversionValue: Double
    private let allowedRangeSI: ClosedRange<Double>

    @State private var weightText = ""
    @FocusState private var isWeightFieldFocused: Bool

    public init(
        selectedWeightSI: Binding<Double>,
        unit: String,
        siConversionValue: Double,
        allowedRangeSI: ClosedRange<Double>
    ) {
        _selectedWeightSI = selectedWeightSI
        self.unit = unit
        self.siConversionValue = siConversionValue
        self.allowedRangeSI = allowedRangeSI
    }

    public var body: some View {
        HStack(spacing: 20) {
            adjustmentButton(
                systemImage: Constants.decreaseIcon,
                accessibilityLabel: Constants.decreaseLabel
            ) {
                updateWeight(by: -Constants.weightStepSI)
            }

            ZStack {
                TextField(Constants.emptyWeight, text: $weightText)
                    .font(.system(size: 52, weight: .black))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isWeightFieldFocused)
                    .accessibilityLabel(Constants.accessibilityLabel)

                Text(unit)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Color(Constants.secondaryColor))
                    .offset(x: Constants.unitOffsetX, y: Constants.unitOffsetY)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)

            adjustmentButton(
                systemImage: Constants.increaseIcon,
                accessibilityLabel: Constants.increaseLabel
            ) {
                updateWeight(by: Constants.weightStepSI)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            selectedWeightSI = clampedWeight(selectedWeightSI)
            weightText = formatted(displayedWeight)
        }
        .onChange(of: selectedWeightSI) { _, newValue in
            let clampedValue = clampedWeight(newValue)

            if abs(clampedValue - newValue) > Constants.comparisonTolerance {
                selectedWeightSI = clampedValue
                weightText = formatted(clampedValue / siConversionValue)
                return
            }

            if !isWeightFieldFocused {
                weightText = formatted(newValue / siConversionValue)
            }
        }
        .onChange(of: weightText) { _, newValue in
            guard let displayedWeight = Self.weight(from: newValue),
                  displayedWeight > 0 else {
                return
            }

            let enteredWeightSI = displayedWeight * siConversionValue
            let clampedValue = clampedWeight(enteredWeightSI)
            selectedWeightSI = clampedValue

            if abs(enteredWeightSI - clampedValue) > Constants.comparisonTolerance {
                weightText = formatted(clampedValue / siConversionValue)
            }
        }
        .onChange(of: isWeightFieldFocused) { _, isFocused in
            if !isFocused {
                weightText = formatted(displayedWeight)
            }
        }
    }

    public nonisolated static func weight(from text: String) -> Double? {
        let normalizedValue = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        return Double(normalizedValue)
    }

    private var displayedWeight: Double {
        selectedWeightSI / siConversionValue
    }

    private func adjustmentButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 54, height: 54)
                .overlay {
                    Circle()
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func updateWeight(by changeSI: Double) {
        selectedWeightSI = clampedWeight(selectedWeightSI + changeSI)
        weightText = formatted(displayedWeight)
    }

    private func clampedWeight(_ weightSI: Double) -> Double {
        min(max(weightSI, allowedRangeSI.lowerBound), allowedRangeSI.upperBound)
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(
            .number
                .grouping(.never)
                .precision(.fractionLength(0...2))
        )
    }
}

private enum Constants {
    static let emptyWeight = "0"
    static let accessibilityLabel = "Selected weight"
    static let decreaseIcon = "minus"
    static let increaseIcon = "plus"
    static let decreaseLabel = "Decrease weight"
    static let increaseLabel = "Increase weight"
    static let secondaryColor = "SearchBoxSecondary"
    static let comparisonTolerance = 0.001
    static let weightStepSI = 100.0
    static let unitOffsetX: CGFloat = 88
    static let unitOffsetY: CGFloat = 10
}
