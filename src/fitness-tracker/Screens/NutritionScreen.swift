import SwiftUI

struct NutritionScreen: View {
    @State private var isShowingLogFood = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitle("Progress is built on the plate.")
                .padding(.horizontal, 20)
                .padding(.top, 28)

            Spacer()

            LogMealButton {
                isShowingLogFood = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
        .navigationDestination(isPresented: $isShowingLogFood) {
            LogFoodScreen()
        }
    }
}

#Preview {
    NavigationStack {
        NutritionScreen()
    }
}
