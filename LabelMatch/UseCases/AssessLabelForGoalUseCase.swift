import Foundation

/// Judges a label against the active goal, saves the check
/// and asks the widgets to refresh.
struct AssessLabelForGoalUseCase {
    let goalRepository: NutritionGoalRepository
    let checkRepository: LabelCheckRepository
    let widgetReloader: WidgetReloading
    var now: () -> Date = { Date() }

    func execute(productName: String,
                 values: NutritionPanelValues,
                 sourceImageFilename: String? = nil) throws -> LabelCheck {
        guard let goal = try goalRepository.activeGoal() else {
            throw AssessLabelError.noActiveGoal
        }
        guard values.servingSizeGrams > 0 else {
            throw AssessLabelError.invalidServingSize
        }

        let reasons = AssessLabelForGoalUseCase.reasons(for: values, goal: goal)
        let verdict = AssessLabelForGoalUseCase.overallVerdict(of: reasons)

        let check = LabelCheck(
            id: UUID(),
            goalID: goal.id,
            goalNameAtCheck: goal.name,
            productName: productName,
            checkedAt: now(),
            values: values,
            verdict: verdict,
            reasons: reasons,
            sourceImageFilename: sourceImageFilename
        )

        try checkRepository.save(check)
        widgetReloader.reloadWidgets()
        return check
    }

    // MARK: Rules

    static func reasons(for values: NutritionPanelValues, goal: NutritionGoal) -> [VerdictReason] {
        var reasons: [VerdictReason] = []

        // Rule: a declared allergen the shopper avoids is always Not suitable.
        for avoided in goal.avoidedAllergens where !avoided.trimmingCharacters(in: .whitespaces).isEmpty {
            let declared = values.declaredAllergens.contains { stem($0).contains(stem(avoided)) }
            if declared {
                reasons.append(VerdictReason(
                    nutrientName: "Allergen",
                    comparedValue: 0,
                    limit: 0,
                    message: "This label declares \(avoided), which you avoid.",
                    severity: .notSuitable))
            }
        }

        if let limit = goal.sugarMaxPer100g {
            reasons.append(upperLimitReason(.sugars, value: values.sugarsGramsPer100g,
                                            limit: limit, basis: "per 100 g"))
        }
        if let limit = goal.saturatedFatMaxPer100g {
            reasons.append(upperLimitReason(.saturatedFat, value: values.saturatedFatGramsPer100g,
                                            limit: limit, basis: "per 100 g"))
        }
        if let limit = goal.sodiumMaxPer100gMilligrams {
            reasons.append(upperLimitReason(.sodium, value: values.sodiumMilligramsPer100g,
                                            limit: limit, basis: "per 100 g"))
        }
        if let limit = goal.energyMaxPerServeKilojoules {
            reasons.append(upperLimitReason(.energy, value: values.energyKilojoulesPerServe,
                                            limit: limit, basis: "per serve"))
        }
        if let minimum = goal.proteinMinPerServeGrams {
            reasons.append(lowerLimitReason(.protein, value: values.proteinGramsPerServe,
                                            minimum: minimum, basis: "per serve"))
        }
        return reasons
    }

    static func overallVerdict(of reasons: [VerdictReason]) -> Verdict {
        if reasons.contains(where: { $0.severity == .notSuitable }) {
            return .notSuitable
        }
        if reasons.contains(where: { $0.severity == .caution }) {
            return .caution
        }
        return .suitable
    }

    // Over the limit is Not suitable.
    // Equal to the limit, or within 10% below it, is Suitable with caution.
    private static func upperLimitReason(_ nutrient: Nutrient, value: Double,
                                         limit: Double, basis: String) -> VerdictReason {
        let severity: Verdict
        if value > limit {
            severity = .notSuitable
        } else if value > limit * 0.9 {
            severity = .caution
        } else {
            severity = .suitable
        }
        let message = "\(nutrient.displayName) \(format(value)) \(nutrient.unit) \(basis), your limit is \(format(limit)) \(nutrient.unit)."
        return VerdictReason(nutrientName: nutrient.displayName, comparedValue: value,
                             limit: limit, message: message, severity: severity)
    }

    // At or above the target is Suitable.
    // Within 10% below the target is Suitable with caution.
    private static func lowerLimitReason(_ nutrient: Nutrient, value: Double,
                                         minimum: Double, basis: String) -> VerdictReason {
        let severity: Verdict
        if value >= minimum {
            severity = .suitable
        } else if value >= minimum * 0.9 {
            severity = .caution
        } else {
            severity = .notSuitable
        }
        let message = "\(nutrient.displayName) \(format(value)) \(nutrient.unit) \(basis), your target is at least \(format(minimum)) \(nutrient.unit)."
        return VerdictReason(nutrientName: nutrient.displayName, comparedValue: value,
                             limit: minimum, message: message, severity: severity)
    }

    // "peanuts" and "peanut" count as the same allergen.
    private static func stem(_ word: String) -> String {
        let lower = word.lowercased().trimmingCharacters(in: .whitespaces)
        return lower.hasSuffix("s") ? String(lower.dropLast()) : lower
    }

    private static func format(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
