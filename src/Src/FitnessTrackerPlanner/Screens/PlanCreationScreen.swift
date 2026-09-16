import SwiftUI

public struct PlanCreationScreen: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading) {
            Text(Constants.title)
                .font(.system(size: 28, weight: .black))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .padding(.top, 15)
        .background(Color(Constants.backgroundColor).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

private enum Constants {
    static let title = "Select or build a plan"
    static let backgroundColor = "AppBackground"
}
