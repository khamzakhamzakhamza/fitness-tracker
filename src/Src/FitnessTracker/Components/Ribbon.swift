import SwiftUI

struct Ribbon: View {
    @Binding var selectedItem: RibbonItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RibbonItem.allCases, id: \.self) { item in
                ribbonButton(for: item)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(alignment: .top) {
            Divider()
        }
    }

    @ViewBuilder
    private func ribbonButton(for item: RibbonItem) -> some View {
        switch item {
        case .plan:
            PlanRibbonButton(isSelected: selectedItem == item) {
                selectedItem = item
            }
        case .nutrition:
            NutritionRibbonButton(isSelected: selectedItem == item) {
                selectedItem = item
            }
        case .settings:
            SettingsRibbonButton(isSelected: selectedItem == item) {
                selectedItem = item
            }
        }
    }
}
