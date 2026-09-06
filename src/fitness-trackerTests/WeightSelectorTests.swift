import Testing
@testable import fitness_tracker

struct WeightSelectorTests {
    @Test func usesHalfServingServingAndFullAmount() {
        let weights = WeightSelector.presetWeights(
            servingSizeGrams: 100,
            totalAmountGrams: 250
        )

        #expect(weights == [50, 100, 250])
    }

    @Test func usesDoubleServingWhenFullAmountMatchesServing() {
        let weights = WeightSelector.presetWeights(
            servingSizeGrams: 100,
            totalAmountGrams: 100
        )

        #expect(weights == [50, 100, 200])
    }

    @Test func addsLargerServingOptionsWhenTotalIsBelowServing() {
        let weights = WeightSelector.presetWeights(
            servingSizeGrams: 100,
            totalAmountGrams: 40
        )

        #expect(weights == [40, 50, 100, 150, 200])
    }

    @Test func capsWeightsAndPresetsAtTwoKilograms() {
        #expect(WeightSelector.clampedWeight(2_500) == 2_000)
        #expect(
            WeightSelector.clampedWeight(
                WeightSelector.weight(from: "2500") ?? 0
            ) == 2_000
        )

        let weights = WeightSelector.presetWeights(
            servingSizeGrams: 1_500,
            totalAmountGrams: 3_000
        )

        #expect(weights == [750, 1_500, 2_000])
    }
}
