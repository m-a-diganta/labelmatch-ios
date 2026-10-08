import Foundation

/// The numbers read from one Nutrition Information Panel.
/// Nutrient values are per 100 g, as printed on the label.
struct NutritionPanelValues: Equatable {
    var energyKilojoulesPer100g: Double
    var proteinGramsPer100g: Double
    var sugarsGramsPer100g: Double
    var saturatedFatGramsPer100g: Double
    var sodiumMilligramsPer100g: Double
    var servingSizeGrams: Double
    var declaredAllergens: [String]

    /// Turns a per 100 g value into a per serve value.
    func perServe(_ valuePer100g: Double) -> Double {
        return valuePer100g * servingSizeGrams / 100
    }

    var proteinGramsPerServe: Double {
        return perServe(proteinGramsPer100g)
    }

    var energyKilojoulesPerServe: Double {
        return perServe(energyKilojoulesPer100g)
    }
}
