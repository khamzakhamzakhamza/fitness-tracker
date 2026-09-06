import SwiftUI

struct WarningMessage: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 19, weight: .semibold))

            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color("SearchBoxSecondary"))
        .padding(16)
        .background(Color("SearchBoxSecondary").opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WarningMessage(
        message: "Every match is tagged with where its figures come from."
    )
    .padding(20)
    .background(Color("AppBackground"))
}
