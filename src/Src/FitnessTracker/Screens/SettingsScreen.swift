import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Settings")
                .font(.system(size: 28, weight: .black))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
