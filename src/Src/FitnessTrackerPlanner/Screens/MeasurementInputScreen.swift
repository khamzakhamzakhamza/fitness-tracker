import SwiftUI
import FitnessTrackerShared

public struct MeasurementInputScreen: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Constants.title)
                    .font(.system(size: 28, weight: .black))

                InfoLabel(text: Constants.infoMessage)
            }
            .padding(20)
            .padding(.top, 15)

            Spacer()

            PrimaryActionButton(title: Constants.nextButtonTitle) {}
        }
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

private enum Constants {
    static let title = "Pls set your measurments"
    static let infoMessage = "Your calorie intake will be adjusted as you log more measurements in the app."
    static let nextButtonTitle = "NEXT"
    static let backgroundColor = "AppBackground"
}
