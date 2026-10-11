import Foundation

final class WeekValue {
    let date: Date
    var weightSi: Double
    var deltaSi: Double
    let fixed: Bool
    var locked: Bool
    weak var previousWeek: WeekValue?
    var nextWeek: WeekValue?

    init(
        date: Date,
        weightSi: Double,
        deltaSi: Double,
        fixed: Bool,
        locked: Bool,
        previousWeek: WeekValue? = nil,
        nextWeek: WeekValue? = nil
    ) {
        self.date = date
        self.weightSi = weightSi
        self.deltaSi = deltaSi
        self.fixed = fixed
        self.locked = locked
        self.previousWeek = previousWeek
        self.nextWeek = nextWeek
    }
}
