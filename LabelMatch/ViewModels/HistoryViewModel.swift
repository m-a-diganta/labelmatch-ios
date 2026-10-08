import Foundation
import Combine

/// State for the History screen.
final class HistoryViewModel: ObservableObject {
    @Published var checks: [LabelCheck] = []
    @Published var showOnlyThingsToAvoid = false
    @Published var errorMessage: String?

    private let checkRepository: LabelCheckRepository

    init(checkRepository: LabelCheckRepository) {
        self.checkRepository = checkRepository
    }

    /// Loads every check, or only this week's "things to avoid" for the active goal.
    func load() {
        errorMessage = nil
        do {
            if showOnlyThingsToAvoid {
                checks = try checkRepository.notSuitableChecksForActiveGoal(since: startOfThisWeek())
            } else {
                checks = try checkRepository.allChecks()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startOfThisWeek() -> Date {
        let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        return week?.start ?? Date().addingTimeInterval(-7 * 24 * 3600)
    }
}
