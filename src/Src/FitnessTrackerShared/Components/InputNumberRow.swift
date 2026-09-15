import SwiftUI

public struct InputNumberRow: View {
    @Binding public var value: String
    public let label: String
    public let placeholder: String
    public let unit: String?
    public let unitOptions: [String]
    public let inlineOptions: [String]
    public let showValidationError: Bool

    private let selectedUnit: Binding<String>?
    private let selectedInlineOption: Binding<String?>?
    private let focus: FocusState<Bool>.Binding?
    @FocusState private var internalFocus: Bool

    public init(
        value: Binding<String>,
        label: String,
        placeholder: String = "",
        unit: String? = nil,
        unitOptions: [String] = [],
        selectedUnit: Binding<String>? = nil,
        inlineOptions: [String] = [],
        selectedInlineOption: Binding<String?>? = nil,
        showValidationError: Bool = false,
        focus: FocusState<Bool>.Binding? = nil
    ) {
        _value = value
        self.label = label
        self.placeholder = placeholder
        self.unit = unit
        self.unitOptions = unitOptions
        self.selectedUnit = selectedUnit
        self.inlineOptions = inlineOptions
        self.selectedInlineOption = selectedInlineOption
        self.showValidationError = showValidationError
        self.focus = focus
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
                TextField(placeholder, text: $value)
                    .keyboardType(.decimalPad)
                    .focused(activeFocus)

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
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    if shouldDismissKeyboard(for: value.translation) {
                        activeFocus.wrappedValue = false
                    }
                }
        )
    }

    private var activeFocus: FocusState<Bool>.Binding {
        focus ?? $internalFocus
    }

    private func shouldDismissKeyboard(for translation: CGSize) -> Bool {
        translation.height > 10
            && abs(translation.height) > abs(translation.width)
    }
}

private enum Constants {
    static let secondaryTextColor = "SearchBoxSecondary"
    static let unitPickerLabel = "Measurement unit"
}
