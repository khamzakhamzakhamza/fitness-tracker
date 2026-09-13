import SwiftUI

struct LogFoodScreen: View {
    var onLogCreated: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                ScreenTitle("Log meal")
                CloseButton {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            FoodSearch(onLogCreated: onLogCreated)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    LogFoodScreen()
}
