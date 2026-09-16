import SwiftUI
import FitnessTrackerShared

public struct UserInputScreen: View {
    @State private var name = ""
    @State private var birthday: Date?
    @State private var shouldShowValidationErrors = false
    @State private var isDatePickerShowing = false
    @State private var isShowingMeasurementInput = false
    @FocusState private var isNameFieldFocused: Bool

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
                        focus: $isNameFieldFocused,
                        submitLabel: .next,
                        onSubmit: focusBirthdayInput
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingMeasurementInput) {
            MeasurementInputScreen()
        }
        .dismissesKeyboardOnDownwardSwipe()
        .onChange(of: isNameFieldFocused) { _, isFocused in
            if isFocused {
                isDatePickerShowing = false
            }
        }
        .onChange(of: isDatePickerShowing) { _, isShowing in
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

    private func focusBirthdayInput() {
        isNameFieldFocused = false
        isDatePickerShowing = true
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
    static let title = "Pls give us some personal data"
    static let privacyMessage = "Everything is stored only on your device"
    static let nameLabel = "Name"
    static let namePlaceholder = "Bob for example"
    static let birthdayLabel = "Date of birth"
    static let nextButtonTitle = "NEXT"
    static let backgroundColor = "AppBackground"
}
