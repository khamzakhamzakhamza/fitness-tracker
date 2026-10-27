import Charts
import SwiftUI
import UIKit
import FitnessTrackerShared

public struct PlanComponent: View {
    public let title: String
    public let numberOfWeeks: Int
    public let latestMeasurement: UserMeasurement
    public let planDefinition: PlanDefinition
    public let onDragEnded: ([PlanMilestoneValue]) -> Void

    @State private var weekValues: [Date: WeekValue]
    @State private var scrollPosition: Date
    @State private var draggedWeekDate: Date?
    @State private var weightUnit: MeasurementUnitOption?
    
    public init(title: String,
                numberOfWeeks: Int,
                latestMeasurement: UserMeasurement,
                planDefinition: PlanDefinition,
                onDragEnded: @escaping ([PlanMilestoneValue]) -> Void)
    {
        self.title = title
        self.numberOfWeeks = numberOfWeeks
        self.latestMeasurement = latestMeasurement
        self.planDefinition = planDefinition
        self.onDragEnded = onDragEnded
        
        let calendar = Calendar.current
        let dates = PlanComponentService.makeAxisDates(numberOfWeeks)
        let startDate = dates.first ?? calendar.startOfDay(for: .now)
        
        _scrollPosition = State(initialValue: PlanComponentService.makeXDomain(dates: dates).lowerBound)

        _weekValues = State(
            initialValue: PlanComponentService.makeWeekValues(
                dates: dates,
                startDate: startDate,
                startingWeightSI: latestMeasurement.weightSI,
                planDefinition: planDefinition
            )
        )
    }
    
    private var axisDates: [Date] {
        PlanComponentService.makeAxisDates(numberOfWeeks)
    }
    
    private var visibleDuration: TimeInterval {
        let visibleWeeks = 4
        return TimeInterval(visibleWeeks * 7 * 86_400)
    }
    
    private var xDomain: ClosedRange<Date> {
        PlanComponentService.makeXDomain(dates: axisDates)
    }

    private var yDomain: ClosedRange<Double> {
        PlanComponentService.makeYDomain(
            numberOfWeeks: numberOfWeeks,
            startingWeightSI: latestMeasurement.weightSI,
            siConversionValue: weightConversionValue
        )
    }

    private var weightConversionValue: Double {
        guard let conversionValue = weightUnit?.siConversionValue,
              conversionValue > 0 else {
            return Constants.defaultWeightConversionValue
        }

        return conversionValue
    }

    private func convertWeight(weightSi: Double) -> Double {
        weightSi / weightConversionValue
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .padding(.leading, 20)
            
            Chart {
                if let anchor = latestFixedOrLockedWeekBeforeDraggedWeek {
                    ForEach(
                        projectedWeightLimits(from: anchor),
                        id: \.date
                    ) { projection in
                        LimitLineMark(
                            date: projection.date,
                            weight: convertWeight(
                                weightSi: projection.maximumWeightSi
                            ),
                            series: Constants.maximumGainSeries
                        )

                        LimitLineMark(
                            date: projection.date,
                            weight: convertWeight(
                                weightSi: projection.minimumWeightSi
                            ),
                            series: Constants.maximumLossSeries
                        )
                    }
                }

                RuleMark(y: .value(Constants.planValueLabel,
                                   convertWeight(weightSi: latestMeasurement.weightSI))
                )
                    .foregroundStyle(
                        Color(Constants.planLineColor)
                            .opacity(Constants.planLineOpacity)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [7, 7]))
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: .now)
                RuleMark(x: .value("Start", today))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                
                RuleMark(x: .value("End", calendar.date(byAdding: .day, value: numberOfWeeks * 7, to: today)!))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                
                ForEach(axisDates, id: \.self) { date in
                    RuleMark(
                        x: .value(Constants.weekValueLabel, date)
                    )
                        .foregroundStyle(
                            Color(Constants.planLineColor)
                                .opacity(Constants.weekLineOpacity)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1))

