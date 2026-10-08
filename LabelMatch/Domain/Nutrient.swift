import Foundation

/// The nutrients LabelMatch checks.
enum Nutrient: String, CaseIterable, Equatable {
    case energy
    case protein
    case sugars
    case saturatedFat
    case sodium

    var displayName: String {
        switch self {
        case .energy: return "Energy"
        case .protein: return "Protein"
        case .sugars: return "Sugars"
        case .saturatedFat: return "Saturated fat"
        case .sodium: return "Sodium"
        }
    }

    var unit: String {
        switch self {
        case .energy: return "kJ"
        case .sodium: return "mg"
        default: return "g"
        }
    }

    /// A believable range for a target. Used when a goal is saved.
    var targetRange: ClosedRange<Double> {
        switch self {
        case .energy: return 50...5000
        case .protein: return 1...100
        case .sugars: return 0...100
        case .saturatedFat: return 0...100
        case .sodium: return 0...5000
        }
    }
}
