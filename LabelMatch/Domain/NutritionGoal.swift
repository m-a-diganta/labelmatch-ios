import Foundation

/// The kind of goal the shopper is following.
enum GoalKind: String, CaseIterable, Equatable {
    case buildMuscle
    case loseWeight
    case heartHealth
    case custom

    var title: String {
        switch self {
        case .buildMuscle: return "Build muscle"
        case .loseWeight: return "Lose weight"
        case .heartHealth: return "Heart health"
        case .custom: return "Custom"
        }
    }
}

/// A shopper's nutrition goal. Every target is optional.
struct NutritionGoal: Identifiable, Equatable {
    let id: UUID
    var name: String
    var kind: GoalKind
    var isActive: Bool
    var proteinMinPerServeGrams: Double?
    var energyMaxPerServeKilojoules: Double?
    var sugarMaxPer100g: Double?
    var saturatedFatMaxPer100g: Double?
    var sodiumMaxPer100gMilligrams: Double?
    var avoidedAllergens: [String]

    init(id: UUID = UUID(),
         name: String,
         kind: GoalKind = .custom,
         isActive: Bool = false,
         proteinMinPerServeGrams: Double? = nil,
         energyMaxPerServeKilojoules: Double? = nil,
         sugarMaxPer100g: Double? = nil,
         saturatedFatMaxPer100g: Double? = nil,
         sodiumMaxPer100gMilligrams: Double? = nil,
         avoidedAllergens: [String] = []) {
        self.id = id
        self.name = name
        self.kind = kind
        self.isActive = isActive
        self.proteinMinPerServeGrams = proteinMinPerServeGrams
        self.energyMaxPerServeKilojoules = energyMaxPerServeKilojoules
        self.sugarMaxPer100g = sugarMaxPer100g
        self.saturatedFatMaxPer100g = saturatedFatMaxPer100g
        self.sodiumMaxPer100gMilligrams = sodiumMaxPer100gMilligrams
        self.avoidedAllergens = avoidedAllergens
    }

    /// True when the goal has at least one target or limit.
    /// Avoided allergens count as a limit.
    var hasAnyTarget: Bool {
        return proteinMinPerServeGrams != nil
            || energyMaxPerServeKilojoules != nil
            || sugarMaxPer100g != nil
            || saturatedFatMaxPer100g != nil
            || sodiumMaxPer100gMilligrams != nil
            || !avoidedAllergens.isEmpty
    }

    /// Editable starting numbers for each kind of goal.
    /// They are starting points, not medical advice.
    static func starting(for kind: GoalKind) -> NutritionGoal {
        switch kind {
        case .buildMuscle:
            return NutritionGoal(name: "Build muscle", kind: kind,
                                 proteinMinPerServeGrams: 30, sugarMaxPer100g: 10)
        case .loseWeight:
            return NutritionGoal(name: "Lose weight", kind: kind,
                                 energyMaxPerServeKilojoules: 800,
                                 sugarMaxPer100g: 10, saturatedFatMaxPer100g: 3)
        case .heartHealth:
            return NutritionGoal(name: "Heart health", kind: kind,
                                 saturatedFatMaxPer100g: 3, sodiumMaxPer100gMilligrams: 120)
        case .custom:
            return NutritionGoal(name: "My goal", kind: kind)
        }
    }
}
