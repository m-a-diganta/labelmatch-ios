import Foundation

struct ComparisonLine: Equatable {
    let nutrientName: String
    let unit: String
    let firstValue: Double
    let secondValue: Double
}

struct ComparisonResult: Equatable {
    /// nil means both products are equally good for the goal.
    let winner: LabelCheck?
    let explanation: String
    let lines: [ComparisonLine]
}

/// Compares two label checks that were made against the same goal.
struct CompareLabelChecksUseCase {

    func execute(checks: [LabelCheck]) throws -> ComparisonResult {
        guard checks.count >= 2 else {
            throw CompareLabelChecksError.fewerThanTwoChecks
        }
        let first = checks[0]
        let second = checks[1]

        // Rule: both checks must use the same goal.
        guard first.goalID == second.goalID else {
            throw CompareLabelChecksError.differentGoals
        }

        let lines = per100gLines(first: first, second: second)

        // A better verdict wins.
        if first.verdict.rank != second.verdict.rank {
            let firstWins = first.verdict.rank > second.verdict.rank
            let winner = firstWins ? first : second
            let loser = firstWins ? second : first
            let text = "\(winner.productName) fits your goal better. It is \(winner.verdict.title.lowercased()) and \(loser.productName) is \(loser.verdict.title.lowercased())."
            return ComparisonResult(winner: winner, explanation: text, lines: lines)
        }

        // Same verdict, so the one with fewer problems wins.
        let firstProblems = problemCount(first)
        let secondProblems = problemCount(second)
        if firstProblems != secondProblems {
            let firstWins = firstProblems < secondProblems
            let winner = firstWins ? first : second
            let text = "\(winner.productName) fits your goal slightly better. It has fewer numbers close to or over your limits."
            return ComparisonResult(winner: winner, explanation: text, lines: lines)
        }

        return ComparisonResult(winner: nil,
                                explanation: "Both products fit your goal equally well.",
                                lines: lines)
    }

    private func problemCount(_ check: LabelCheck) -> Int {
        return check.reasons.filter { $0.severity != .suitable }.count
    }

    // Rule: numbers are compared per 100 g, so serving sizes cannot mislead.
    private func per100gLines(first: LabelCheck, second: LabelCheck) -> [ComparisonLine] {
        return [
            ComparisonLine(nutrientName: "Energy", unit: "kJ",
                           firstValue: first.values.energyKilojoulesPer100g,
                           secondValue: second.values.energyKilojoulesPer100g),
            ComparisonLine(nutrientName: "Protein", unit: "g",
                           firstValue: first.values.proteinGramsPer100g,
                           secondValue: second.values.proteinGramsPer100g),
            ComparisonLine(nutrientName: "Sugars", unit: "g",
                           firstValue: first.values.sugarsGramsPer100g,
                           secondValue: second.values.sugarsGramsPer100g),
            ComparisonLine(nutrientName: "Saturated fat", unit: "g",
                           firstValue: first.values.saturatedFatGramsPer100g,
                           secondValue: second.values.saturatedFatGramsPer100g),
            ComparisonLine(nutrientName: "Sodium", unit: "mg",
                           firstValue: first.values.sodiumMilligramsPer100g,
                           secondValue: second.values.sodiumMilligramsPer100g)
        ]
    }
}
