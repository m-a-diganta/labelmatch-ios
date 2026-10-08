import Foundation
import Combine

/// Creates the data store, repositories and use cases once.
/// Every screen shares them.
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceController
    let goalRepository: NutritionGoalRepository
    let checkRepository: LabelCheckRepository
    let widgetReloader: WidgetReloading
    let setGoalUseCase: SetNutritionGoalUseCase

    init() {
        let persistence = PersistenceController()
        let goalRepository = CoreDataNutritionGoalRepository(persistence: persistence)
        let checkRepository = CoreDataLabelCheckRepository(persistence: persistence)

        self.persistence = persistence
        self.goalRepository = goalRepository
        self.checkRepository = checkRepository
        self.widgetReloader = WidgetCenterReloader()
        self.setGoalUseCase = SetNutritionGoalUseCase(goalRepository: goalRepository)
    }

    func makeGoalSetupViewModel() -> GoalSetupViewModel {
        return GoalSetupViewModel(goalRepository: goalRepository,
                                  setGoalUseCase: setGoalUseCase)
    }
}
