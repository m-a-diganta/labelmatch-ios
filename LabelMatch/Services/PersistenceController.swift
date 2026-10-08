import CoreData

/// Names of the Core Data entities.
enum EntityName {
    static let goal = "NutritionGoalEntity"
    static let check = "LabelCheckEntity"
    static let reason = "VerdictReasonEntity"
}

/// Errors from the data store, written for the shopper.
enum StorageError: LocalizedError, Equatable {
    case couldNotSave

    var errorDescription: String? {
        switch self {
        case .couldNotSave:
            return "LabelMatch couldn't save your data. Close the app, open it again and try once more."
        }
    }
}

/// Builds the Core Data store.
/// The store file is in the App Group container, so the widget reads the same data as the app.
final class PersistenceController {
    let container: NSPersistentContainer

    var context: NSManagedObjectContext {
        return container.viewContext
    }

    init(storeURL: URL = AppGroup.storeURL) {
        container = NSPersistentContainer(name: "LabelMatch",
                                          managedObjectModel: PersistenceController.model)
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                print("LabelMatch could not open its data store: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Saves changes. If saving fails, the changes are undone.
    func save() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw StorageError.couldNotSave
        }
    }

    // MARK: The model
    // It is written in code so the app and the widget share one definition.
    // Goal 1 to many Check, and Check 1 to many Reason.

    nonisolated(unsafe) static let model: NSManagedObjectModel = makeModel()

    private static func attribute(_ name: String,
                                  _ type: NSAttributeType,
                                  optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }

    private static func makeModel() -> NSManagedObjectModel {
        let goal = NSEntityDescription()
        goal.name = EntityName.goal
        let check = NSEntityDescription()
        check.name = EntityName.check
        let reason = NSEntityDescription()
        reason.name = EntityName.reason

        // Goal to checks. Deleting a goal deletes its history.
        let goalChecks = NSRelationshipDescription()
        goalChecks.name = "checks"
        goalChecks.destinationEntity = check
        goalChecks.minCount = 0
        goalChecks.maxCount = 0
        goalChecks.isOptional = true
        goalChecks.deleteRule = .cascadeDeleteRule

        let checkGoal = NSRelationshipDescription()
        checkGoal.name = "goal"
        checkGoal.destinationEntity = goal
        checkGoal.minCount = 0
        checkGoal.maxCount = 1
        checkGoal.isOptional = true
        checkGoal.deleteRule = .nullifyDeleteRule

        goalChecks.inverseRelationship = checkGoal
        checkGoal.inverseRelationship = goalChecks

        // Check to reasons. Deleting a check deletes its reasons.
        let checkReasons = NSRelationshipDescription()
        checkReasons.name = "reasons"
        checkReasons.destinationEntity = reason
        checkReasons.minCount = 0
        checkReasons.maxCount = 0
        checkReasons.isOptional = true
        checkReasons.deleteRule = .cascadeDeleteRule

        let reasonCheck = NSRelationshipDescription()
        reasonCheck.name = "check"
        reasonCheck.destinationEntity = check
        reasonCheck.minCount = 0
        reasonCheck.maxCount = 1
        reasonCheck.isOptional = true
        reasonCheck.deleteRule = .nullifyDeleteRule

        checkReasons.inverseRelationship = reasonCheck
        reasonCheck.inverseRelationship = checkReasons

        goal.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("kind", .stringAttributeType),
            attribute("isActive", .booleanAttributeType),
            attribute("createdAt", .dateAttributeType),
            attribute("proteinMinPerServeGrams", .doubleAttributeType, optional: true),
            attribute("energyMaxPerServeKilojoules", .doubleAttributeType, optional: true),
            attribute("sugarMaxPer100g", .doubleAttributeType, optional: true),
            attribute("saturatedFatMaxPer100g", .doubleAttributeType, optional: true),
            attribute("sodiumMaxPer100gMilligrams", .doubleAttributeType, optional: true),
            attribute("avoidedAllergens", .stringAttributeType),
            goalChecks
        ]

        check.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("goalID", .UUIDAttributeType),
            attribute("goalNameAtCheck", .stringAttributeType),
            attribute("productName", .stringAttributeType),
            attribute("checkedAt", .dateAttributeType),
            attribute("servingSizeGrams", .doubleAttributeType),
            attribute("energyKilojoulesPer100g", .doubleAttributeType),
            attribute("proteinGramsPer100g", .doubleAttributeType),
            attribute("sugarsGramsPer100g", .doubleAttributeType),
            attribute("saturatedFatGramsPer100g", .doubleAttributeType),
            attribute("sodiumMilligramsPer100g", .doubleAttributeType),
            attribute("declaredAllergens", .stringAttributeType),
            attribute("verdict", .stringAttributeType),
            attribute("sourceImageFilename", .stringAttributeType, optional: true),
            checkGoal,
            checkReasons
        ]

        reason.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("nutrientName", .stringAttributeType),
            attribute("comparedValue", .doubleAttributeType),
            attribute("limit", .doubleAttributeType),
            attribute("message", .stringAttributeType),
            attribute("severity", .stringAttributeType),
            attribute("orderIndex", .doubleAttributeType),
            reasonCheck
        ]

        let model = NSManagedObjectModel()
        model.entities = [goal, check, reason]
        return model
    }
}
