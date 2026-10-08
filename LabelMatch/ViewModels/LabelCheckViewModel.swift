import Foundation
import Combine

/// State for the Check tab: choose a photo, review the numbers, read the verdict.
final class LabelCheckViewModel: ObservableObject {

    enum Stage {
        case choosePhoto
        case review
        case verdict
    }

    @Published var stage: Stage = .choosePhoto
    @Published var isReading = false
    @Published var errorMessage: String?
    @Published var pendingFilenames: [String] = []
    @Published var result: LabelCheck?

    // The review form. Text fields let the shopper type freely.
    @Published var productName = ""
    @Published var energyText = ""
    @Published var proteinText = ""
    @Published var sugarsText = ""
    @Published var saturatedFatText = ""
    @Published var sodiumText = ""
    @Published var servingSizeText = ""
    @Published var allergensText = ""

    private let readUseCase: ReadNutritionPanelUseCase
    private let assessUseCase: AssessLabelForGoalUseCase
    private let inboxRepository: SharedInboxRepository
    private var sharedFilename: String?

    init(readUseCase: ReadNutritionPanelUseCase,
         assessUseCase: AssessLabelForGoalUseCase,
         inboxRepository: SharedInboxRepository) {
        self.readUseCase = readUseCase
        self.assessUseCase = assessUseCase
        self.inboxRepository = inboxRepository
    }

    // MARK: Choosing a photo

    func refreshInbox() {
        pendingFilenames = (try? inboxRepository.pendingFilenames()) ?? []
    }

    func beginReading() {
        errorMessage = nil
        isReading = true
    }

    func photoCouldNotBeOpened() {
        isReading = false
        errorMessage = "I couldn't open that photo. Choose another photo and try again."
    }

    /// Reads the numbers from the photo, then shows them for review.
    func readPhoto(data: Data, sharedFilename: String? = nil) {
        errorMessage = nil
        do {
            let values = try readUseCase.execute(imageData: data)
            fill(from: values)
            self.sharedFilename = sharedFilename
            stage = .review
        } catch {
            errorMessage = error.localizedDescription
        }
        isReading = false
    }

    func openSharedPhoto(named filename: String) {
        do {
            let data = try inboxRepository.photoData(named: filename)
            readPhoto(data: data, sharedFilename: filename)
        } catch {
            errorMessage = "I couldn't open that shared photo. Try sharing it again."
        }
    }

    /// For when the photo can't be read. The shopper types the numbers.
    func typeValuesManually() {
        errorMessage = nil
        clearForm()
        sharedFilename = nil
        stage = .review
    }

    // MARK: Judging the label

    func assess() {
        errorMessage = nil
        do {
            let values = NutritionPanelValues(
                energyKilojoulesPer100g: try number(energyText, "energy"),
                proteinGramsPer100g: try number(proteinText, "protein"),
                sugarsGramsPer100g: try number(sugarsText, "sugars"),
                saturatedFatGramsPer100g: try number(saturatedFatText, "saturated fat"),
                sodiumMilligramsPer100g: try number(sodiumText, "sodium"),
                servingSizeGrams: try number(servingSizeText, "serving size"),
                declaredAllergens: allergens()
            )
            let name = productName.trimmingCharacters(in: .whitespaces)
            let check = try assessUseCase.execute(
                productName: name.isEmpty ? "Unnamed product" : name,
                values: values,
                sourceImageFilename: sharedFilename)

            result = check
            stage = .verdict
            removeSharedPhoto()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startOver() {
        clearForm()
        result = nil
        errorMessage = nil
        sharedFilename = nil
        stage = .choosePhoto
        refreshInbox()
    }

    // MARK: Helpers

    private func removeSharedPhoto() {
        if let name = sharedFilename {
            try? inboxRepository.removePhoto(named: name)
            sharedFilename = nil
        }
    }

    private func fill(from values: NutritionPanelValues) {
        productName = ""
        energyText = text(values.energyKilojoulesPer100g)
        proteinText = text(values.proteinGramsPer100g)
        sugarsText = text(values.sugarsGramsPer100g)
        saturatedFatText = text(values.saturatedFatGramsPer100g)
        sodiumText = text(values.sodiumMilligramsPer100g)
        servingSizeText = text(values.servingSizeGrams)
        allergensText = values.declaredAllergens.joined(separator: ", ")
    }

    private func clearForm() {
        productName = ""
        energyText = ""
        proteinText = ""
        sugarsText = ""
        saturatedFatText = ""
        sodiumText = ""
        servingSizeText = ""
        allergensText = ""
    }

    private func text(_ value: Double) -> String {
        return value == value.rounded() ? String(Int(value)) : String(value)
    }

    private func number(_ text: String, _ name: String) throws -> Double {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned) else {
            throw ReviewInputError.notANumber(name)
        }
        return value
    }

    private func allergens() -> [String] {
        return allergensText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }

    private enum ReviewInputError: LocalizedError {
        case notANumber(String)

        var errorDescription: String? {
            switch self {
            case .notANumber(let name):
                return "The \(name) number is missing or isn't a number. Type the value from the label using digits only, for example 12.5."
            }
        }
    }
}
