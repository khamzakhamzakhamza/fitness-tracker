import Charts
import SwiftUI

public struct PlanProgress: View {
    public let plan: PlanValue
    public let milestones: [PlanMilestoneValue]
    public let measurements: [UserMeasurement]

    public init(
        plan: PlanValue,
        milestones: [PlanMilestoneValue],
        measurements: [UserMeasurement]
    ) {
        self.plan = plan
        self.milestones = milestones.sorted { $0.date < $1.date }
        self.measurements = measurements.sorted { $0.dateAdded < $1.dateAdded }
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
                    .foregroundStyle(Color.primary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                if let endDate = milestones.last?.date {
                    RuleMark(x: .value(Constants.endLabel, endDate))
                        .foregroundStyle(Color.secondary.opacity(Constants.boundaryLineOpacity))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }

                ForEach(Array(milestones.enumerated()), id: \.element.date) { index, milestone in
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
                            .offset(
                                x: pointLabelOffset(for: index),
                                y: -4
                            )
                    }
                }

                ForEach(measurements, id: \.id) { measurement in
                    let weight = convertedWeight(measurement.weightSI)

                    LineMark(
                        x: .value(Constants.measurementDateLabel, measurement.dateAdded),
                        y: .value(Constants.measurementWeightLabel, weight),
                        series: .value(Constants.seriesLabel, Constants.measurementSeries)
                    )
                    .foregroundStyle(Color.primary)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                    PointMark(
                        x: .value(Constants.measurementDateLabel, measurement.dateAdded),
                        y: .value(Constants.measurementWeightLabel, weight)
                    )
                    .foregroundStyle(Color.primary)
                    .symbolSize(35)
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
            .chartScrollableAxes(.horizontal)
            .padding(.horizontal, -Constants.screenHorizontalPadding)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(plan.name)
    }

    private var xDomain: ClosedRange<Date> {
        PlanComponentService.makeXDomain(
            dates: milestones.map(\.date) + measurements.map(\.dateAdded)
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

    private func pointLabelOffset(for index: Int) -> CGFloat {
        if index == milestones.startIndex {
            return -15
        }

        if index == milestones.index(before: milestones.endIndex) {
            return 15
        }

        return 0
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
    static let screenHorizontalPadding: CGFloat = 20
    static let visibleDuration = TimeInterval(4 * 7 * 86_400)
}