                    if let weekValue = weekValues[date] {
                        let convertedWeight = convertWeight(
                            weightSi: weekValue.weightSi
                        )

                        LineMark(
                            x: .value(Constants.weekValueLabel, date),
                            y: .value(
                                Constants.planValueLabel,
                                convertedWeight
                            )
                        )
                            .foregroundStyle(Color.accentColor)
                            .lineStyle(
                                StrokeStyle(
                                    lineWidth: 1,
                                    lineCap: .round
                                )
                            )

                        WeightPointMark(
                            date: date,
                            weight: convertedWeight,
                            fixed: weekValue.fixed,
                            locked: weekValue.locked,
                            isDragged: draggedWeekDate == date,
                            isLastDate: date == axisDates.last
                        )
                    }
                }
            }
            .background(Color.primary.opacity(0.03))
            .chartXScale(domain: xDomain)
            .chartXAxis {
                AxisMarks(values: PlanComponentService.getSundayDates(numberOfWeeks)) { value in
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
                AxisMarks(values: [yDomain.lowerBound, convertWeight(weightSi: latestMeasurement.weightSI), yDomain.upperBound]) {
                    value in
                    if let weight = value.as(Double.self) {
                        if weight == convertWeight(weightSi: latestMeasurement.weightSI) {
                             AxisValueLabel {Text(PlanComponentService.weightToString(weight))}
                         }
                         else {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {Text(PlanComponentService.weightToString(weight))}
                         }
                    }
                }
            }
            .chartXVisibleDomain(length: visibleDuration)
            .chartScrollPosition(x: $scrollPosition)
            .addChartGestures(
                siConversionValue: weightConversionValue,
                scrollPosition: $scrollPosition,
                onChanged: { event in
                    updateDraggedWeek(with: event)
                },
                onChangeEnded: {
                    onDragEnded(planMilestones)
                    draggedWeekDate = nil
                },
                onTap: { event in
                    lockWeekValue(with: event)
                }
            )
            .chartScrollableAxes(.horizontal)
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .task {
            loadWeightUnit()
            onDragEnded(planMilestones)
        }
    }

    private var planMilestones: [PlanMilestoneValue] {
        weekValues.values
            .sorted { $0.date < $1.date }
            .map {
                PlanMilestoneValue(
                    date: $0.date,
                    targetWeightSI: $0.weightSi
                )
            }
    }

    private func loadWeightUnit() {
        guard let measurementUnitService = PlanningDependencyContext.measurementUnitService else {
            return
        }

        do {
            let units = try measurementUnitService.fetchWeightMeasurementUnits()
            weightUnit = units.first(where: \.isDefault) ?? units.first
        } catch {
            weightUnit = nil
        }
    }
    
    private func lockWeekValue(
        with event: WeeklyWeightTapEvent
    ) {
        guard let weekValue = weekValue(near: event.date),
              isWeightNear(
                  event.weightSi,
                  weekValue.weightSi
              ) else {
            return
        }

        weekValue.locked.toggle()
        weekValues[weekValue.date] = weekValue
    }

    private var latestFixedOrLockedWeekBeforeDraggedWeek: WeekValue? {
        guard let draggedWeekDate,
              let draggedWeek = weekValues[draggedWeekDate] else {
            return nil
        }

        return previousFixedOrLockedWeek(before: draggedWeek)
    }

    private func projectedWeightLimits(
        from anchor: WeekValue
    ) -> [ProjectedWeightLimit] {
        var projections: [ProjectedWeightLimit] = []
        var currentWeek: WeekValue? = anchor
        var elapsedWeeks = 0

        while let week = currentWeek {
            let totalChangeSi = Double(elapsedWeeks)
                * Constants.maximumWeeklyWeightChangeSi

            projections.append(
                ProjectedWeightLimit(
                    date: week.date,
                    maximumWeightSi: anchor.weightSi + totalChangeSi,
                    minimumWeightSi: anchor.weightSi - totalChangeSi
                )
            )

            currentWeek = week.nextWeek
            elapsedWeeks += 1
        }

        return projections
    }

    private func updateDraggedWeek(
        with event: WeeklyWeightChangeEvent
    ) {
        let draggedWeek: WeekValue

        if let draggedWeekDate,
           let activeDraggedWeek = weekValues[draggedWeekDate] {
            draggedWeek = activeDraggedWeek
        } else {
            guard let matchedWeek = weekValue(near: event.date),
                  isWeightNear(
                      event.originWeightSi,
                      matchedWeek.weightSi
                  ) else {
                return
            }

            draggedWeek = matchedWeek
        }

        guard abs(event.weightSi - draggedWeek.weightSi)
                >= Constants.minimumDragWeightChangeSi else {
            return
        }

        guard let previousUpdates = proposedPreviousWeekUpdates(
            from: draggedWeek,
            draggedWeightSi: event.weightSi
        ),
        let followingUpdates = proposedFollowingWeekUpdates(
            from: draggedWeek,
            draggedWeightSi: event.weightSi
        ) else {
            return
        }

        draggedWeekDate = draggedWeek.date
        setWeight(event.weightSi, for: draggedWeek)

        for update in previousUpdates + followingUpdates {
            setWeight(update.weightSi, for: update.week)
        }

        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func proposedPreviousWeekUpdates(
        from draggedWeek: WeekValue,
        draggedWeightSi: Double
    ) -> [WeekWeightUpdate]? {
        var updates: [WeekWeightUpdate] = []
        var followingWeightSi = draggedWeightSi
        var previousWeek = draggedWeek.previousWeek

        while let week = previousWeek {
            if week.fixed || week.locked {
                guard abs(week.weightSi - followingWeightSi)
                        <= Constants.maximumWeeklyWeightChangeSi else {
                    return nil
                }

                return updates
            }

            let updatedWeightSi = min(
                max(
                    week.weightSi,
                    followingWeightSi
                        - Constants.maximumWeeklyWeightChangeSi
                ),
                followingWeightSi
                    + Constants.maximumWeeklyWeightChangeSi
            )

            updates.append(
                WeekWeightUpdate(
                    week: week,
                    weightSi: updatedWeightSi
                )
            )

            followingWeightSi = updatedWeightSi
            previousWeek = week.previousWeek
        }

        return updates
    }

    private func proposedFollowingWeekUpdates(
        from draggedWeek: WeekValue,
        draggedWeightSi: Double
    ) -> [WeekWeightUpdate]? {
        var updates: [WeekWeightUpdate] = []
        var precedingWeightSi = draggedWeightSi
        var followingWeek = draggedWeek.nextWeek

        while let week = followingWeek {
            let updatedWeightSi = min(
                max(
                    week.weightSi,
                    precedingWeightSi
                        - Constants.maximumWeeklyWeightChangeSi
                ),
                precedingWeightSi
                    + Constants.maximumWeeklyWeightChangeSi
            )

            updates.append(
                WeekWeightUpdate(
                    week: week,
                    weightSi: updatedWeightSi
                )
            )

            precedingWeightSi = updatedWeightSi
            followingWeek = week.nextWeek
        }

        return updates
    }

    private func weekValue(near date: Date) -> WeekValue? {
        let calendar = Calendar.current
        let returnedDate = calendar.startOfDay(for: date)

        for dayOffset in [0, -1, 1] {
            guard let candidateDate = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: returnedDate
            ) else {
                continue
            }

            if let weekValue = weekValues[candidateDate] {
                return weekValue
            }
        }

        return nil
    }

    private func isWeightNear(
        _ firstWeightSi: Double,
        _ secondWeightSi: Double
    ) -> Bool {
        abs(firstWeightSi - secondWeightSi)
            <= Constants.pointHitValueRange * 5000.0
    }

    private func previousFixedOrLockedWeek(
        before week: WeekValue
    ) -> WeekValue? {
        var previousWeek = week.previousWeek

        while let candidate = previousWeek {
            if candidate.fixed || candidate.locked {
                return candidate
            }

            previousWeek = candidate.previousWeek
        }

        return nil
    }

    private func setWeight(
        _ weightSi: Double,
        for week: WeekValue
    ) {
        week.weightSi = weightSi
        weekValues[week.date] = week
    }
}

