import SwiftUI

public struct SearchBox: View {
    public static let clearButtonAccessibilityLabel = "Clear search"

    @Binding public var text: String
    public let placeholder: String
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) { _text = text; self.placeholder = placeholder }

    static func shouldDismissKeyboard(for translation: CGSize) -> Bool {
        translation.height > 10
            && abs(translation.height) > abs(translation.width)
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            TextField(
                placeholder,
                text: $text,
                prompt: Text(placeholder)
                    .foregroundStyle(Color("SearchBoxSecondary"))
            )
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .focused($isFocused)
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color("SearchBoxSecondary"))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Self.clearButtonAccessibilityLabel)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color("AppBackground"))
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    if Self.shouldDismissKeyboard(for: value.translation) {
                        isFocused = false
                    }
                }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.primary, lineWidth: 2)
        }
    }
}

#Preview {
    @Previewable @State var searchText = "test"

    SearchBox(text: $searchText, placeholder: "Search foods")
        .padding()
        .background(Color("AppBackground"))
}
