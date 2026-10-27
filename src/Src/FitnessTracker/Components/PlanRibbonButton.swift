import SwiftUI

struct PlanRibbonButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("Plan")
                    .font(.caption)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(minWidth: 64, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