private struct ProjectedWeightLimit {
    let date: Date
    let maximumWeightSi: Double
    let minimumWeightSi: Double
}

private struct WeekWeightUpdate {
    let week: WeekValue
    let weightSi: Double
}

private enum Constants {
    static let planValueLabel = "Planned weight"
    static let planLineColor = "SearchBoxSecondary"
    static let planLineOpacity = 0.3
    
    static let weekValueLabel = "Week"
    static let maximumGainSeries = "Maximum gain"
    static let maximumLossSeries = "Maximum loss"
    static let maximumWeeklyWeightChangeSi = 1_000.0
    static let minimumDragWeightChangeSi = 100.0
    static let defaultWeightConversionValue = 1_000.0
    
    static let weekLineOpacity = 0.2
    static let secondsPerDay = 86_400
    static let pointHitValueRange = 1.0
}

#Preview {
    PlanComponent(title: "Maintenance",
                  numberOfWeeks: 24,
                  latestMeasurement: UserMeasurement(
                    id: UUID().uuidString,
                    userID: UUID().uuidString,
                    weightSI: 85_000,
                    heightSI: 181,
                    leanMass: 77,
                    activityLevelID: 3
                  ),
                  planDefinition: .maintenance24Weeks,
                  onDragEnded: { _ in }
    ).padding()
}
