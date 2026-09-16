import SwiftUI

public struct InlineOptionButtons: View {
    public let options: [String]
    @Binding public var selection: String?

    public init(options: [String], selection: Binding<String?>) {
        self.options = options
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(option)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(selection == option ? Color.white : Color(Constants.textColor))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selection == option ? Color.accentColor : Color.primary.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private enum Constants {
    static let textColor = "SearchBoxSecondary"
}
