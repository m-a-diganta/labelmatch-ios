import XCTest
@testable import LabelMatch

final class ReadNutritionPanelUseCaseTests: XCTestCase {

    private var reader: MockNutritionPanelReader!
    private var useCase: ReadNutritionPanelUseCase!

    override func setUp() {
        super.setUp()
        reader = MockNutritionPanelReader()
        useCase = ReadNutritionPanelUseCase(reader: reader)
    }

    func test_readPanel_returnsValuesPer100g_whenThePanelIsComplete() throws {
        reader.lines = TestData.completePanelLines

        let values = try useCase.execute(imageData: Data())

        XCTAssertEqual(values.energyKilojoulesPer100g, 1350)
        XCTAssertEqual(values.proteinGramsPer100g, 20)
        XCTAssertEqual(values.sugarsGramsPer100g, 5)
        XCTAssertEqual(values.saturatedFatGramsPer100g, 2.5)
        XCTAssertEqual(values.sodiumMilligramsPer100g, 100)
        XCTAssertEqual(values.servingSizeGrams, 40)
        XCTAssertEqual(values.declaredAllergens, ["peanuts", "milk"])
    }

    func test_readPanel_fails_whenNoTextIsFound() {
        reader.lines = ["   ", ""]

        XCTAssertThrowsError(try useCase.execute(imageData: Data())) { error in
            XCTAssertEqual(error as? ReadNutritionPanelError, .noTextFound)
        }
    }

    func test_readPanel_fails_whenTheTextIsNotANutritionPanel() {
        reader.lines = ["Fresh apple puree", "Best before 12 Dec"]

        XCTAssertThrowsError(try useCase.execute(imageData: Data())) { error in
            XCTAssertEqual(error as? ReadNutritionPanelError, .panelNotRecognised)
        }
    }

    func test_readPanel_fails_whenSodiumIsMissing() {
        reader.lines = TestData.completePanelLines.filter { !$0.hasPrefix("Sodium") }

        XCTAssertThrowsError(try useCase.execute(imageData: Data())) { error in
            XCTAssertEqual(error as? ReadNutritionPanelError, .requiredValueMissing(valueName: "sodium"))
        }
    }

    func test_readPanel_fails_whenTheServingSizeIsMissing() {
        reader.lines = TestData.completePanelLines.filter { !$0.hasPrefix("Serving size") }

        XCTAssertThrowsError(try useCase.execute(imageData: Data())) { error in
            XCTAssertEqual(error as? ReadNutritionPanelError, .requiredValueMissing(valueName: "serving size"))
        }
    }
}
