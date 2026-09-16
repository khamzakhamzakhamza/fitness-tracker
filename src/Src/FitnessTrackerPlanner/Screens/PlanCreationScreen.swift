import SwiftUI
import FitnessTrackerShared

public struct PlanCreationScreen: View {
    @State private var selectedPlanName = PlanTemplate.maintenance.name
    @State private var activePlanName = PlanTemplate.maintenance.name
    @State private var planName = PlanTemplate.maintenance.name
    @State private var finalWeight = ""
    @State private var weightUnits: [MeasurementUnitOption] = []
    @State private var weightUnit = ""
    @State private var currentMeasurement: UserMeasurement?
    @State private var planLength = String(PlanTemplate.maintenance.lengthInWeeks)
    @State private var selectedPlanLength: String? = Constants.defaultPlanLengthOption
    @State private var pendingPlanName: String?
    @State private var isShowingUnsavedChangesWarning = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(Constants.title)
                        .font(.system(size: 28, weight: .black))

                    InputDropdownRow(
                        selection: planSelection,
                        label: Constants.planSelectorLabel,
                        options: PlanTemplate.preMadePlans.map(\.name)
                    )

                    Divider()

                    InputTextRow(
                        text: $planName,
                        label: Constants.planNameLabel,
                        placeholder: Constants.planNamePlaceholder
                    )

                    InputNumberRow(
                        value: $finalWeight,
                        label: Constants.finalWeightLabel,
                        unitOptions: weightUnits.map(\.shortName),
                        selectedUnit: $weightUnit
                    )

