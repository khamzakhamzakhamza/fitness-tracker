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
    @State private var activity = Constants.activityOptions[0]

    @FocusState private var isWeightFocused: Bool
    @FocusState private var isHeightFocused: Bool
    @FocusState private var isLeanMassFocused: Bool

    public init() {}

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
                            placeholder: Constants.weightPlaceholder,
                            unitOptions: weightUnits.map(\.shortName),
                            selectedUnit: $weightUnit,
                            focus: $isWeightFocused
                        )

                        InputNumberRow(
                            value: $height,
                            label: Constants.heightLabel,
                            placeholder: Constants.heightPlaceholder,
                            unitOptions: heightUnits.map(\.shortName),
                            selectedUnit: $heightUnit,
                            focus: $isHeightFocused
                        )

                        InputNumberRow(
                            value: $leanMass,
                            label: Constants.leanMassLabel,
                            placeholder: Constants.leanMassPlaceholder,
                            unit: Constants.percentageUnit,
                            inlineOptions: Constants.leanMassOptions,
                            selectedInlineOption: $leanMassPreset,
                            focus: $isLeanMassFocused
                        )

                        InputDropdownRow(
                            selection: $activity,
                            label: Constants.activityLabel,
                            options: Constants.activityOptions
                        )
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .padding(.top, 15)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryActionButton(title: Constants.nextButtonTitle) {}
        }
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .task {
            loadMeasurementUnits()
        }
        .onChange(of: leanMassPreset) { preset in
            switch preset {
            case Constants.averageMaleLabel:
                leanMass = Constants.averageMaleLeanMass
            case Constants.averageFemaleLabel:
                leanMass = Constants.averageFemaleLeanMass
            default:
                break
            }
            dismissKeyboard()
        }
        .onChange(of: activity) { _ in
            dismissKeyboard()
        }
        .onChange(of: weightUnit) { selectedUnit in
            updateDefaultWeightUnit(shortName: selectedUnit)
            dismissKeyboard()
        }
        .onChange(of: heightUnit) { selectedUnit in
            updateDefaultHeightUnit(shortName: selectedUnit)
            dismissKeyboard()
        }
        .onChange(of: isWeightFocused) { isFocused in
            if isFocused {
                isHeightFocused = false
                isLeanMassFocused = false
            }
        }
        .onChange(of: isHeightFocused) { isFocused in
            if isFocused {
                isWeightFocused = false
                isLeanMassFocused = false
            }
        }
        .onChange(of: isLeanMassFocused) { isFocused in
            if isFocused {
                isWeightFocused = false
                isHeightFocused = false
                leanMassPreset = nil
            }
        }
    }

    private func dismissKeyboard() {
        isWeightFocused = false
        isHeightFocused = false
        isLeanMassFocused = false
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
}

private enum Constants {
    static let title = "Pls set your measurments"
    static let infoMessage = "Your calorie intake will be adjusted as you log more measurements in the app."
    static let weightLabel = "Weight"
    static let weightPlaceholder = "82.4"
    static let heightLabel = "Height"
    static let heightPlaceholder = "180"
    static let leanMassLabel = "Lean mass"
    static let leanMassPlaceholder = "80"
    static let percentageUnit = "%"
    static let averageMaleLabel = "Avg. Male"
    static let averageFemaleLabel = "Avg. Female"
    static let averageMaleLeanMass = "79"
    static let averageFemaleLeanMass = "69"
    static let leanMassOptions = [averageMaleLabel, averageFemaleLabel]
    static let activityLabel = "How often do you exercise?"
    static let activityOptions = [
        "desk job, no training",
        "1–3 sessions a week",
        "3–5 sessions a week",
        "6–7 sessions a week",
        "training twice a day"
    ]
    static let nextButtonTitle = "NEXT"
    static let backgroundColor = "AppBackground"
}
