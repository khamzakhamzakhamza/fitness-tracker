import Testing
import Foundation
@testable import fitness_tracker

struct FoodItemImageTests {

    @Test func foodImageLoadsWithInternetAndValidURL() {
        let imageURL = URL(string: "https://example.com/food.jpg")

        #expect(
            FoodItemImage.shouldLoadImage(
                imageURL: imageURL,
                isInternetAvailable: true
            )
        )
    }

    @Test func foodImageDoesNotLoadWithoutInternet() {
        let imageURL = URL(string: "https://example.com/food.jpg")

        #expect(
            !FoodItemImage.shouldLoadImage(
                imageURL: imageURL,
                isInternetAvailable: false
            )
        )
    }

    @Test func foodImageDoesNotLoadWithoutURL() {
        #expect(
            !FoodItemImage.shouldLoadImage(
                imageURL: nil,
                isInternetAvailable: true
            )
        )
    }
}
