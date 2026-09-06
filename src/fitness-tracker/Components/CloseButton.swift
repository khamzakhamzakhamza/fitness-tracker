import SwiftUI

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(
                    Color("SearchBoxSecondary").opacity(0.12)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

#Preview {
    CloseButton(action: {})
        .padding(20)
        .background(Color("AppBackground"))
}
