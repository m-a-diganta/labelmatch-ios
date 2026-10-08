import XCTest
@testable import LabelMatch

final class SetNutritionGoalUseCaseTests: XCTestCase {

    private var goalRepository: MockNutritionGoalRepository!
    private var widgetReloader: MockWidgetReloader!
    private var useCase: SetNutritionGoalUseCase!

    override func setUp() {
        super.setUp()
        goalRepository = MockNutritionGoalRepository()
        widgetReloader = MockWidgetReloader()
        useCase = SetNutritionGoalUseCase(goalRepository: goalRepository,
                                          widgetReloader: widgetReloader)
    }

    func test_setGoal_savesAndActivatesTheGoal_whenProteinTargetIsValid() throws {
        let goal = NutritionGoal(name: "Build muscle", proteinMinPerServeGrams: 30)

        let saved = try useCase.execute(goal)

        XCTAssertTrue(saved.isActive)
        XCTAssertEqual(goalRepository.goals.count, 1)
        XCTAssertEqual(goalRepository.activeID, goal.id)
    }

    func test_setGoal_reloadsTheWidgets_whenTheGoalIsSaved() throws {
        _ = try useCase.execute(NutritionGoal(name: "Build muscle", proteinMinPerServeGrams: 30))

        XCTAssertEqual(widgetReloader.reloadCount, 1)
    }

    func test_setGoal_fails_whenNoTargetsAreSet() {
        let goal = NutritionGoal(name: "Empty goal")

        XCTAssertThrowsError(try useCase.execute(goal)) { error in
            XCTAssertEqual(error as? SetNutritionGoalError, .noTargetsSet)
        }
        XCTAssertTrue(goalRepository.goals.isEmpty)
    }

    func test_setGoal_doesNotReloadTheWidgets_whenTheGoalIsRejected() {
        _ = try? useCase.execute(NutritionGoal(name: "Empty goal"))

        XCTAssertEqual(widgetReloader.reloadCount, 0)
    }

    func test_setGoal_acceptsAnAllergenOnlyGoal() throws {
        let goal = NutritionGoal(name: "Peanut free", avoidedAllergens: ["peanut"])

        let saved = try useCase.execute(goal)

        XCTAssertTrue(saved.isActive)
    }

    func test_setGoal_fails_whenSugarLimitIsAbove100GramsPer100g() {
        let goal = NutritionGoal(name: "Too high", sugarMaxPer100g: 150)

        XCTAssertThrowsError(try useCase.execute(goal)) { error in
            XCTAssertEqual(error as? SetNutritionGoalError, .implausibleTarget(nutrient: .sugars))
        }
    }

    func test_setGoal_accepts_aSugarLimitOfExactly100GramsPer100g() throws {
        let goal = NutritionGoal(name: "Edge", sugarMaxPer100g: 100)

        XCTAssertNoThrow(try useCase.execute(goal))
    }
}
