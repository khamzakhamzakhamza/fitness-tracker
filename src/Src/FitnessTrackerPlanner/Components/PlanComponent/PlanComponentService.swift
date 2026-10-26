import Foundation

internal enum PlanComponentService {
    internal static func getSundayDates(_ numberOfWeeks: Int) -> [Date] {
        guard numberOfWeeks > 0 else {
            return []
        }
        
        let sundayNo = 1

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekdayNo = calendar.component(.weekday, from: today)
        
        let daysUntilSunday = (sundayNo - weekdayNo + 7) % 7
        
        let firstSunday = calendar.date(
            byAdding: .day,
            value: daysUntilSunday,
            to: today
        )

        return (0..<numberOfWeeks).compactMap { week in
            calendar.date(byAdding: .weekOfYear, value: week, to: firstSunday!)
        }
    }
    
    internal static func makeWeekValues(
        dates: [Date],
        startDate: Date,
        startingWeightSI: Double,
        planDefinition: PlanDefinition,
        calendar: Calendar = .current
    ) -> [Date: WeekValue] {
        let values = dates.enumerated().map { index, date in
            let elapsedDays = calendar.dateComponents(
                [.day],
                from: startDate,
                to: date
            ).day ?? 0

            let weekNumber = Int(
                ceil(Double(elapsedDays) / 7.0)
            )
            let planWeek = planDefinition.weeks.first {
                $0.week == weekNumber
            }

            return WeekValue(
                date: date,
                weightSi: startingWeightSI
                    + (planWeek?.weightDeltaSI ?? 0),
                fixed: index == 0,
                locked: planWeek?.locked ?? false
            )
        }

        for index in values.indices {
            if index > values.startIndex {
                values[index].previousWeek = values[index - 1]
            }

            if index < values.index(before: values.endIndex) {
                values[index].nextWeek = values[index + 1]
            }
        }

        return Dictionary(
            uniqueKeysWithValues: values.map { value in
                (
                    value.date,
                    value
                )
            }
        )
    }
    
    internal static func weightToString(_ weight: Double) -> String {
        return weight.formatted(.number.precision(.fractionLength(0...1)))
    }

    internal static func makeXDomain(
        dates: [Date],
        calendar: Calendar = .current
    ) -> ClosedRange<Date> {
        guard let first = dates.first,
              let last = dates.last else {
            let today = calendar.startOfDay(for: .now)
            return today...today
        }

        let paddingDays = 3
        let lowerBound = calendar.date(
            byAdding: .day,
            value: -paddingDays,
            to: first
        ) ?? first
        let upperBound = calendar.date(
            byAdding: .day,
            value: paddingDays,
            to: last
        ) ?? last

        return lowerBound...upperBound
    }

    internal static func makeYDomain(
        numberOfWeeks: Int,
        startingWeightSI: Double,
        siConversionValue: Double
    ) -> ClosedRange<Double> {
        let paddingWeightSI = 8_000.0
        let maximumWeeklyChangeSI = 1_000.0
        let totalPotentialChangeSI = maximumWeeklyChangeSI
            * Double(numberOfWeeks)

        let minimumWeightSI = startingWeightSI
            - totalPotentialChangeSI
            - paddingWeightSI
        let maximumWeightSI = startingWeightSI
            + totalPotentialChangeSI
            + paddingWeightSI

        return (minimumWeightSI / siConversionValue)...(maximumWeightSI / siConversionValue)
    }
    
    internal static func makeAxisDates(_ numberOfWeeks: Int) -> [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: start)
        let daysUntilSunday = (1 - weekday + 7) % 7

        guard
            let firstSunday = calendar.date(
                byAdding: .day,
                value: daysUntilSunday,
                to: start
            ),
            let end = calendar.date(
                byAdding: .day,
                value: numberOfWeeks * 7,
                to: start
            )
        else {
            return [start]
        }

        let sundays = (0..<max(numberOfWeeks, 0)).compactMap { week in
            calendar.date(
                byAdding: .weekOfYear,
                value: week,
                to: firstSunday
            )
        }

        return Array(Set([start, end] + sundays)).sorted()
    }

}
