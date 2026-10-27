import Charts
import SwiftUI

public struct PlanProgress: View {
    public let plan: PlanValue
    public let milestones: [PlanMilestoneValue]

    public init(
        plan: PlanValue,
        milestones: [PlanMilestoneValue]
    ) {
        self.plan = plan
        self.milestones = milestones.sorted { $0.date < $1.date }
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
                        Color(Constants.planLineColor)
                            .opacity(Constants.planLineOpacity)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [7, 7]))
                }

                if let startDate = milestones.first?.date {
                    RuleMark(x: .value(Constants.startLabel, startDate))
                        .foregroundStyle(Color.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }

                if let endDate = milestones.last?.date {
                    RuleMark(x: .value(Constants.endLabel, endDate))
                        .foregroundStyle(Color.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }

                ForEach(Array(milestones.enumerated()), id: \.element.date) { index, milestone in
                    let weight = convertedWeight(milestone.targetWeightSI)

                    RuleMark(x: .value(Constants.weekValueLabel, milestone.date))
                        .foregroundStyle(
                            Color(Constants.planLineColor)
                                .opacity(Constants.weekLineOpacity)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1))

                    LineMark(
                        x: .value(Constants.weekValueLabel, milestone.date),
                        y: .value(Constants.planValueLabel, weight)
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 1,
                            lineCap: .round
                        )
                    )

                    WeightPointMark(
                        date: milestone.date,
                        weight: weight,
                        fixed: index == milestones.startIndex,
                        locked: false,
                        isDragged: false,
                        isLastDate: index == milestones.index(before: milestones.endIndex)
                    )
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
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(plan.name)
    }

    private var xDomain: ClosedRange<Date> {
        PlanComponentService.makeXDomain(dates: milestones.map(\.date))
    }

    private var yDomain: ClosedRange<Double> {
        let weights = milestones.map { convertedWeight($0.targetWeightSI) }
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
    static let startLabel = "Start"
    static let endLabel = "End"
    static let weekValueLabel = "Week"
    static let planValueLabel = "Planned weight"
    static let planLineColor = "SearchBoxSecondary"
    static let planLineOpacity = 0.55
    static let weekLineOpacity = 0.16
    static let gramsPerKilogram = 1_000.0
    static let weightPadding = 2.0
    static let visibleDuration = TimeInterval(4 * 7 * 86_400)
}
