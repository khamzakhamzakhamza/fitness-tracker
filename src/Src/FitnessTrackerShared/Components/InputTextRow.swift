import SwiftUI

public struct InputTextRow: View {
    @Binding public var text: String
    public let label: String
    public let placeholder: String
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, label: String, placeholder: String = "") {
        _text = text
        self.label = label
        self.placeholder = placeholder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color("SearchBoxSecondary"))

            TextField(placeholder, text: $text)
                .multilineTextAlignment(.leading)
                .focused($isFocused)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.primary.opacity(0.15), lineWidth: 1)
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    if shouldDismissKeyboard(for: value.translation) {
                        isFocused = false
                    }
                }
        )
    }

    private func shouldDismissKeyboard(for translation: CGSize) -> Bool {
        translation.height > 10
            && abs(translation.height) > abs(translation.width)
    }
}
