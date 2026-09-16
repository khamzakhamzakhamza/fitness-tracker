import SwiftUI
import UIKit

public extension View {
    func dismissesKeyboardOnDownwardSwipe() -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: Constants.minimumSwipeDistance)
                .onChanged { value in
                    guard isDownwardSwipe(value.translation) else {
                        return
                    }

                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
        )
    }

    private func isDownwardSwipe(_ translation: CGSize) -> Bool {
        translation.height > Constants.minimumSwipeDistance
            && abs(translation.height) > abs(translation.width)
    }
}

private enum Constants {
    static let minimumSwipeDistance = 10.0
}
