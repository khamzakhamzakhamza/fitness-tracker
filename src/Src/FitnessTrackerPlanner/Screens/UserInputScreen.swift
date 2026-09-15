import SwiftUI
import FitnessTrackerShared

public struct UserInputScreen: View {
    @State private var name = ""
    @State private var birthday: Date?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Constants.title)
                    .font(.system(size: 28, weight: .black))

                Label(Constants.privacyMessage, systemImage: Constants.infoIcon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(Constants.secondaryTextColor))

                VStack(spacing: 16) {
                    InputTextRow(
                        text: $name,
                        label: Constants.nameLabel,
                        placeholder: Constants.namePlaceholder
                    )
                    InputDateRow(date: $birthday, label: Constants.birthdayLabel)
                }
                .padding(.top, 12)
            }
            .padding(20)

            Spacer()

            PrimaryActionButton(title: Constants.nextButtonTitle) {}
        }
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
    }
}

private enum Constants {
    static let title = "Pls set your user data"
    static let privacyMessage = "Your data is stored on device only"
    static let infoIcon = "info.circle"
    static let nameLabel = "Name"
    static let namePlaceholder = "Bob for example"
    static let birthdayLabel = "Date of birth"
    static let nextButtonTitle = "NEXT"
    static let secondaryTextColor = "SearchBoxSecondary"
    static let backgroundColor = "AppBackground"
}
