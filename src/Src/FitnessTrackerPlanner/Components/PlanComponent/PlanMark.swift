import SwiftUI

struct PlanMark: View {
    let date: Date
    let weightText: String
    let fixed: Bool
    let locked: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    fixed
                        ? Color.green.opacity(0.5)
                        : Color.accentColor
                )
                .frame(width: 10, height: 10)

            Text(weightText)
                .font(.caption)
                .foregroundStyle(
                    fixed ? Color.green : Color.accentColor
                )
                .offset(
                    x: fixed ? -7 : 0,
                    y: -18
                )

            if locked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: -34)
            }
        }
        .frame(width: 44, height: 70)
        .contentShape(Rectangle())
    }
}
