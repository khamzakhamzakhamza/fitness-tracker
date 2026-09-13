import SwiftUI
import FitnessTrackerNutrition

struct ContentView: View {
    var body: some View {
        NavigationStack {
            NutritionScreen()
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
}
