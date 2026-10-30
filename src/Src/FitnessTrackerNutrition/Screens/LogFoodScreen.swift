import SwiftUI
import FitnessTrackerShared

struct LogFoodScreen: View {
    var onLogCreated: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            FoodSearch(onLogCreated: onLogCreated)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
        .navigationTitle("Log meal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LogFoodScreen()
}
