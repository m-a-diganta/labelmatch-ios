import Foundation
import Combine

/// Creates the data store, repositories and use cases once.
/// Every screen shares them.
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceController
    let goalRepository: NutritionGoalRepository
    let checkRepository: LabelCheckRepository
    let inboxRepository: SharedInboxRepository
    let widgetReloader: WidgetReloading
    let setGoalUseCase: SetNutritionGoalUseCase
    let readPanelUseCase: ReadNutritionPanelUseCase
    let assessUseCase: AssessLabelForGoalUseCase
    let compareUseCase: CompareLabelChecksUseCase

    init() {
        let persistence = PersistenceController()
        let goalRepository = CoreDataNutritionGoalRepository(persistence: persistence)
        let checkRepository = CoreDataLabelCheckRepository(persistence: persistence)
        let widgetReloader = WidgetCenterReloader()

        self.persistence = persistence
        self.goalRepository = goalRepository
        self.checkRepository = checkRepository
        self.inboxRepository = FileSharedInboxRepository()
        self.widgetReloader = widgetReloader
        self.setGoalUseCase = SetNutritionGoalUseCase(goalRepository: goalRepository,
                                                               widgetReloader: widgetReloader)
        self.readPanelUseCase = ReadNutritionPanelUseCase(reader: VisionNutritionPanelReader())
        self.assessUseCase = AssessLabelForGoalUseCase(goalRepository: goalRepository,
                                                       checkRepository: checkRepository,
                                                       widgetReloader: widgetReloader)
        self.compareUseCase = CompareLabelChecksUseCase()
    }

    func makeGoalSetupViewModel() -> GoalSetupViewModel {
        return GoalSetupViewModel(goalRepository: goalRepository,
                                  setGoalUseCase: setGoalUseCase)
    }

    func makeLabelCheckViewModel() -> LabelCheckViewModel {
        return LabelCheckViewModel(readUseCase: readPanelUseCase,
                                   assessUseCase: assessUseCase,
                                   inboxRepository: inboxRepository)
    }

    func makeHistoryViewModel() -> HistoryViewModel {
        return HistoryViewModel(checkRepository: checkRepository)
    }

    func makeCompareViewModel() -> CompareViewModel {
        return CompareViewModel(checkRepository: checkRepository,
                                compareUseCase: compareUseCase)
    }
}
