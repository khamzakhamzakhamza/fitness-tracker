import Charts
import SwiftUI

struct LimitLineMark: ChartContent {
    let date: Date
    let weight: Double
    let series: String

    var body: some ChartContent {
        LineMark(
            x: .value(
                Constants.weekValueLabel,
                date
            ),
            y: .value(
                Constants.planValueLabel,
                weight
            ),
            series: .value(
                Constants.weightLimitSeriesLabel,
                series
            )
        )
        .foregroundStyle(Color.red.opacity(0.7))
    }
}

private enum Constants {
    static let weekValueLabel = "Week"
    static let planValueLabel = "Planned weight"
    static let weightLimitSeriesLabel = "Weight limit"
}
