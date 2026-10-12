import Charts
import SwiftUI

struct WeightPointMark: ChartContent {
    let date: Date
    let weight: Double
    let fixed: Bool
    let locked: Bool
    let onLongPress: (Date) -> Void

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
                date: date,
                weightText: PlanComponentService.weightToString(weight),
                fixed: fixed,
                locked: locked,
                onLongPress: onLongPress
            )
        }
    }
}

private enum Constants {
    static let weekValueLabel = "Week"
    static let planValueLabel = "Planned weight"
}
