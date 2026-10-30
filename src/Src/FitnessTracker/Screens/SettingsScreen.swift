import SwiftUI
import FitnessTrackerShared

struct SettingsScreen: View {
    var body: some View {
        VStack(alignment: .leading) {
            ScreenTitle("Settings")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
