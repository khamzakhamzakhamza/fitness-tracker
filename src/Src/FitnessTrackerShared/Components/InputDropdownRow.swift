import SwiftUI

public struct InputDropdownRow: View {
    @Binding public var selection: String
    public let label: String
    public let options: [String]
    public let showValidationError: Bool

    public init(
        selection: Binding<String>,
        label: String,
        options: [String],
        showValidationError: Bool = false
    ) {
        _selection = selection
        self.label = label
        self.options = options
        self.showValidationError = showValidationError
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(Constants.secondaryTextColor))

            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
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
    }
}

private enum Constants {
    static let secondaryTextColor = "SearchBoxSecondary"
}
