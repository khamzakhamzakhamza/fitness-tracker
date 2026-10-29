import SwiftUI

public struct WeightSelector: View {
    @Binding private var selectedWeight: Double
    private let unit: String
    private let allowedRange: ClosedRange<Double>

    @State private var weightText = ""
    @FocusState private var isWeightFieldFocused: Bool

    public init(
        selectedWeight: Binding<Double>,
        unit: String,
        allowedRange: ClosedRange<Double>
    ) {
        _selectedWeight = selectedWeight
        self.unit = unit
        self.allowedRange = allowedRange
    }

    public var body: some View {
        ZStack {
            TextField(Constants.emptyWeight, text: $weightText)
                .font(.system(size: 52, weight: .black))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($isWeightFieldFocused)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Constants.accessibilityLabel)

            VStack(spacing: 1) {
                Image(systemName: Constants.editIcon)
                    .font(.system(size: 13, weight: .bold))
                    .accessibilityHidden(true)

                Text(unit)
                    .font(.system(size: 20, weight: .black))
            }
            .foregroundStyle(Color(Constants.secondaryColor))
            .offset(x: 115, y: 2)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            selectedWeight = clampedWeight(selectedWeight)
            weightText = formatted(selectedWeight)
        }
        .onChange(of: selectedWeight) { _, newValue in
            let clampedValue = clampedWeight(newValue)

            if abs(clampedValue - newValue) > Constants.comparisonTolerance {
                selectedWeight = clampedValue
                weightText = formatted(clampedValue)
                return
            }

            if !isWeightFieldFocused {
                weightText = formatted(newValue)
            }
        }
        .onChange(of: weightText) { _, newValue in
            guard let weight = Self.weight(from: newValue), weight > 0 else {
                return
            }

            let clampedValue = clampedWeight(weight)
            selectedWeight = clampedValue

            if abs(weight - clampedValue) > Constants.comparisonTolerance {
                weightText = formatted(clampedValue)
            }
        }
        .onChange(of: isWeightFieldFocused) { _, isFocused in
            if !isFocused {
                weightText = formatted(selectedWeight)
            }
        }
    }

    public nonisolated static func weight(from text: String) -> Double? {
        let normalizedValue = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        return Double(normalizedValue)
    }

    private func clampedWeight(_ weight: Double) -> Double {
        min(max(weight, allowedRange.lowerBound), allowedRange.upperBound)
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(
            .number
                .grouping(.never)
                .precision(.fractionLength(0...1))
        )
    }
}

private enum Constants {
    static let emptyWeight = "0"
    static let accessibilityLabel = "Selected weight"
    static let editIcon = "pencil"
    static let secondaryColor = "SearchBoxSecondary"
    static let comparisonTolerance = 0.001
}
