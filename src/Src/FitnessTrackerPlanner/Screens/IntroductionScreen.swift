import SwiftUI
import FitnessTrackerShared

public struct IntroductionScreen: View {
    private let welcomeMessageLabel = "Hi!\n\nThanks for downloading FitnessTracker!\n\nThe goal here is to help you keep track of your nutrition and exercise in one place, as efficiently as possible.\n\nThe app is open source, free, works offline, and does not store any data.\n\nEnjoy!"
    
    private let btnLabel = "LET'S START"
    @State private var isShowingUserInput = false
    
    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MessageBox(text: welcomeMessageLabel)
                    .brightness(-0.08)
                    .padding()

                Spacer()

                PrimaryActionButton(title: btnLabel) {
                    isShowingUserInput = true
                }
            }
            .navigationDestination(isPresented: $isShowingUserInput) {
                UserInputScreen()
            }
        }
    }
}
