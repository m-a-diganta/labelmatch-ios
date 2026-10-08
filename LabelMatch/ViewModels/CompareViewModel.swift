import Foundation
import Combine

/// State for the Compare screen.
final class CompareViewModel: ObservableObject {
    @Published var checks: [LabelCheck] = []
    @Published var selectedIDs: [UUID] = []
    @Published var result: ComparisonResult?
    @Published var errorMessage: String?

    private let checkRepository: LabelCheckRepository
    private let compareUseCase: CompareLabelChecksUseCase

    init(checkRepository: LabelCheckRepository, compareUseCase: CompareLabelChecksUseCase) {
        self.checkRepository = checkRepository
        self.compareUseCase = compareUseCase
    }

    /// The selected checks, in the order they were picked.
    var selectedChecks: [LabelCheck] {
        return selectedIDs.compactMap { id in
            checks.first { $0.id == id }
        }
    }

    func load() {
        do {
            checks = try checkRepository.allChecks()
        } catch {
            errorMessage = error.localizedDescription
        }
        selectedIDs = selectedIDs.filter { id in
            checks.contains { $0.id == id }
        }
    }

    func isSelected(_ check: LabelCheck) -> Bool {
        return selectedIDs.contains(check.id)
    }

    /// Only two checks can be picked. A third pick replaces the oldest pick.
    func toggle(_ check: LabelCheck) {
        result = nil
        errorMessage = nil
        if let index = selectedIDs.firstIndex(of: check.id) {
            selectedIDs.remove(at: index)
        } else {
            if selectedIDs.count == 2 {
                selectedIDs.removeFirst()
            }
            selectedIDs.append(check.id)
        }
    }

    func compare() {
        errorMessage = nil
        do {
            result = try compareUseCase.execute(checks: selectedChecks)
        } catch {
            result = nil
            errorMessage = error.localizedDescription
        }
    }
}
