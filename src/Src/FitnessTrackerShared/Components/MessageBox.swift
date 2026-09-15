import SwiftUI

public struct MessageBox: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Color("SearchBoxSecondary"))
            .multilineTextAlignment(.center)
            .lineSpacing(7)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    MessageBox(text: "This is a message for the user. It supports multiple lines of text.")
        .padding()
}
