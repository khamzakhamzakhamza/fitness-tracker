import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .black))
                .tracking(0.5)
                .foregroundStyle(Color("AppBackground"))
                .frame(maxWidth: .infinity, minHeight: 56)
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
