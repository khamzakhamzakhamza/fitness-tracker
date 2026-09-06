import XCTest

final class fitness_trackerUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testNutritionListLoadsNextDatabaseBatchWhileScrolling() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Log meal"].tap()

        let searchField = app.textFields["Search foods"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("chicken")

        let totalMatchCount = app.staticTexts["7787 MATCHES"]
        XCTAssertTrue(totalMatchCount.waitForExistence(timeout: 5))

        let list = app.scrollViews["food-list-scroll-view"]
        XCTAssertTrue(list.exists)

        let firstFoodInSecondBatch = app.staticTexts["Chicken tikka chunks"]
        var swipeCount = 0

        while !firstFoodInSecondBatch.exists && swipeCount < 100 {
            list.swipeUp(velocity: .fast)
            swipeCount += 1
        }

        XCTAssertTrue(firstFoodInSecondBatch.waitForExistence(timeout: 5))
        XCTAssertTrue(totalMatchCount.exists)
    }

    @MainActor
    func testNutritionSearchShowsExactMatchCount() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Log meal"].tap()

        let searchField = app.textFields["Search foods"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("yorkshire pudding")

        XCTAssertTrue(
            app.staticTexts["55 MATCHES"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["Yorkshire pudding"].exists)
    }

    @MainActor
    func testSelectingFoodOpensAddFoodScreen() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Log meal"].tap()

        let searchField = app.textFields["Search foods"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("yorkshire pudding")

        let food = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Yorkshire pudding'")
        ).firstMatch
        XCTAssertTrue(food.waitForExistence(timeout: 5))
        food.tap()

        XCTAssertTrue(
            app.buttons["Add to today"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["131 kcal"].exists)
        XCTAssertTrue(app.staticTexts["4.2 g"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
