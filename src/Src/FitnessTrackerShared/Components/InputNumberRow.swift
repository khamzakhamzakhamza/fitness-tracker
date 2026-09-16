import SwiftUI
import UIKit

public struct InputNumberRow: View {
    @Binding public var value: String
    public let label: String
    public let placeholder: String
    public let allowedRange: ClosedRange<Double>?
    public let unit: String?
    public let unitOptions: [String]
    public let inlineOptions: [String]
    public let showValidationError: Bool

    private let selectedUnit: Binding<String>?
    private let selectedInlineOption: Binding<String?>?

    public init(
        value: Binding<String>,
        label: String,
        placeholder: String = "",
        allowedRange: ClosedRange<Double>? = nil,
        unit: String? = nil,
        unitOptions: [String] = [],
        selectedUnit: Binding<String>? = nil,
        inlineOptions: [String] = [],
        selectedInlineOption: Binding<String?>? = nil,
        showValidationError: Bool = false
    ) {
        _value = value
        self.label = label
        self.placeholder = placeholder
        self.allowedRange = allowedRange
        self.unit = unit
        self.unitOptions = unitOptions
        self.selectedUnit = selectedUnit
        self.inlineOptions = inlineOptions
        self.selectedInlineOption = selectedInlineOption
        self.showValidationError = showValidationError
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(Constants.secondaryTextColor))

            if !inlineOptions.isEmpty, let selectedInlineOption {
                InlineOptionButtons(
                    options: inlineOptions,
                    selection: selectedInlineOption
                )
            }

            HStack(spacing: 10) {
                TextField(
                    placeholder,
                    text: $value,
                    onEditingChanged: { isEditing in
                        if !isEditing {
                            clampValueToAllowedRange()
                        }
                    }
                )
                .keyboardType(.decimalPad)

                if !unitOptions.isEmpty, let selectedUnit {
                    Picker(Constants.unitPickerLabel, selection: selectedUnit) {
                        ForEach(unitOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(Color(Constants.secondaryTextColor))
                } else if let unit {
                    Text(unit)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(Constants.secondaryTextColor))
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        showValidationError ? Color.red : Color.primary.opacity(0.15),
                        lineWidth: showValidationError ? 1.5 : 1
                    )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            clampValueToAllowedRange()
        }
    }

    private func clampValueToAllowedRange() {
        guard let allowedRange,
              let numericValue = parsedValue else {
            return
        }

        let clampedValue = min(max(numericValue, allowedRange.lowerBound), allowedRange.upperBound)
        guard clampedValue != numericValue else {
            return
        }

        value = formattedValue(clampedValue)
    }

    private var parsedValue: Double? {
        let formatter = NumberFormatter()
        formatter.locale = .current
        return formatter.number(from: value)?.doubleValue ?? Double(value)
    }

    private func formattedValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

private enum Constants {
    static let secondaryTextColor = "SearchBoxSecondary"
    static let unitPickerLabel = "Measurement unit"
}
