import Foundation

/// Saves a goal and makes it the one goal that is active.
/// The widgets are refreshed so they show the new goal.
struct SetNutritionGoalUseCase {
    let goalRepository: NutritionGoalRepository
    let widgetReloader: WidgetReloading

    func execute(_ goal: NutritionGoal) throws -> NutritionGoal {
        // Rule: a goal needs at least one target or limit.
        guard goal.hasAnyTarget else {
            throw SetNutritionGoalError.noTargetsSet
        }

        // Rule: every number must be in a believable range.
        try checkRange(goal.proteinMinPerServeGrams, for: .protein)
        try checkRange(goal.energyMaxPerServeKilojoules, for: .energy)
        try checkRange(goal.sugarMaxPer100g, for: .sugars)
        try checkRange(goal.saturatedFatMaxPer100g, for: .saturatedFat)
        try checkRange(goal.sodiumMaxPer100gMilligrams, for: .sodium)

        // Rule: only one goal is active at a time.
        var savedGoal = goal
        savedGoal.isActive = true
        try goalRepository.save(savedGoal)
        try goalRepository.setActiveGoal(id: savedGoal.id)

        widgetReloader.reloadWidgets()
        return savedGoal
    }

    private func checkRange(_ value: Double?, for nutrient: Nutrient) throws {
        guard let value = value else { return }
        if !nutrient.targetRange.contains(value) {
            throw SetNutritionGoalError.implausibleTarget(nutrient: nutrient)
        }
    }
}
