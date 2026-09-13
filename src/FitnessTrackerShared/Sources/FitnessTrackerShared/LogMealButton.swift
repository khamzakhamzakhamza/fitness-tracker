import SwiftUI

public struct LogMealButton: View {
    public let action: () -> Void

    public init(action: @escaping () -> Void) { self.action = action }

    public var body: some View {
        PrimaryActionButton(title: "LOG MEAL", action: action)
    }
}

#Preview {
    LogMealButton(action: {})
        .background(Color("AppBackground"))
}
