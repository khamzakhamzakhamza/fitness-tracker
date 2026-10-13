import Charts
import SwiftUI

struct WeightPointMark: ChartContent {
    let date: Date
    let weight: Double
    let fixed: Bool
    let locked: Bool
    let isDragged: Bool
    let isLastDate: Bool

    var body: some ChartContent {
        PointMark(
            x: .value(Constants.weekValueLabel, date),
            y: .value(
                Constants.planValueLabel,
                weight
            )
        )
        .symbolSize(50)
        .annotation(position: .overlay) {
            PlanMark(
                weightText: PlanComponentService.weightToString(weight),
                fixed: fixed,
                locked: locked,
                isLastDate: isLastDate
            )
            .shadow(
                color: isDragged
                    ? Color.accentColor
                    : .clear,
                radius: isDragged ? 10 : 0
            )
            .shadow(
                color: isDragged
                    ? Color.accentColor.opacity(0.9)
                    : .clear,
                radius: isDragged ? 22 : 0
            )
            .animation(
                .easeInOut(duration: 0.15),
                value: isDragged
            )
        }
    }
}

private enum Constants {
    static let weekValueLabel = "Week"
    static let planValueLabel = "Planned weight"
}
