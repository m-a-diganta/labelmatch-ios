import XCTest
@testable import LabelMatch

final class CompareLabelChecksUseCaseTests: XCTestCase {

    private let useCase = CompareLabelChecksUseCase()

    func test_compare_prefersTheSuitableProduct_overTheNotSuitableOne() throws {
        let goalID = UUID()
        let good = TestData.check(name: "Greek yoghurt", verdict: .suitable, goalID: goalID)
        let bad = TestData.check(name: "Flavoured yoghurt", verdict: .notSuitable, goalID: goalID)

        let result = try useCase.execute(checks: [bad, good])

        XCTAssertEqual(result.winner?.productName, "Greek yoghurt")
    }

    func test_compare_prefersFewerProblems_whenBothVerdictsAreTheSame() throws {
        let goalID = UUID()
        let fewer = TestData.check(name: "Plain oats", verdict: .caution, goalID: goalID,
                                   reasons: [TestData.reason(severity: .caution)])
        let more = TestData.check(name: "Sweet oats", verdict: .caution, goalID: goalID,
                                  reasons: [TestData.reason(severity: .caution),
                                            TestData.reason(severity: .caution)])

        let result = try useCase.execute(checks: [more, fewer])

        XCTAssertEqual(result.winner?.productName, "Plain oats")
    }

    func test_compare_hasNoWinner_whenBothProductsFitEquallyWell() throws {
        let goalID = UUID()
        let first = TestData.check(name: "Milk A", verdict: .suitable, goalID: goalID)
        let second = TestData.check(name: "Milk B", verdict: .suitable, goalID: goalID)

        let result = try useCase.execute(checks: [first, second])

        XCTAssertNil(result.winner)
    }

    func test_compare_showsPer100gNumbersForBothProducts() throws {
        let goalID = UUID()
        let first = TestData.check(name: "A", verdict: .suitable, goalID: goalID)
        let second = TestData.check(name: "B", verdict: .suitable, goalID: goalID)

        let result = try useCase.execute(checks: [first, second])

        XCTAssertEqual(result.lines.count, 5)
        XCTAssertEqual(result.lines.first?.nutrientName, "Energy")
    }

    func test_compare_fails_whenTheTwoChecksUsedDifferentGoals() {
        let first = TestData.check(name: "A", verdict: .suitable, goalID: UUID())
        let second = TestData.check(name: "B", verdict: .suitable, goalID: UUID())

        XCTAssertThrowsError(try useCase.execute(checks: [first, second])) { error in
            XCTAssertEqual(error as? CompareLabelChecksError, .differentGoals)
        }
    }

    func test_compare_fails_whenFewerThanTwoChecksAreGiven() {
        let only = TestData.check(name: "A", verdict: .suitable)

        XCTAssertThrowsError(try useCase.execute(checks: [only])) { error in
            XCTAssertEqual(error as? CompareLabelChecksError, .fewerThanTwoChecks)
        }
    }
    
    func test_compare_saysNeitherFits_whenBothProductsAreNotSuitable() throws {
        let goalID = UUID()
        let first = TestData.check(name: "Biscuit A", verdict: .notSuitable, goalID: goalID)
        let second = TestData.check(name: "Biscuit B", verdict: .notSuitable, goalID: goalID)

        let result = try useCase.execute(checks: [first, second])

        XCTAssertNil(result.winner)
        XCTAssertEqual(result.explanation, "Neither product fits your goal. Both go over your limits equally.")
    }

    func test_compare_namesTheCloserProduct_whenBothAreNotSuitable() throws {
        let goalID = UUID()
        let closer = TestData.check(name: "Biscuit A", verdict: .notSuitable, goalID: goalID,
                                    reasons: [TestData.reason(severity: .notSuitable)])
        let further = TestData.check(name: "Biscuit B", verdict: .notSuitable, goalID: goalID,
                                     reasons: [TestData.reason(severity: .notSuitable),
                                               TestData.reason(severity: .notSuitable)])

        let result = try useCase.execute(checks: [further, closer])

        XCTAssertEqual(result.winner?.productName, "Biscuit A")
        XCTAssertTrue(result.explanation.hasPrefix("Neither product fits your goal"))
    }
}
