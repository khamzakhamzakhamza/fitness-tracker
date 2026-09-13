import CoreGraphics
import Testing
@testable import FitnessTrackerShared

struct SearchBoxTests {

    @Test func dismissesKeyboardForDownwardVerticalSwipe() {
        #expect(
            SearchBox.shouldDismissKeyboard(
                for: CGSize(width: 8, height: 24)
            )
        )
    }

    @Test func keepsKeyboardOpenForHorizontalOrUpwardSwipe() {
        #expect(
            !SearchBox.shouldDismissKeyboard(
                for: CGSize(width: 24, height: 8)
            )
        )
        #expect(
            !SearchBox.shouldDismissKeyboard(
                for: CGSize(width: 0, height: -24)
            )
        )
    }
}
