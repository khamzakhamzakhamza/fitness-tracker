import SwiftUI

struct Ribbon: View {
    @Binding var selectedItem: RibbonItem

    var body: some View {
        HStack {
            PlanRibbonButton(isSelected: selectedItem == .plan) {
                selectedItem = .plan
            }

            NutritionRibbonButton(isSelected: selectedItem == .nutrition) {
                selectedItem = .nutrition
            }

            Spacer()

            SettingsRibbonButton(isSelected: selectedItem == .settings) {
                selectedItem = .settings
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
