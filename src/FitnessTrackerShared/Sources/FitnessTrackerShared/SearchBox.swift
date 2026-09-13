import SwiftUI

public struct SearchBox: View {
    @Binding public var text: String
    public let placeholder: String
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) { _text = text; self.placeholder = placeholder }

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
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
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
                .accessibilityLabel("Clear search")
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
                    let isDownwardSwipe = value.translation.height > 10
                    let isMostlyVertical = abs(value.translation.height)
                        > abs(value.translation.width)

                    if isDownwardSwipe && isMostlyVertical {
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
    @Previewable @State var searchText = "chick"

    SearchBox(text: $searchText, placeholder: "Search foods")
        .padding()
        .background(Color("AppBackground"))
}
