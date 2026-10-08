import XCTest
@testable import LabelMatch

final class AssessLabelForGoalUseCaseTests: XCTestCase {

    private var goalRepository: MockNutritionGoalRepository!
    private var checkRepository: MockLabelCheckRepository!
    private var widgetReloader: MockWidgetReloader!
    private var useCase: AssessLabelForGoalUseCase!

    override func setUp() {
        super.setUp()
        goalRepository = MockNutritionGoalRepository()
        checkRepository = MockLabelCheckRepository()
        widgetReloader = MockWidgetReloader()
        useCase = AssessLabelForGoalUseCase(goalRepository: goalRepository,
                                            checkRepository: checkRepository,
                                            widgetReloader: widgetReloader)
    }

    // Makes this goal the active goal.
    private func activate(_ goal: NutritionGoal) {
        goalRepository.goals = [goal]
        goalRepository.activeID = goal.id
    }

    func test_assessLabel_isSuitable_whenAllValuesAreWithinTheGoal() throws {
        activate(NutritionGoal(name: "Low sugar", sugarMaxPer100g: 10))

        let check = try useCase.execute(productName: "Yoghurt", values: TestData.values(sugars: 5))

        XCTAssertEqual(check.verdict, .suitable)
    }

    func test_assessLabel_isNotSuitable_whenSugarIsOverTheLimit() throws {
        activate(NutritionGoal(name: "Low sugar", sugarMaxPer100g: 10))

        let check = try useCase.execute(productName: "Cereal", values: TestData.values(sugars: 12))

        XCTAssertEqual(check.verdict, .notSuitable)
        XCTAssertEqual(check.reasons.first?.message, "Sugars 12 g per 100 g, your limit is 10 g.")
    }

    func test_assessLabel_isSuitableWithCaution_whenSugarEqualsTheLimit() throws {
        activate(NutritionGoal(name: "Low sugar", sugarMaxPer100g: 10))

        let check = try useCase.execute(productName: "Granola", values: TestData.values(sugars: 10))

        XCTAssertEqual(check.verdict, .caution)
    }

    func test_assessLabel_isNotSuitable_whenPeanutsAreDeclared() throws {
        activate(NutritionGoal(name: "Peanut free", avoidedAllergens: ["peanut"]))

        let check = try useCase.execute(productName: "Muesli bar",
                                        values: TestData.values(allergens: ["peanuts", "milk"]))

        XCTAssertEqual(check.verdict, .notSuitable)
        XCTAssertEqual(check.reasons.first?.nutrientName, "Allergen")
    }

    func test_assessLabel_isNotSuitable_whenProteinPerServeIsBelowTheTarget() throws {
        activate(NutritionGoal(name: "Build muscle", proteinMinPerServeGrams: 30))

        // 20 g per 100 g and a 40 g serve is only 8 g of protein.
        let check = try useCase.execute(productName: "Snack", values: TestData.values(protein: 20, serving: 40))

        XCTAssertEqual(check.verdict, .notSuitable)
    }

    func test_assessLabel_isSuitable_whenProteinPerServeEqualsTheTarget() throws {
        activate(NutritionGoal(name: "Build muscle", proteinMinPerServeGrams: 30))

        // 75 g per 100 g and a 40 g serve is exactly 30 g.
        let check = try useCase.execute(productName: "Protein bar", values: TestData.values(protein: 75, serving: 40))

        XCTAssertEqual(check.verdict, .suitable)
    }

    func test_assessLabel_fails_whenThereIsNoActiveGoal() {
        XCTAssertThrowsError(try useCase.execute(productName: "Yoghurt", values: TestData.values())) { error in
            XCTAssertEqual(error as? AssessLabelError, .noActiveGoal)
        }
    }

    func test_assessLabel_fails_whenTheServingSizeIsZero() {
        activate(NutritionGoal(name: "Low sugar", sugarMaxPer100g: 10))

        XCTAssertThrowsError(try useCase.execute(productName: "Yoghurt", values: TestData.values(serving: 0))) { error in
            XCTAssertEqual(error as? AssessLabelError, .invalidServingSize)
        }
    }

    func test_assessLabel_savesTheCheckAndReloadsTheWidgets() throws {
        activate(NutritionGoal(name: "Low sugar", sugarMaxPer100g: 10))

        _ = try useCase.execute(productName: "Yoghurt", values: TestData.values(sugars: 5))

        XCTAssertEqual(checkRepository.saved.count, 1)
        XCTAssertEqual(widgetReloader.reloadCount, 1)
    }

    func test_assessLabel_doesNotSaveOrReload_whenThereIsNoActiveGoal() {
        _ = try? useCase.execute(productName: "Yoghurt", values: TestData.values())

        XCTAssertTrue(checkRepository.saved.isEmpty)
        XCTAssertEqual(widgetReloader.reloadCount, 0)
    }
}
