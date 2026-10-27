import SwiftUI
import FitnessTrackerShared

public struct PlanCreationScreen: View {
    @State private var selectedPlanName = PlanDefinition.maintenance24Weeks.name
    @State private var activePlanName = PlanDefinition.maintenance24Weeks.name
    @State private var activePlanID = PlanDefinition.maintenance24Weeks.id
    @State private var planName = PlanDefinition.maintenance24Weeks.name
    @State private var activeCustomPlanName = PlanDefinition.maintenance24Weeks.name
    @State private var currentMeasurement: UserMeasurement?
    @State private var planMilestones: [PlanMilestoneValue] = []
    @State private var selectedPlanLength: String? = Constants.defaultPlanLengthOption
    @State private var pendingPlanName: String?
    @State private var isShowingUnsavedChangesWarning = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Constants.title)
                    .font(.system(size: 28, weight: .black))

                InputDropdownRow(
                    selection: planSelection,
                    label: Constants.planSelectorLabel,
                    options: availablePlanNames
                )

                Divider()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .padding(.top, 15)

            VStack(alignment: .leading, spacing: 18) {
                InputTextRow(
                    text: $planName,
                    label: Constants.planNameLabel,
                    placeholder: Constants.planNamePlaceholder
                )

                VStack(alignment: .leading, spacing: 7) {
                    Text(Constants.planTimeLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(Constants.secondaryTextColor))

                    InlineOptionButtons(
                        options: planLengthOptions,
                        selection: $selectedPlanLength
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            if let currentMeasurement {
                PlanComponent(
                    title: planName,
                    numberOfWeeks: selectedPlanDefinition.lengthInWeeks,
                    latestMeasurement: currentMeasurement,
                    planDefinition: selectedPlanDefinition,
                    onDragEnded: { milestones in
                        planMilestones = milestones
                    }
                )
                .frame(maxHeight: .infinity)
                .id(selectedPlanDefinition.id)
            }

            PrimaryActionButton(
                title: Constants.createPlanButtonTitle,
                action: createPlan
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
        .dismissesKeyboardOnDownwardSwipe()
        .navigationBarBackButtonHidden(true)
        .task {
            loadPlanData()
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

                applyPlanDefinition(named: pendingPlanName)
                self.pendingPlanName = nil
            }
        } message: {
            Text(Constants.unsavedChangesMessage)
        }
    }

    private var availablePlans: [PlanDefinition] {
        PlanDefinition.maintenancePlans
            + PlanDefinition.bulkingPlans
            + PlanDefinition.weightLossPlans
    }

    private var availablePlanNames: [String] {
        availablePlans.reduce(into: []) { names, plan in
            guard !names.contains(plan.name) else {
                return
            }

            names.append(plan.name)
        }
    }

    private var planLengthOptions: [String] {
        availablePlans
            .filter { $0.name == selectedPlanName }
            .map { "\($0.lengthInWeeks) weeks" }
    }

    private var selectedPlanDefinition: PlanDefinition {
        let selectedLength = selectedPlanLength.flatMap {
            Int($0.components(separatedBy: " ").first ?? "")
        }

        return availablePlans.first {
            $0.name == selectedPlanName
                && $0.lengthInWeeks == selectedLength
        } ?? availablePlans.first {
            $0.name == selectedPlanName
        } ?? .maintenance24Weeks
    }

    private var planSelection: Binding<String> {
        Binding(
            get: { selectedPlanName },
            set: { requestPlanSelection($0) }
        )
    }

    private var hasUnsavedPlanChanges: Bool {
        planName != activeCustomPlanName
            || selectedPlanDefinition.id != activePlanID
    }

    private func requestPlanSelection(_ selectedName: String) {
        guard selectedName != activePlanName else {
            return
        }

        guard hasUnsavedPlanChanges else {
            applyPlanDefinition(named: selectedName)
            return
        }

        pendingPlanName = selectedName
        isShowingUnsavedChangesWarning = true
    }

    private func applyPlanDefinition(named name: String) {
        guard let plan = availablePlans.first(where: { $0.name == name }) else {
            return
        }

        selectedPlanName = plan.name
        activePlanName = plan.name
        activePlanID = plan.id
        planName = activeCustomPlanName
        selectedPlanLength = "\(plan.lengthInWeeks) weeks"
    }

    private func loadPlanData() {
        do {
            if let userName = try PlanningService.shared.fetchUser()?.name?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !userName.isEmpty {
                let firstPlanName = "\(userName)'s first plan"
                planName = firstPlanName
                activeCustomPlanName = firstPlanName
            }

            currentMeasurement = try PlanningService.shared.fetchMeasurements(amount: 1).first
        } catch {
            currentMeasurement = nil
        }
    }

    private func createPlan() {
        let trimmedPlanName = planName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedPlanName.isEmpty,
              !planMilestones.isEmpty else {
            return
        }

        PlanningService.shared.createPlan(
            PlanCreationRequest(
                name: trimmedPlanName,
                milestones: planMilestones
            )
        )
    }
}

private enum Constants {
    static let title = "Select or build a plan"
    static let planSelectorLabel = "Select base plan"
    static let planNameLabel = "Name"
    static let planNamePlaceholder = "Plan name"
    static let planTimeLabel = "Plan time"
    static let defaultPlanLengthOption = "24 weeks"
    static let createPlanButtonTitle = "CREATE PLAN"
    static let unsavedChangesTitle = "Discard plan changes?"
    static let unsavedChangesMessage = "Changing the base plan will discard your changes."
    static let cancelButtonTitle = "Cancel"
    static let discardChangesButtonTitle = "Discard Changes"
    static let backgroundColor = "AppBackground"
    static let secondaryTextColor = "SearchBoxSecondary"
}
