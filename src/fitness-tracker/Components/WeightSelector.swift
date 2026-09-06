import SwiftUI

struct WeightSelector: View {
    nonisolated static let maximumWeightGrams = 2_000.0

    let servingSizeGrams: Double
    let totalAmountGrams: Double?
    @Binding var selectedGrams: Double
    @State private var weightText = ""
    @FocusState private var isWeightFieldFocused: Bool

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                TextField("0", text: $weightText)
                    .font(.system(size: 52, weight: .black))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isWeightFieldFocused)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Selected weight in grams")

                Text("g")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Color("SearchBoxSecondary"))
                    .offset(x: 95, y: 10)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach(presetWeights, id: \.self) { weight in
                    Button {
                        selectedGrams = weight
                        weightText = formatted(weight)
                    } label: {
                        Text("\(formatted(weight)) g")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(
                                isSelected(weight) ? .primary :
                                    Color("SearchBoxSecondary")
                            )
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isSelected(weight) ? Color.primary :
                                            Color("SearchBoxSecondary")
                                                .opacity(0.2),
                                        lineWidth: isSelected(weight) ? 2 : 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            selectedGrams = Self.clampedWeight(selectedGrams)
            weightText = formatted(selectedGrams)
        }
        .onChange(of: selectedGrams) { _, newValue in
            let clampedValue = Self.clampedWeight(newValue)
            if abs(clampedValue - newValue) > 0.001 {
                selectedGrams = clampedValue
                weightText = formatted(clampedValue)
                return
            }

            if !isWeightFieldFocused {
                weightText = formatted(newValue)
            }
        }
        .onChange(of: weightText) { _, newValue in
            if let weight = Self.weight(from: newValue), weight > 0 {
                let clampedWeight = Self.clampedWeight(weight)
                selectedGrams = clampedWeight

                if abs(weight - clampedWeight) > 0.001 {
                    weightText = formatted(clampedWeight)
                }
            }
        }
        .onChange(of: isWeightFieldFocused) { _, isFocused in
            if !isFocused {
                weightText = formatted(selectedGrams)
            }
        }
    }

    nonisolated static func clampedWeight(_ weight: Double) -> Double {
        min(max(weight, 1), maximumWeightGrams)
    }

    nonisolated static func weight(from text: String) -> Double? {
        let normalizedValue = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalizedValue)
    }

    nonisolated static func presetWeights(
        servingSizeGrams: Double,
        totalAmountGrams: Double?
    ) -> [Double] {
        let serving = clampedWeight(servingSizeGrams)
        var weights = [serving / 2, serving]

        if let totalAmountGrams, totalAmountGrams > 0 {
            let totalAmount = clampedWeight(totalAmountGrams)
            weights.append(totalAmount)

            if totalAmount < serving {
                weights.append(serving * 1.5)
                weights.append(serving * 2)
            } else if abs(totalAmount - serving) < 0.001 {
                weights.append(serving * 2)
            }
        } else {
            weights.append(serving * 2)
        }

        return weights
            .map(clampedWeight)
            .sorted()
            .reduce(into: []) { uniqueWeights, weight in
                if uniqueWeights.last.map({ abs($0 - weight) > 0.001 }) ?? true {
                    uniqueWeights.append(weight)
                }
            }
    }

    private var presetWeights: [Double] {
        Self.presetWeights(
            servingSizeGrams: servingSizeGrams,
            totalAmountGrams: totalAmountGrams
        )
    }

    private func isSelected(_ weight: Double) -> Bool {
        abs(selectedGrams - weight) < 0.001
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(
            .number
                .grouping(.never)
                .precision(.fractionLength(0...1))
        )
    }
}

#Preview {
    @Previewable @State var selectedGrams = 100.0

    WeightSelector(
        servingSizeGrams: 100,
        totalAmountGrams: 250,
        selectedGrams: $selectedGrams
    )
    .padding(20)
    .background(Color("AppBackground"))
}
