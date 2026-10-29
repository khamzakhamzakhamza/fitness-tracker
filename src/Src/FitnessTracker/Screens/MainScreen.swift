import SwiftUI
import FitnessTrackerNutrition
import FitnessTrackerPlanner

struct MainScreen: View {
    @State private var selectedRibbonItem = RibbonItem.plan

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch selectedRibbonItem {
                case .plan:
                    PlanScreen()
                case .nutrition:
                    NutritionScreen()
                case .settings:
                    SettingsScreen()
                }

                Ribbon(selectedItem: $selectedRibbonItem)
            }
        }
    }
}
