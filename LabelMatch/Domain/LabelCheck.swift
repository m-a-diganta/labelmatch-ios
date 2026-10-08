import Foundation

/// The result of checking a label against a goal.
enum Verdict: String, CaseIterable, Equatable {
    case suitable
    case caution
    case notSuitable

    var title: String {
        switch self {
        case .suitable: return "Suitable"
        case .caution: return "Suitable with caution"
        case .notSuitable: return "Not suitable"
        }
    }

    /// A higher rank is a better result.
    var rank: Int {
        switch self {
        case .suitable: return 2
        case .caution: return 1
        case .notSuitable: return 0
        }
    }
}

/// One part of a verdict, for example "Sugars 12 g per 100 g, your limit is 10 g".
struct VerdictReason: Identifiable, Equatable {
    let id: UUID
    let nutrientName: String
    let comparedValue: Double
    let limit: Double
    let message: String
    let severity: Verdict

    init(id: UUID = UUID(),
         nutrientName: String,
         comparedValue: Double,
         limit: Double,
         message: String,
         severity: Verdict) {
        self.id = id
        self.nutrientName = nutrientName
        self.comparedValue = comparedValue
        self.limit = limit
        self.message = message
        self.severity = severity
    }
}

/// One label that has been checked.
/// It keeps a snapshot of the numbers and the verdict at the time of the check.
struct LabelCheck: Identifiable, Equatable {
    let id: UUID
    let goalID: UUID
    let goalNameAtCheck: String
    let productName: String
    let checkedAt: Date
    let values: NutritionPanelValues
    let verdict: Verdict
    let reasons: [VerdictReason]
    let sourceImageFilename: String?

    var servingSizeGrams: Double {
        return values.servingSizeGrams
    }
}
