import Foundation
import Combine

/// State for the Goals screen.
/// The number fields hold text so the shopper can type freely.
final class GoalSetupViewModel: ObservableObject {
    @Published var kind: GoalKind = .buildMuscle
    @Published var name = ""
    @Published var proteinText = ""
    @Published var energyText = ""
    @Published var sugarText = ""
    @Published var saturatedFatText = ""
    @Published var sodiumText = ""
    @Published var allergensText = ""
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private let goalRepository: NutritionGoalRepository
    private let setGoalUseCase: SetNutritionGoalUseCase
    private var editingGoalID = UUID()
    private var hasLoaded = false

    init(goalRepository: NutritionGoalRepository, setGoalUseCase: SetNutritionGoalUseCase) {
        self.goalRepository = goalRepository
        self.setGoalUseCase = setGoalUseCase
    }

    /// Shows the active goal, or a starting goal if there is none yet.
    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true

        if let active = try? goalRepository.activeGoal() {
            editingGoalID = active.id
            fill(from: active)
            statusMessage = "Your active goal is \(active.name)."
        } else {
            startNewGoal(of: .buildMuscle)
        }
    }

    /// Choosing a kind starts a new goal with editable starting numbers.
    func chooseKind(_ newKind: GoalKind) {
        startNewGoal(of: newKind)
        errorMessage = nil
        statusMessage = "These are starting numbers. Change them if you like, then save."
    }

    func save() {
        errorMessage = nil
        statusMessage = nil

        do {
            let goal = NutritionGoal(
                id: editingGoalID,
                name: name.trimmingCharacters(in: .whitespaces).isEmpty ? kind.title : name,
                kind: kind,
                isActive: true,
                proteinMinPerServeGrams: try number(proteinText),
                energyMaxPerServeKilojoules: try number(energyText),
                sugarMaxPer100g: try number(sugarText),
                saturatedFatMaxPer100g: try number(saturatedFatText),
                sodiumMaxPer100gMilligrams: try number(sodiumText),
                avoidedAllergens: allergens()
            )
            let saved = try setGoalUseCase.execute(goal)
            statusMessage = "Saved. \(saved.name) is now your active goal."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Helpers

    private func startNewGoal(of newKind: GoalKind) {
        editingGoalID = UUID()
        fill(from: NutritionGoal.starting(for: newKind))
    }

    private func fill(from goal: NutritionGoal) {
        kind = goal.kind
        name = goal.name
        proteinText = text(goal.proteinMinPerServeGrams)
        energyText = text(goal.energyMaxPerServeKilojoules)
        sugarText = text(goal.sugarMaxPer100g)
        saturatedFatText = text(goal.saturatedFatMaxPer100g)
        sodiumText = text(goal.sodiumMaxPer100gMilligrams)
        allergensText = goal.avoidedAllergens.joined(separator: ", ")
    }

    private func text(_ value: Double?) -> String {
        guard let value = value else { return "" }
        return value == value.rounded() ? String(Int(value)) : String(value)
    }

    // An empty box means "no target". Anything else must be a number.
    private func number(_ text: String) throws -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        guard let value = Double(trimmed) else { throw InputError.notANumber }
        return value
    }

    private func allergens() -> [String] {
        return allergensText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private enum InputError: LocalizedError {
        case notANumber

        var errorDescription: String? {
            return "One of the targets isn't a number. Use digits only, for example 30 or 7.5."
        }
    }
}
