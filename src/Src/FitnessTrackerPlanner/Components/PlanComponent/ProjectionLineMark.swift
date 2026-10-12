import Charts
import SwiftUI

struct ProjectionLineMark: ChartContent {
    let date: Date
    let weight: Double

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
                Constants.maximumLossSeries
            )
        )
        .foregroundStyle(Color.red.opacity(0.7))
    }
}

private enum Constants {
    static let weekValueLabel = "Week"
    static let planValueLabel = "Planned weight"
    static let weightLimitSeriesLabel = "Weight limit"
    static let maximumLossSeries = "Maximum loss"
}
