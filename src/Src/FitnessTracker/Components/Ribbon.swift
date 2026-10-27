import SwiftUI

struct Ribbon: View {
    @Binding var selectedItem: RibbonItem

    var body: some View {
        HStack {
            PlanRibbonButton(isSelected: selectedItem == .plan) {
                selectedItem = .plan
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
