import SwiftUI

struct MainScreen: View {
    @State private var selectedRibbonItem = RibbonItem.plan

    var body: some View {
        VStack(spacing: 0) {
            Text("Main screen")

            Spacer()

            Ribbon(selectedItem: $selectedRibbonItem)
        }
    }
}
