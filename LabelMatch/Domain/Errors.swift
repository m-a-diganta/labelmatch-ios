import Foundation

// Every error says what went wrong and what the shopper can do next.

enum SetNutritionGoalError: LocalizedError, Equatable {
    case noTargetsSet
    case implausibleTarget(nutrient: Nutrient)

    var errorDescription: String? {
        switch self {
        case .noTargetsSet:
            return "Your goal needs at least one target, such as protein per serve or a sugar limit. Add one to continue."
        case .implausibleTarget(let nutrient):
            let range = nutrient.targetRange
            return "The \(nutrient.displayName.lowercased()) number doesn't look right. Enter a value between \(Int(range.lowerBound)) and \(Int(range.upperBound)) \(nutrient.unit)."
        }
    }
}

enum ReadNutritionPanelError: LocalizedError, Equatable {
    case noTextFound
    case panelNotRecognised
    case requiredValueMissing(valueName: String)

    var errorDescription: String? {
        switch self {
        case .noTextFound:
            return "I couldn't read any text in this photo. Take the photo closer, in good light, and try again."
        case .panelNotRecognised:
            return "This doesn't look like a Nutrition Information Panel. Photograph the panel on the back of the pack."
        case .requiredValueMissing(let valueName):
            return "I couldn't find \(valueName) on this label. Retake the photo closer to the panel, or type the value in."
        }
    }
}

enum AssessLabelError: LocalizedError, Equatable {
    case noActiveGoal
    case invalidServingSize

    var errorDescription: String? {
        switch self {
        case .noActiveGoal:
            return "Choose a goal before checking a label. Open Goals and pick the one you are following."
        case .invalidServingSize:
            return "The serving size must be more than zero. Check the serving size on the label and correct it."
        }
    }
}

enum CompareLabelChecksError: LocalizedError, Equatable {
    case differentGoals
    case fewerThanTwoChecks

    var errorDescription: String? {
        switch self {
        case .differentGoals:
            return "These two checks used different goals, so they can't be compared fairly. Check one of them again against the same goal."
        case .fewerThanTwoChecks:
            return "Pick two checks to compare."
        }
    }
}
