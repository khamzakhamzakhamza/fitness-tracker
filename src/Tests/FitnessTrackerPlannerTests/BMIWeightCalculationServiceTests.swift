import Testing
@testable import FitnessTrackerPlanner

struct BMIWeightCalculationServiceTests {
    @Test
    func calculatesWeightFromBMIAndHeight() throws {
        let service = BMIWeightCalculationService()

        let weightSI = try service.calculateWeightSI(
            targetBMI: 24.9,
            heightSI: 180
        )

        #expect(abs(weightSI - 80_676) < 0.001)
    }

    @Test
    func rejectsInvalidBMIInput() {
        let service = BMIWeightCalculationService()

        #expect(throws: BMIWeightCalculationError.invalidInput) {
            try service.calculateWeightSI(targetBMI: 0, heightSI: 180)
        }
    }
}
