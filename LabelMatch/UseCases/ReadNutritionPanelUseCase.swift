import Foundation

/// Turns a label photo into numbers.
/// The reader finds the text. This use case finds the values in it.
struct ReadNutritionPanelUseCase {
    let reader: NutritionPanelReader

    func execute(imageData: Data) throws -> NutritionPanelValues {
        let lines = try reader.recognisedLines(in: imageData)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw ReadNutritionPanelError.noTextFound
        }
        guard looksLikeNutritionPanel(lines) else {
            throw ReadNutritionPanelError.panelNotRecognised
        }

        // Each value must be found. We never guess.
        guard let energy = lastValue(keyword: "energy", unit: "kj", in: lines) else {
            throw missing("energy")
        }
        guard let protein = lastValue(keyword: "protein", unit: "g", in: lines) else {
            throw missing("protein")
        }
        guard let sugars = lastValue(keyword: "sugars", unit: "g", in: lines) else {
            throw missing("sugars")
        }
        guard let saturatedFat = lastValue(keyword: "saturated", unit: "g", in: lines) else {
            throw missing("saturated fat")
        }
        guard let sodium = lastValue(keyword: "sodium", unit: "mg", in: lines) else {
            throw missing("sodium")
        }
        guard let serving = firstValue(keyword: "serving size", unit: "g", in: lines) else {
            throw missing("serving size")
        }

        return NutritionPanelValues(
            energyKilojoulesPer100g: energy,
            proteinGramsPer100g: protein,
            sugarsGramsPer100g: sugars,
            saturatedFatGramsPer100g: saturatedFat,
            sodiumMilligramsPer100g: sodium,
            servingSizeGrams: serving,
            declaredAllergens: declaredAllergens(in: lines)
        )
    }

    private func missing(_ name: String) -> ReadNutritionPanelError {
        return .requiredValueMissing(valueName: name)
    }

    private func looksLikeNutritionPanel(_ lines: [String]) -> Bool {
        let text = lines.joined(separator: " ").lowercased()
        let keywords = ["energy", "protein", "sodium", "sugars", "fat", "carbohydrate", "nutrition"]
        let hits = keywords.filter { text.contains($0) }.count
        return hits >= 2
    }

    // The per 100 g column is the last number on the line.
    private func lastValue(keyword: String, unit: String, in lines: [String]) -> Double? {
        for line in lines where line.lowercased().contains(keyword) {
            if let value = numbers(in: line, unit: unit).last {
                return value
            }
        }
        return nil
    }

    private func firstValue(keyword: String, unit: String, in lines: [String]) -> Double? {
        for line in lines where line.lowercased().contains(keyword) {
            if let value = numbers(in: line, unit: unit).first {
                return value
            }
        }
        return nil
    }

    // Finds numbers that are followed by a unit, for example "13.0 g".
    private func numbers(in line: String, unit: String) -> [Double] {
        let pattern = "([0-9]+(?:\\.[0-9]+)?)\\s*" + unit + "\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(line.startIndex..., in: line)
        var found: [Double] = []
        for match in regex.matches(in: line, options: [], range: range) {
            if let numberRange = Range(match.range(at: 1), in: line),
               let number = Double(line[numberRange]) {
                found.append(number)
            }
        }
        return found
    }

    // Reads lines like "Contains: peanuts, milk".
    private func declaredAllergens(in lines: [String]) -> [String] {
        var allergens: [String] = []
        for line in lines {
            let lower = line.lowercased()
            guard let found = lower.range(of: "contains") ?? lower.range(of: "may contain") else {
                continue
            }
            let rest = lower[found.upperBound...].replacingOccurrences(of: " and ", with: ",")
            let parts = rest.components(separatedBy: CharacterSet(charactersIn: ",;:."))
            for part in parts {
                let word = part.trimmingCharacters(in: .whitespaces)
                if !word.isEmpty {
                    allergens.append(word)
                }
            }
        }
        return allergens
    }
}
