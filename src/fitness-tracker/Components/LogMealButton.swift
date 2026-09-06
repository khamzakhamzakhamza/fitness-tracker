import SwiftUI

struct LogMealButton: View {
    let action: () -> Void

    var body: some View {
        PrimaryActionButton(title: "LOG MEAL", action: action)
    }
}

#Preview {
    LogMealButton(action: {})
        .background(Color("AppBackground"))
}
