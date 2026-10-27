import SwiftUI

public struct PlanScreen: View {
    public init() {}

    public var body: some View {
        Text("Plan")
            .font(.system(size: 28, weight: .black))
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .padding(20)
    }
}
