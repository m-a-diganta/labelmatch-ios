import Foundation

// Use cases only talk to these protocols.
// The real versions use Core Data, Vision and WidgetKit.
// Unit tests swap in simple mock versions.

struct VerdictTally: Equatable {
    var suitable = 0
    var caution = 0
    var notSuitable = 0

    var total: Int {
        return suitable + caution + notSuitable
    }
}

protocol NutritionGoalRepository {
    func allGoals() throws -> [NutritionGoal]
    func activeGoal() throws -> NutritionGoal?
    func save(_ goal: NutritionGoal) throws
    func setActiveGoal(id: UUID) throws
    func deleteGoal(id: UUID) throws
}

protocol LabelCheckRepository {
    func save(_ check: LabelCheck) throws
    func allChecks() throws -> [LabelCheck]
    func checks(since date: Date) throws -> [LabelCheck]
    func notSuitableChecksForActiveGoal(since date: Date) throws -> [LabelCheck]
    func tally(since date: Date) throws -> VerdictTally
}

/// Label photos waiting in the shared App Group Inbox folder.
protocol SharedInboxRepository {
    func pendingFilenames() throws -> [String]
    func photoData(named filename: String) throws -> Data
    func removePhoto(named filename: String) throws
}

/// Reads the text in a photo. The real version uses Vision on the device.
protocol NutritionPanelReader {
    func recognisedLines(in imageData: Data) throws -> [String]
}

/// Asks the widgets to refresh after data changes.
protocol WidgetReloading {
    func reloadWidgets()
}