                    InputNumberRow(
                        value: $planLength,
                        label: Constants.planTimeLabel,
                        allowedRange: Constants.planLengthRange,
                        unit: Constants.weeksUnit,
                        inlineOptions: Constants.planLengthOptions,
                        selectedInlineOption: $selectedPlanLength
                    )

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .padding(.top, 15)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryActionButton(title: Constants.activatePlanButtonTitle) {}
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
        .dismissesKeyboardOnDownwardSwipe()
        .navigationBarBackButtonHidden(true)
        .task {
            loadPlanData()
        }
        .onChange(of: selectedPlanLength) { _, selectedLength in
            guard let selectedLength,
                  let weeks = Int(selectedLength.components(separatedBy: " ").first ?? "") else {
                return
            }

            planLength = String(weeks)
        }
        .onChange(of: planLength) { _, length in
            selectedPlanLength = Constants.planLengthOptions.first {
                $0.hasPrefix("\(length) ")
            }
        }
        .onChange(of: weightUnit) { previousUnit, selectedUnit in
            updateFinalWeight(from: previousUnit, to: selectedUnit)
            updateDefaultWeightUnit(shortName: selectedUnit)
        }
        .alert(
            Constants.unsavedChangesTitle,
            isPresented: $isShowingUnsavedChangesWarning
        ) {
            Button(Constants.cancelButtonTitle, role: .cancel) {
                pendingPlanName = nil
            }

            Button(Constants.discardChangesButtonTitle, role: .destructive) {
                guard let pendingPlanName else {
                    return
                }

                applyPlanTemplate(named: pendingPlanName)
                self.pendingPlanName = nil
            }
        } message: {
            Text(Constants.unsavedChangesMessage)
        }
    }

    private var planSelection: Binding<String> {
        Binding(
            get: { selectedPlanName },
            set: { requestPlanSelection($0) }
        )
    }

    private var hasUnsavedPlanChanges: Bool {
        guard let activePlan = PlanTemplate.preMadePlans.first(where: { $0.name == activePlanName }) else {
            return false
        }

        guard planName == activePlan.name,
              Int(planLength) == activePlan.lengthInWeeks,
              let displayedWeight = numericValue(from: finalWeight),
              let selectedWeightUnit = weightUnits.first(where: { $0.shortName == weightUnit }) else {
            return true
        }

        guard let expectedWeightSI = targetWeightSI(for: activePlan) else {
            return true
        }

        let finalWeightSI = displayedWeight * selectedWeightUnit.siConversionValue
        return abs(finalWeightSI - expectedWeightSI) > Constants.weightComparisonToleranceSI
    }

    private func requestPlanSelection(_ selectedName: String) {
        guard selectedName != activePlanName else {
            return
        }

        guard hasUnsavedPlanChanges else {
            applyPlanTemplate(named: selectedName)
            return
        }

        pendingPlanName = selectedName
        isShowingUnsavedChangesWarning = true
    }

    private func applyPlanTemplate(named name: String) {
        guard let plan = PlanTemplate.preMadePlans.first(where: { $0.name == name }) else {
            return
        }

        selectedPlanName = plan.name
        activePlanName = plan.name
        planName = plan.name
        planLength = String(plan.lengthInWeeks)
        selectedPlanLength = Constants.planLengthOptions.first {
            $0.hasPrefix("\(plan.lengthInWeeks) ")
        }
        if let targetWeightSI = targetWeightSI(for: plan) {
            setFinalWeight(targetWeightSI, for: weightUnit)
        }
    }

    private func loadPlanData() {
        do {
            currentMeasurement = try PlanningService.shared.fetchMeasurements(amount: 1).first
        } catch {
            currentMeasurement = nil
        }

        loadWeightUnits()
    }

    private func loadWeightUnits() {
        guard let measurementUnitService = PlanningDependencyContext.measurementUnitService else {
            return
        }

        do {
            weightUnits = try measurementUnitService.fetchWeightMeasurementUnits()
            let preferredUnit = weightUnits.first(where: \.isDefault) ?? weightUnits.first
            weightUnit = preferredUnit?.shortName ?? ""
            if let activePlan = PlanTemplate.preMadePlans.first(where: { $0.name == activePlanName }),
               let targetWeightSI = targetWeightSI(for: activePlan) {
                setFinalWeight(targetWeightSI, for: weightUnit)
            }
        } catch {
            weightUnits = []
        }
    }

    private func updateFinalWeight(from previousUnit: String, to selectedUnit: String) {
        guard let selectedUnit = weightUnits.first(where: { $0.shortName == selectedUnit }),
              selectedUnit.siConversionValue > 0 else {
            return
        }

        let weightSI: Double
        if let previousUnit = weightUnits.first(where: { $0.shortName == previousUnit }),
           previousUnit.siConversionValue > 0,
           let currentWeight = numericValue(from: finalWeight) {
            weightSI = currentWeight * previousUnit.siConversionValue
        } else {
            guard let activePlan = PlanTemplate.preMadePlans.first(where: { $0.name == activePlanName }),
                  let targetWeightSI = targetWeightSI(for: activePlan) else {
                return
            }

            weightSI = targetWeightSI
        }

        setFinalWeight(weightSI, for: selectedUnit.shortName)
    }

    private func setFinalWeight(_ weightSI: Double, for unitShortName: String) {
        guard let unit = weightUnits.first(where: { $0.shortName == unitShortName }),
              unit.siConversionValue > 0 else {
            return
        }

        let convertedWeight = weightSI / unit.siConversionValue
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        finalWeight = formatter.string(from: NSNumber(value: convertedWeight)) ?? String(convertedWeight)
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

    private func numericValue(from input: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = .current
        return formatter.number(from: input)?.doubleValue ?? Double(input)
    }

    private func targetWeightSI(for plan: PlanTemplate) -> Double? {
        guard let currentMeasurement else {
            return nil
        }

        guard let targetBMI = plan.targetBMI else {
            return currentMeasurement.weightSI
        }

        guard let heightSI = currentMeasurement.heightSI else {
            return nil
        }

        return try? BMIWeightCalculationService.shared.calculateWeightSI(
            targetBMI: targetBMI,
            heightSI: heightSI
        )
    }
}

private enum Constants {
    static let title = "Select or build a plan"
    static let planSelectorLabel = "Select base plan"
    static let planNameLabel = "Name"
    static let planNamePlaceholder = "Plan name"
    static let finalWeightLabel = "Final weight"
    static let weightComparisonToleranceSI = 50.0
    static let planTimeLabel = "Plan time"
    static let weeksUnit = "weeks"
    static let planLengthRange = 1.0...520.0
    static let planLengthOptions = ["12 weeks", "24 weeks", "52 weeks"]
    static let defaultPlanLengthOption = "24 weeks"
    static let activatePlanButtonTitle = "ACTIVATE PLAN"
    static let unsavedChangesTitle = "Discard plan changes?"
    static let unsavedChangesMessage = "Changing the base plan will discard your changes."
    static let cancelButtonTitle = "Cancel"
    static let discardChangesButtonTitle = "Discard Changes"
    static let backgroundColor = "AppBackground"
}
