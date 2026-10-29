import SwiftUI

struct SettingsRibbonButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("Settings")
                    .font(.caption)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(minWidth: 64, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
