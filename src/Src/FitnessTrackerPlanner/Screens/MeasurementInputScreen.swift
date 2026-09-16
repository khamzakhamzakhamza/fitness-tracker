import SwiftUI
import FitnessTrackerShared

public struct MeasurementInputScreen: View {
    @State private var weight = ""
    @State private var height = ""
    @State private var leanMass = ""
    @State private var weightUnits: [MeasurementUnitOption] = []
    @State private var heightUnits: [MeasurementUnitOption] = []
    @State private var weightUnit = ""
    @State private var heightUnit = ""
    @State private var leanMassPreset: String?
    @State private var activity = Constants.activityOptions[0].description
    @State private var birthday: Date?
    @State private var shouldShowValidationErrors = false
    @State private var isShowingPlanCreation = false

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Constants.title)
                        .font(.system(size: 28, weight: .black))

                    InfoLabel(text: Constants.infoMessage)

                    VStack(spacing: 16) {
                        InputNumberRow(
                            value: $weight,
                            label: Constants.weightLabel,
                            placeholder: weightPlaceholder,
                            allowedRange: weightInputRange,
                            unitOptions: weightUnits.map(\.shortName),
                            selectedUnit: $weightUnit,
                            showValidationError: shouldShowValidationErrors && !isWeightValid
                        )

                        InputNumberRow(
                            value: $height,
                            label: Constants.heightLabel,
                            placeholder: heightPlaceholder,
                            allowedRange: heightInputRange,
                            unitOptions: heightUnits.map(\.shortName),
                            selectedUnit: $heightUnit,
                            showValidationError: shouldShowValidationErrors && !isHeightValid
                        )

                        InputNumberRow(
                            value: $leanMass,
                            label: Constants.leanMassLabel,
                            placeholder: Constants.leanMassPlaceholder,
                            allowedRange: Constants.leanMassRange,
                            unit: Constants.percentageUnit,
                            inlineOptions: Constants.leanMassOptions,
                            selectedInlineOption: $leanMassPreset,
                            showValidationError: shouldShowValidationErrors && !isLeanMassValid
                        )

                        InputDropdownRow(
                            selection: $activity,
                            label: Constants.activityLabel,
                            options: Constants.activityOptions.map(\.description)
                        )
                    }
                    .padding(.top, 4)

                }
                .padding(20)
                .padding(.top, 15)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: 0) {
                CalorieBreakdown(
                    restingCalories: calorieCalculation?.restingCalories,
                    restingCalculation: Constants.restingCalculation,
                    activityDescription: activity,
                    activityMultiplier: calorieCalculation?.activityMultiplier
                )

                CalorieReadout(
                    calories: calorieCalculation?.fullDailyCalories,
                    detail: Constants.maintenanceDetailPrefix
                )
            }
            .padding(.horizontal, 20)

            PrimaryActionButton(title: Constants.nextButtonTitle) {
                saveMeasurement()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
        .dismissesKeyboardOnDownwardSwipe()
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingPlanCreation) {
            PlanCreationScreen()
        }
        .task {
            loadMeasurementUnits()
            loadBirthday()
        }
        .onChange(of: leanMassPreset) { _, preset in
            switch preset {
            case Constants.averageMaleLabel:
                leanMass = Constants.averageMaleLeanMass
            case Constants.averageFemaleLabel:
                leanMass = Constants.averageFemaleLeanMass
            default:
                break
            }
        }
        .onChange(of: leanMass) { _, value in
            leanMassPreset = matchingLeanMassPreset(for: value)
        }
        .onChange(of: weightUnit) { _, selectedUnit in
            updateDefaultWeightUnit(shortName: selectedUnit)
        }
        .onChange(of: heightUnit) { _, selectedUnit in
            updateDefaultHeightUnit(shortName: selectedUnit)
        }
    }

    private var isWeightValid: Bool {
        guard let value = numericValue(from: weight),
              let selectedUnit = weightUnits.first(where: { $0.shortName == weightUnit }) else {
            return false
        }

        let valueSI = value * selectedUnit.siConversionValue
        return Constants.weightRangeSI.contains(valueSI)
    }

    private var isHeightValid: Bool {
        guard let value = numericValue(from: height),
              let selectedUnit = heightUnits.first(where: { $0.shortName == heightUnit }) else {
            return false
        }

        let valueSI = value * selectedUnit.siConversionValue
        return Constants.heightRangeSI.contains(valueSI)
    }

    private var isLeanMassValid: Bool {
        guard let value = numericValue(from: leanMass) else {
            return false
        }

        return Constants.leanMassRange.contains(value)
    }

    private func matchingLeanMassPreset(for value: String) -> String? {
        guard let value = numericValue(from: value) else {
            return nil
        }

        if value == numericValue(from: Constants.averageMaleLeanMass) {
            return Constants.averageMaleLabel
        }

        if value == numericValue(from: Constants.averageFemaleLeanMass) {
            return Constants.averageFemaleLabel
        }

        return nil
    }

    private func saveMeasurement() {
        shouldShowValidationErrors = true

        guard isWeightValid,
              isHeightValid,
              isLeanMassValid,
              let weightValue = numericValue(from: weight),
              let heightValue = numericValue(from: height),
              let leanMassValue = numericValue(from: leanMass),
              let selectedWeightUnit = weightUnits.first(where: { $0.shortName == weightUnit }),
              let selectedHeightUnit = heightUnits.first(where: { $0.shortName == heightUnit }),
              let selectedActivity = Constants.activityOptions.first(where: { $0.description == activity }) else {
            return
        }

        isShowingPlanCreation = PlanningService.shared.createMeasurement(
            weightSI: weightValue * selectedWeightUnit.siConversionValue,
            heightSI: heightValue * selectedHeightUnit.siConversionValue,
            leanMass: leanMassValue,
            activityLevelID: selectedActivity.id
        )
    }

    private func loadMeasurementUnits() {
        guard let measurementUnitService = PlanningDependencyContext.measurementUnitService else {
            return
        }

        do {
            weightUnits = try measurementUnitService.fetchWeightMeasurementUnits()
            heightUnits = try measurementUnitService.fetchHeightMeasurementUnits()
            weightUnit = preferredUnit(from: weightUnits)?.shortName ?? ""
            heightUnit = preferredUnit(from: heightUnits)?.shortName ?? ""
        } catch {
            weightUnits = []
            heightUnits = []
        }
    }

    private func loadBirthday() {
        do {
            birthday = try PlanningService.shared.fetchUser()?.birthday
        } catch {
            birthday = nil
        }
    }

    private func updateDefaultWeightUnit(shortName: String) {
        guard let measurementUnitService = PlanningDependencyContext.measurementUnitService,
              let selectedUnit = weightUnits.first(where: { $0.shortName == shortName }) else {
            return
        }

        do {
            try measurementUnitService.setDefaultWeightMeasurementUnit(id: selectedUnit.id)
            weightUnits = try measurementUnitService.fetchWeightMeasurementUnits()
        } catch {
            return
        }
    }

    private func updateDefaultHeightUnit(shortName: String) {
        guard let measurementUnitService = PlanningDependencyContext.measurementUnitService,
              let selectedUnit = heightUnits.first(where: { $0.shortName == shortName }) else {
            return
        }

        do {
            try measurementUnitService.setDefaultHeightMeasurementUnit(id: selectedUnit.id)
            heightUnits = try measurementUnitService.fetchHeightMeasurementUnits()
        } catch {
            return
        }
    }

    private func preferredUnit(from units: [MeasurementUnitOption]) -> MeasurementUnitOption? {
        units.first(where: \.isDefault) ?? units.first
    }

    private var calorieCalculation: CalorieCalculation? {
        guard isWeightValid,
              isHeightValid,
              isLeanMassValid,
              let weightValue = numericValue(from: weight),
              let heightValue = numericValue(from: height),
              let leanMassValue = numericValue(from: leanMass),
              let birthday,
              let selectedWeightUnit = weightUnits.first(where: { $0.shortName == weightUnit }),
              let selectedHeightUnit = heightUnits.first(where: { $0.shortName == heightUnit }),
              let selectedActivity = Constants.activityOptions.first(where: { $0.description == activity }) else {
            return nil
        }

        let weightKilograms = weightValue * selectedWeightUnit.siConversionValue / 1_000
        let heightCentimetres = heightValue * selectedHeightUnit.siConversionValue

        do {
            let restingCalories = try CalorieCalculationService.shared.calculateRestingCalories(
                weightKilograms: weightKilograms,
                heightCentimetres: heightCentimetres,
                birthday: birthday,
                leanMassPercentage: leanMassValue
            )
            let fullDailyCalories = try CalorieCalculationService.shared.calculateFullDailyCalories(
                restingCalories: restingCalories,
                activityMultiplier: selectedActivity.multiplier
            )

            return CalorieCalculation(
                restingCalories: Int(restingCalories.rounded()),
                fullDailyCalories: Int(fullDailyCalories.rounded()),
                activityMultiplier: selectedActivity.multiplier
            )
        } catch {
            return nil
        }
    }

    private var weightPlaceholder: String {
        convertedPlaceholder(
            siValue: Constants.weightPlaceholderSI,
            selectedUnit: weightUnit,
            units: weightUnits,
            fallbackConversionValue: Constants.defaultWeightConversionValue
        )
    }

    private var heightPlaceholder: String {
        convertedPlaceholder(
            siValue: Constants.heightPlaceholderSI,
            selectedUnit: heightUnit,
            units: heightUnits,
            fallbackConversionValue: Constants.defaultHeightConversionValue
        )
    }

    private var weightInputRange: ClosedRange<Double>? {
        convertedRange(
            siRange: Constants.weightRangeSI,
            selectedUnit: weightUnit,
            units: weightUnits
        )
    }

    private var heightInputRange: ClosedRange<Double>? {
        convertedRange(
            siRange: Constants.heightRangeSI,
            selectedUnit: heightUnit,
            units: heightUnits
        )
    }

    private func convertedRange(
        siRange: ClosedRange<Double>,
        selectedUnit: String,
        units: [MeasurementUnitOption]
    ) -> ClosedRange<Double>? {
        guard let conversionValue = units.first(where: { $0.shortName == selectedUnit })?.siConversionValue,
              conversionValue > 0 else {
            return nil
        }

        return (siRange.lowerBound / conversionValue)...(siRange.upperBound / conversionValue)
    }

    private func convertedPlaceholder(
        siValue: Double,
        selectedUnit: String,
        units: [MeasurementUnitOption],
        fallbackConversionValue: Double
    ) -> String {
        let conversionValue = units.first(where: { $0.shortName == selectedUnit })?.siConversionValue
            ?? fallbackConversionValue
        let convertedValue = siValue / conversionValue
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: convertedValue)) ?? String(convertedValue)
    }

    private func numericValue(from input: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = .current
        return formatter.number(from: input)?.doubleValue ?? Double(input)
    }
}

