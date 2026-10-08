import Foundation
@testable import LabelMatch

// Simple stand-ins for the real repositories.
// No test touches Core Data, Vision or WidgetKit.

final class MockNutritionGoalRepository: NutritionGoalRepository {
    var goals: [NutritionGoal] = []
    var activeID: UUID?

    func allGoals() throws -> [NutritionGoal] {
        return goals
    }

    func activeGoal() throws -> NutritionGoal? {
        return goals.first { $0.id == activeID }
    }

    func save(_ goal: NutritionGoal) throws {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        } else {
            goals.append(goal)
        }
    }

    func setActiveGoal(id: UUID) throws {
        activeID = id
    }

    func deleteGoal(id: UUID) throws {
        goals.removeAll { $0.id == id }
    }
}

final class MockLabelCheckRepository: LabelCheckRepository {
    var saved: [LabelCheck] = []

    func save(_ check: LabelCheck) throws {
        saved.append(check)
    }

    func allChecks() throws -> [LabelCheck] {
        return saved
    }

    func checks(since date: Date) throws -> [LabelCheck] {
        return saved.filter { $0.checkedAt >= date }
    }

    func notSuitableChecksForActiveGoal(since date: Date) throws -> [LabelCheck] {
        return saved.filter { $0.checkedAt >= date && $0.verdict == .notSuitable }
    }

    func tally(since date: Date) throws -> VerdictTally {
        var tally = VerdictTally()
        for check in saved where check.checkedAt >= date {
            switch check.verdict {
            case .suitable: tally.suitable += 1
            case .caution: tally.caution += 1
            case .notSuitable: tally.notSuitable += 1
            }
        }
        return tally
    }
}

final class MockNutritionPanelReader: NutritionPanelReader {
    var lines: [String] = []

    func recognisedLines(in imageData: Data) throws -> [String] {
        return lines
    }
}

final class MockWidgetReloader: WidgetReloading {
    private(set) var reloadCount = 0

    func reloadWidgets() {
        reloadCount += 1
    }
}

// Ready-made test data.
enum TestData {

    static func values(energy: Double = 800,
                       protein: Double = 20,
                       sugars: Double = 5,
                       saturatedFat: Double = 2,
                       sodium: Double = 100,
                       serving: Double = 40,
                       allergens: [String] = []) -> NutritionPanelValues {
        return NutritionPanelValues(
            energyKilojoulesPer100g: energy,
            proteinGramsPer100g: protein,
            sugarsGramsPer100g: sugars,
            saturatedFatGramsPer100g: saturatedFat,
            sodiumMilligramsPer100g: sodium,
            servingSizeGrams: serving,
            declaredAllergens: allergens
        )
    }

    static let completePanelLines = [
        "Nutrition Information",
        "Serving size: 40 g",
        "Energy 540 kJ 1350 kJ",
        "Protein 8.0 g 20.0 g",
        "Fat, total 5.0 g 12.5 g",
        "- saturated 1.0 g 2.5 g",
        "Carbohydrate 20 g 50 g",
        "- sugars 2.0 g 5.0 g",
        "Sodium 40 mg 100 mg",
        "Contains: peanuts, milk"
    ]

    static func check(name: String,
                      verdict: Verdict,
                      goalID: UUID = UUID(),
                      reasons: [VerdictReason] = []) -> LabelCheck {
        return LabelCheck(
            id: UUID(),
            goalID: goalID,
            goalNameAtCheck: "Build muscle",
            productName: name,
            checkedAt: Date(),
            values: values(),
            verdict: verdict,
            reasons: reasons,
            sourceImageFilename: nil
        )
    }

    static func reason(severity: Verdict) -> VerdictReason {
        return VerdictReason(nutrientName: "Sugars", comparedValue: 5, limit: 10,
                             message: "Sugars 5 g per 100 g, your limit is 10 g.",
                             severity: severity)
    }
}
