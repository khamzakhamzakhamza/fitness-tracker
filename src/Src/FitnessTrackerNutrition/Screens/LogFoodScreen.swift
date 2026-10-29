import SwiftUI
import FitnessTrackerShared

struct LogFoodScreen: View {
    var onLogCreated: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            ScreenTitle("Log meal")
                .padding(.horizontal, 20)

            FoodSearch(onLogCreated: onLogCreated)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
    }
}

#Preview {
    LogFoodScreen()
}
