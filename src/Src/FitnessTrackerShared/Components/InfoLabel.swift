import SwiftUI

public struct InfoLabel: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: Constants.icon)
                .font(.system(size: 13))
                .padding(.top, 1)

            Text(text)
                .font(.system(size: 10, weight: .bold))
                .lineSpacing(3)
        }
        .foregroundStyle(Color(Constants.textColor))
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private enum Constants {
    static let icon = "info.circle"
    static let textColor = "SearchBoxSecondary"
}

#Preview {
    InfoLabel(text: "Your data is stored on device only")
        .padding()
}
