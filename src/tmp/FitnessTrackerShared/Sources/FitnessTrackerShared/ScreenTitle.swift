import SwiftUI

public struct ScreenTitle: View {
    public let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.system(size: 36, weight: .black))
            .tracking(-0.8)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ScreenTitle("Log meal")
        .padding(20)
        .background(Color("AppBackground"))
}
