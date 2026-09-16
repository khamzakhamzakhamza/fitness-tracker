import SwiftUI

public struct InputTextRow: View {
    @Binding public var text: String
    public let label: String
    public let placeholder: String
    public let showValidationError: Bool
    public let submitLabel: SubmitLabel
    private let focus: FocusState<Bool>.Binding?
    private let onSubmit: (() -> Void)?
    @FocusState private var internalFocus: Bool

    public init(
        text: Binding<String>,
        label: String,
        placeholder: String = "",
        showValidationError: Bool = false,
        focus: FocusState<Bool>.Binding? = nil,
        submitLabel: SubmitLabel = .return,
        onSubmit: (() -> Void)? = nil
    ) {
        _text = text
        self.label = label
        self.placeholder = placeholder
        self.showValidationError = showValidationError
        self.focus = focus
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(Constants.secondaryTextColor))

            TextField(placeholder, text: $text)
                .multilineTextAlignment(.leading)
                .focused(activeFocus)
                .submitLabel(submitLabel)
                .onSubmit {
                    onSubmit?()
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
        .contentShape(Rectangle())
        .onTapGesture {
            activeFocus.wrappedValue = true
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

    private func shouldDismissKeyboard(for translation: CGSize) -> Bool {
        translation.height > 10
            && abs(translation.height) > abs(translation.width)
    }

    private var activeFocus: FocusState<Bool>.Binding {
        focus ?? $internalFocus
    }
}

private enum Constants {
    static let secondaryTextColor = "SearchBoxSecondary"
}
