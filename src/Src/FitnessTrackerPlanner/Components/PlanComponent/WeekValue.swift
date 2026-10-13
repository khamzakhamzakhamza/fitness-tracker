import Foundation

final class WeekValue {
    let date: Date
    var weightSi: Double
    let fixed: Bool
    var locked: Bool
    weak var previousWeek: WeekValue?
    var nextWeek: WeekValue?

    init(
        date: Date,
        weightSi: Double,
        fixed: Bool,
        locked: Bool
    ) {
        self.date = date
        self.weightSi = weightSi
        self.fixed = fixed
        self.locked = locked
    }
}
