import Charts
import SwiftUI
import FitnessTrackerShared

public struct PlanComponent: View {
    public let title: String
    public let numberOfWeeks: Int
    public let latestMeasurement: UserMeasurement

    @State private var weekValues: [Date: WeekValue]
    @State private var scrollPosition: Date
    @State private var draggedWeekDate: Date?
    
    public init(title: String,
                numberOfWeeks: Int,
                latestMeasurement: UserMeasurement)
    {
        self.title = title
        self.numberOfWeeks = numberOfWeeks
        self.latestMeasurement = latestMeasurement
        
        let calendar = Calendar.current
        let dates = PlanComponentService.makeAxisDates(numberOfWeeks)
        let startDate = dates.first ?? calendar.startOfDay(for: .now)
        
        _scrollPosition = State(initialValue: PlanComponentService.makeXDomain(dates: dates).lowerBound)

        _weekValues = State(
            initialValue: PlanComponentService.makeWeekValues(
                dates: dates,
                startDate: startDate,
                startingWeightSI: latestMeasurement.weightSI
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

    // TODO: Move this to a static service thing
    private var yDomain: ClosedRange<Double> {
        let paddingWeightSi = 6000.0
        let maxWeeklyChangeSi = 1000.0
        
        let maxPotentialWeightIncrease = maxWeeklyChangeSi * Double(numberOfWeeks)
        let maxPotentialWeight = latestMeasurement.weightSI + maxPotentialWeightIncrease
        
        let minPotentialWeightDecrease = maxWeeklyChangeSi * Double(numberOfWeeks)
        let minPotentialWeight = latestMeasurement.weightSI - minPotentialWeightDecrease
        
        return convertWeight(weightSi:(minPotentialWeight - paddingWeightSi))...convertWeight(weightSi:(maxPotentialWeight + paddingWeightSi))
    }
    
    private func convertWeight(weightSi: Double) -> Double {
        // TODO: Add actual unit convertion
        return weightSi / 1000.0
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
                            onLongPress: lockWeekValue
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
                siConversionValue: 1000.0,
                scrollPosition: $scrollPosition,
                onChanged: { event in
                    updateDraggedWeek(with: event)
                },
                onChangeEnded: {
                    draggedWeekDate = nil
                },
                onLongPress: { event in
                    lockWeekValue(with: event)
                }
            )
            .chartScrollableAxes(.horizontal)
            .frame(height: 250)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
    
    private func getTouchedDate(
        at touchLocation: CGPoint,
        proxy: ChartProxy
    ) -> WeekValue? {
        let hitRadius: CGFloat = 22

        for date in axisDates {
            guard let xPosition = proxy.position(forX: date),
                  abs(xPosition - touchLocation.x) <= hitRadius,
                  let weekValue = weekValues[date] else {
                continue
            }

            let convertedWeight = convertWeight(
                weightSi: weekValue.weightSi
            )

            guard let yPosition = proxy.position(forY: convertedWeight),
                  abs(yPosition - touchLocation.y) <= hitRadius else {
                continue
            }

            let distance = hypot(
                xPosition - touchLocation.x,
                yPosition - touchLocation.y
            )

            guard distance <= hitRadius else {
                continue
            }

            return weekValue
        }
        
        return nil
    }
    
    private func lockWeekValue(at date: Date) {
        guard let weekValue = weekValues[date] else {
            return
        }

        weekValue.locked.toggle()
        weekValues[date] = weekValue
    }

    private func lockWeekValue(
        with event: WeeklyWeightLongPressEvent
    ) {
        guard let weekValue = weekValue(near: event.date),
              isWeightNear(
                  event.weightSi,
                  weekValue.weightSi
              ) else {
            return
        }

        lockWeekValue(at: weekValue.date)
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

            draggedWeekDate = matchedWeek.date
            draggedWeek = matchedWeek
        }

        let anchor = previousFixedOrLockedWeek(before: draggedWeek)

        guard let anchor else {
            setWeight(event.weightSi, for: draggedWeek)
            return
        }

        var weeksToUpdate: [WeekValue] = []
        var currentWeek = anchor.nextWeek

        while let week = currentWeek {
            weeksToUpdate.append(week)

            if week === draggedWeek {
                break
            }

            currentWeek = week.nextWeek
        }

        guard weeksToUpdate.last === draggedWeek else {
            return
        }

        let weightChangePerWeek = (
            event.weightSi - anchor.weightSi
        ) / Double(weeksToUpdate.count)

        for (index, week) in weeksToUpdate.enumerated() {
            let updatedWeightSi = anchor.weightSi
                + weightChangePerWeek * Double(index + 1)

            setWeight(updatedWeightSi, for: week)
        }
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
            <= Constants.pointHitValueRange * 1_000.0
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
        week.deltaSi = weightSi - latestMeasurement.weightSI
        weekValues[week.date] = week
    }
}

private struct ProjectedWeightLimit {
    let date: Date
    let maximumWeightSi: Double
    let minimumWeightSi: Double
}

private enum Constants {
    static let planValueLabel = "Planned weight"
    static let planLineYPosition = 0
    static let planLineColor = "SearchBoxSecondary"
    static let planLineOpacity = 0.3
    
    static let weekValueLabel = "Week"
    static let weightLimitSeriesLabel = "Weight limit"
    static let maximumGainSeries = "Maximum gain"
    static let maximumLossSeries = "Maximum loss"
    static let maximumWeeklyWeightChangeSi = 1_000.0

    
    
    static let weekLineOpacity = 0.2
    static let dateLabelOffset = -10.0
    static let secondsPerDay = 86_400
    static let minimumPointValue = -0.82
    static let maximumPointValue = 0.82
    static let pointSize = 55.0
    static let pointHitDateInterval = 3.0 * Double(secondsPerDay)
    static let pointHitValueRange = 1.0
    
    static let maxWeeklyGainSi = 0.5
    static let maxWeeklyLossSi = 1
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
                  )
    ).padding()
}
