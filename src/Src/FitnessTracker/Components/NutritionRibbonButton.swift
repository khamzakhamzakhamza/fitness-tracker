import SwiftUI

struct NutritionRibbonButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 20, weight: .semibold))

                Text("Nutrition")
                    .font(.caption)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(minWidth: 64, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
