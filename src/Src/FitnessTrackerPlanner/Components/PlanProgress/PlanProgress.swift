import Charts
import SwiftUI

public struct PlanProgress: View {
    public let plan: PlanValue
    public let milestones: [PlanMilestoneValue]
    public let measurements: [UserMeasurement]
    @State private var scrollPosition: Date

    public init(
        plan: PlanValue,
        milestones: [PlanMilestoneValue],
        measurements: [UserMeasurement]
    ) {
        self.plan = plan
        self.milestones = milestones.sorted { $0.date < $1.date }
        self.measurements = measurements.sorted { $0.dateAdded < $1.dateAdded }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        _scrollPosition = State(
            initialValue: calendar.date(
                byAdding: .day,
                value: -Constants.leadingPaddingDays,
                to: today
            ) ?? today
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(plan.name)
                .font(.system(size: 14, weight: .bold))

            Chart {
                if let startingMilestone = milestones.first {
                    RuleMark(
                        y: .value(
                            Constants.planValueLabel,
                            convertedWeight(startingMilestone.targetWeightSI)
                        )
                    )
                    .foregroundStyle(
                        Color.secondary.opacity(Constants.planLineOpacity)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [7, 7]))
                }

                RuleMark(x: .value(Constants.todayLabel, today))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                if let endDate = milestones.last?.date {
                    RuleMark(x: .value(Constants.endLabel, endDate))
                        .foregroundStyle(Color.secondary.opacity(Constants.boundaryLineOpacity))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }

                ForEach(milestones, id: \.date) { milestone in
                    let weight = convertedWeight(milestone.targetWeightSI)

                    RuleMark(x: .value(Constants.weekValueLabel, milestone.date))
                        .foregroundStyle(
                            Color.secondary.opacity(Constants.weekLineOpacity)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1))

                    LineMark(
                        x: .value(Constants.weekValueLabel, milestone.date),
                        y: .value(Constants.planValueLabel, weight),
                        series: .value(Constants.seriesLabel, Constants.planSeries)
                    )
                    .foregroundStyle(Color.secondary)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 1,
                            lineCap: .round,
                            dash: [5, 5]
                        )
                    )

                    PointMark(
                        x: .value(Constants.weekValueLabel, milestone.date),
                        y: .value(Constants.planValueLabel, weight)
                    )
                    .foregroundStyle(Color.secondary)
                    .symbol {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 2)
                            .frame(width: 10, height: 10)
                    }
                    .annotation(position: .top) {
                        Text(PlanComponentService.weightToString(weight))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .offset(y: -4)
                    }
                }

                ForEach(measurements, id: \.id) { measurement in
                    let weight = convertedWeight(measurement.weightSI)
                    let date = Calendar.current.startOfDay(for: measurement.dateAdded)

                    LineMark(
                        x: .value(Constants.measurementDateLabel, date),
                        y: .value(Constants.measurementWeightLabel, weight),
                        series: .value(Constants.seriesLabel, Constants.measurementSeries)
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 1,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                    PointMark(
                        x: .value(Constants.measurementDateLabel, date),
                        y: .value(Constants.measurementWeightLabel, weight)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbol {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 10, height: 10)
                    }
                    .annotation(position: .top) {
                        Text(PlanComponentService.weightToString(weight))
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                            .offset(y: -4)
                    }
                }
            }
            .background(Color.primary.opacity(0.03))
            .chartXScale(domain: xDomain)
            .chartXAxis {
                AxisMarks(values: milestones.map(\.date)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(
                                date,
                                format: .dateTime
                                    .day(.twoDigits)
                                    .month(.twoDigits)
                            )
                            .offset(x: -18)
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .chartYAxis {
                AxisMarks(values: yAxisValues) { value in
                    if let weight = value.as(Double.self) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Text(PlanComponentService.weightToString(weight))
                        }
                    }
                }
            }
            .chartXVisibleDomain(length: Constants.visibleDuration)
            .chartScrollPosition(x: $scrollPosition)
            .chartScrollableAxes(.horizontal)
            .padding(.horizontal, -Constants.screenHorizontalPadding)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(plan.name)
    }

    private var xDomain: ClosedRange<Date> {
        PlanComponentService.makeXDomain(
            dates: milestones.map(\.date) + measurements.map {
                Calendar.current.startOfDay(for: $0.dateAdded)
            }
        )
    }

    private var today: Date {
        Calendar.current.startOfDay(for: .now)
    }

    private var yDomain: ClosedRange<Double> {
        let weights = milestones.map { convertedWeight($0.targetWeightSI) }
            + measurements.map { convertedWeight($0.weightSI) }
        guard let minimumWeight = weights.min(),
              let maximumWeight = weights.max() else {
            return 0...1
        }

        return (minimumWeight - Constants.weightPadding)...(maximumWeight + Constants.weightPadding)
    }

    private var yAxisValues: [Double] {
        [
            yDomain.lowerBound,
            convertedWeight(milestones.first?.targetWeightSI ?? 0),
            yDomain.upperBound
        ]
    }

    private func convertedWeight(_ weightSI: Double) -> Double {
        weightSI / Constants.gramsPerKilogram
    }

}

private enum Constants {
    static let todayLabel = "Today"
    static let endLabel = "End"
    static let weekValueLabel = "Week"
    static let planValueLabel = "Planned weight"
    static let measurementDateLabel = "Measurement date"
    static let measurementWeightLabel = "Measured weight"
    static let seriesLabel = "Series"
    static let planSeries = "Plan"
    static let measurementSeries = "Measurements"
    static let planLineOpacity = 0.55
    static let boundaryLineOpacity = 0.5
    static let weekLineOpacity = 0.16
    static let gramsPerKilogram = 1_000.0
    static let weightPadding = 2.0
    static let leadingPaddingDays = 3
    static let screenHorizontalPadding: CGFloat = 20
    static let visibleDuration = TimeInterval(2 * 7 * 86_400)
}
