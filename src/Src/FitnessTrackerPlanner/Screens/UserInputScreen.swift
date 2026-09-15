import SwiftUI
import FitnessTrackerShared

public struct UserInputScreen: View {
    @State private var name = ""
    @State private var birthday: Date?
    @State private var shouldShowValidationErrors = false
    @State private var isDatePickerShowing = false
    @State private var isShowingMeasurementInput = false
    @FocusState private var isNameFieldFocused: Bool

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Constants.title)
                    .font(.system(size: 28, weight: .black))

                InfoLabel(text: Constants.privacyMessage)

                VStack(spacing: 16) {
                    InputTextRow(
                        text: $name,
                        label: Constants.nameLabel,
                        placeholder: Constants.namePlaceholder,
                        showValidationError: shouldShowValidationErrors && !isNameValid,
                        focus: $isNameFieldFocused
                    )
                    InputDateRow(
                        date: $birthday,
                        label: Constants.birthdayLabel,
                        showValidationError: shouldShowValidationErrors && !isBirthdayValid,
                        isPickerShowing: $isDatePickerShowing
                    )
                }
                .padding(.top, 12)
            }
            .padding(20)
            .padding(.top, 15)

            Spacer()

            PrimaryActionButton(title: Constants.nextButtonTitle) {
                createUser()
            }
        }
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingMeasurementInput) {
            MeasurementInputScreen()
        }
        .onChange(of: isNameFieldFocused) { isFocused in
            if isFocused {
                isDatePickerShowing = false
            }
        }
        .onChange(of: isDatePickerShowing) { isShowing in
            if isShowing {
                isNameFieldFocused = false
            }
        }
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isBirthdayValid: Bool {
        birthday != nil
    }

    private func createUser() {
        shouldShowValidationErrors = true

        guard isNameValid, let birthday else {
            return
        }

        isShowingMeasurementInput = PlanningService.shared.createUser(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            birthday: birthday
        )
    }
}

private enum Constants {
    static let title = "Pls set your user data"
    static let privacyMessage = "Your data is stored on device only"
    static let nameLabel = "Name"
    static let namePlaceholder = "Bob for example"
    static let birthdayLabel = "Date of birth"
    static let nextButtonTitle = "NEXT"
    static let backgroundColor = "AppBackground"
}
