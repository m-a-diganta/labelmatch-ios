import CoreData

/// Saves and loads goals with Core Data.
final class CoreDataNutritionGoalRepository: NutritionGoalRepository {
    private let persistence: PersistenceController

    private var context: NSManagedObjectContext {
        return persistence.context
    }

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func allGoals() throws -> [NutritionGoal] {
        return try context.performAndWait { () throws -> [NutritionGoal] in
            let request = NSFetchRequest<NSManagedObject>(entityName: EntityName.goal)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try context.fetch(request).map { goal(from: $0) }
        }
    }

    /// Query: the one goal where isActive is true.
    func activeGoal() throws -> NutritionGoal? {
        return try context.performAndWait { () throws -> NutritionGoal? in
            let request = NSFetchRequest<NSManagedObject>(entityName: EntityName.goal)
            request.predicate = NSPredicate(format: "isActive == YES")
            request.fetchLimit = 1
            guard let object = try context.fetch(request).first else { return nil }
            return goal(from: object)
        }
    }

    func save(_ goal: NutritionGoal) throws {
        try context.performAndWait { () throws -> Void in
            let object = try findObject(id: goal.id)
                ?? NSEntityDescription.insertNewObject(forEntityName: EntityName.goal, into: context)

            if object.value(forKey: "createdAt") == nil {
                object.setValue(Date(), forKey: "createdAt")
            }
            object.setValue(goal.id, forKey: "id")
            object.setValue(goal.name, forKey: "name")
            object.setValue(goal.kind.rawValue, forKey: "kind")
            object.setValue(goal.isActive, forKey: "isActive")
            object.setValue(goal.proteinMinPerServeGrams, forKey: "proteinMinPerServeGrams")
            object.setValue(goal.energyMaxPerServeKilojoules, forKey: "energyMaxPerServeKilojoules")
            object.setValue(goal.sugarMaxPer100g, forKey: "sugarMaxPer100g")
            object.setValue(goal.saturatedFatMaxPer100g, forKey: "saturatedFatMaxPer100g")
            object.setValue(goal.sodiumMaxPer100gMilligrams, forKey: "sodiumMaxPer100gMilligrams")
            object.setValue(goal.avoidedAllergens.joined(separator: ","), forKey: "avoidedAllergens")
            try persistence.save()
        }
    }

    /// Makes one goal active and every other goal not active.
    func setActiveGoal(id: UUID) throws {
        try context.performAndWait { () throws -> Void in
            let request = NSFetchRequest<NSManagedObject>(entityName: EntityName.goal)
            for object in try context.fetch(request) {
                let isThisOne = (object.value(forKey: "id") as? UUID) == id
                object.setValue(isThisOne, forKey: "isActive")
            }
            try persistence.save()
        }
    }

    func deleteGoal(id: UUID) throws {
        try context.performAndWait { () throws -> Void in
            if let object = try findObject(id: id) {
                context.delete(object)
                try persistence.save()
            }
        }
    }

    // MARK: Helpers

    private func findObject(id: UUID) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: EntityName.goal)
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func goal(from object: NSManagedObject) -> NutritionGoal {
        let allergenText = object.value(forKey: "avoidedAllergens") as? String ?? ""
        let allergens = allergenText.split(separator: ",").map { String($0) }
        let kindText = object.value(forKey: "kind") as? String ?? ""

        return NutritionGoal(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            name: object.value(forKey: "name") as? String ?? "",
            kind: GoalKind(rawValue: kindText) ?? .custom,
            isActive: object.value(forKey: "isActive") as? Bool ?? false,
            proteinMinPerServeGrams: object.value(forKey: "proteinMinPerServeGrams") as? Double,
            energyMaxPerServeKilojoules: object.value(forKey: "energyMaxPerServeKilojoules") as? Double,
            sugarMaxPer100g: object.value(forKey: "sugarMaxPer100g") as? Double,
            saturatedFatMaxPer100g: object.value(forKey: "saturatedFatMaxPer100g") as? Double,
            sodiumMaxPer100gMilligrams: object.value(forKey: "sodiumMaxPer100gMilligrams") as? Double,
            avoidedAllergens: allergens
        )
    }
}