private struct CalorieCalculation {
    let restingCalories: Int
    let fullDailyCalories: Int
    let activityMultiplier: Double
}

private struct ActivityOption {
    let id: Int
    let description: String
    let multiplier: Double
}

private enum Constants {
    static let title = "Pls give us some more personal data"
    static let infoMessage = "Your calorie intake will be adjusted as you log more measurements"
    static let weightLabel = "Weight"
    static let weightPlaceholderSI = 77_000.0
    static let defaultWeightConversionValue = 1_000.0
    static let weightRangeSI = 20_000.0...500_000.0
    static let heightLabel = "Height"
    static let heightPlaceholderSI = 180.0
    static let defaultHeightConversionValue = 1.0
    static let heightRangeSI = 50.0...300.0
    static let leanMassLabel = "Lean mass"
    static let leanMassPlaceholder = "80"
    static let leanMassRange = 1.0...100.0
    static let percentageUnit = "%"
    static let averageMaleLabel = "Avg. Male"
    static let averageFemaleLabel = "Avg. Female"
    static let averageMaleLeanMass = "79"
    static let averageFemaleLeanMass = "69"
    static let leanMassOptions = [averageMaleLabel, averageFemaleLabel]
    static let activityLabel = "How often do you exercise?"
    static let activityOptions = [
        ActivityOption(id: 1, description: "desk job, no training", multiplier: 1.2),
        ActivityOption(id: 2, description: "1–3 sessions a week", multiplier: 1.375),
        ActivityOption(id: 3, description: "3–5 sessions a week", multiplier: 1.55),
        ActivityOption(id: 4, description: "6–7 sessions a week", multiplier: 1.725),
        ActivityOption(id: 5, description: "training twice a day", multiplier: 1.9)
    ]
    static let restingCalculation = "Mifflin-St Jeor"
    static let maintenanceDetailPrefix = "a day to hold current weight"
    static let nextButtonTitle = "NEXT"
    static let backgroundColor = "AppBackground"
}
