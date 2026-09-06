import Testing
@testable import fitness_tracker

struct NutrientsTests {
    @Test func hidesAmountsThatAreZeroAfterDisplayRounding() {
        #expect(Nutrients.roundedAmountForDisplay(nil) == nil)
        #expect(Nutrients.roundedAmountForDisplay(0) == nil)
        #expect(Nutrients.roundedAmountForDisplay(0.04) == nil)
        #expect(Nutrients.roundedAmountForDisplay(0.06) == 0.1)
    }
}
