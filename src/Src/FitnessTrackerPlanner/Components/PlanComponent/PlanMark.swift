import SwiftUI

struct PlanMark: View {
    let weightText: String
    let fixed: Bool
    let locked: Bool
    let isLastDate: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)

            HStack(spacing: 3) {
                Text(weightText)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(Color.accentColor)

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .offset(
                x: labelOffsetX,
                y: -18
            )
        }
        .frame(width: 80, height: 70)
        .contentShape(Rectangle())
    }

    private var labelOffsetX: CGFloat {
        if isLastDate {
            return 15
        }

        return fixed ? -15 : 0
    }
}
