import SwiftUI

public struct PrimaryActionButton: View {
    public let title: String
    public var minimumHeight: CGFloat = 56
    public let action: () -> Void

    public init(title: String, minimumHeight: CGFloat = 56, action: @escaping () -> Void) { self.title = title; self.minimumHeight = minimumHeight; self.action = action }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .black))
                .tracking(0.5)
                .foregroundStyle(Color("AppBackground"))
                .frame(maxWidth: .infinity, minHeight: minimumHeight)
                .background(Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            title.prefix(1) + title.dropFirst().lowercased()
        )
    }
}

#Preview {
    PrimaryActionButton(title: "ADD TO TODAY", action: {})
        .background(Color("AppBackground"))
}
