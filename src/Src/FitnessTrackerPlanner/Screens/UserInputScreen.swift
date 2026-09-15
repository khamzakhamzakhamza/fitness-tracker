import SwiftUI
import FitnessTrackerShared

public struct UserInputScreen: View {
    @State private var name = ""
    @State private var birthday = Date()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            InputTextRow(text: $name, label: "Name")
            InputDateRow(date: $birthday, label: "Date of birth")
        }
        .padding()
    }
}
