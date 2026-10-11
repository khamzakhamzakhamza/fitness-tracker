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
        calendar: Calendar = .current
    ) -> [Date: WeekValue] {
        let values = dates.enumerated().map { index, date in
            let elapsedDays = calendar.dateComponents(
                [.day],
                from: startDate,
                to: date
            ).day ?? 0

            let elapsedWeeks = Double(elapsedDays) / 7.0
            let deltaSI = elapsedWeeks * 1_000.0

            return WeekValue(
                date: date,
                weightSi: startingWeightSI + deltaSI,
                deltaSi: deltaSI,
                fixed: index == 0,
                locked: false
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
        return weight.formatted(.number.precision(.fractionLength(0...2)))
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
