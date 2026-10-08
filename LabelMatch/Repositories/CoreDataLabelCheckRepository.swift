import CoreData

/// Saves and loads label checks with Core Data.
final class CoreDataLabelCheckRepository: LabelCheckRepository {
    private let persistence: PersistenceController

    private var context: NSManagedObjectContext {
        return persistence.context
    }

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    /// Saves the check and its reasons. The check is linked to its goal.
    func save(_ check: LabelCheck) throws {
        try context.performAndWait { () throws -> Void in
            let object = NSEntityDescription.insertNewObject(forEntityName: EntityName.check, into: context)
            object.setValue(check.id, forKey: "id")
            object.setValue(check.goalID, forKey: "goalID")
            object.setValue(check.goalNameAtCheck, forKey: "goalNameAtCheck")
            object.setValue(check.productName, forKey: "productName")
            object.setValue(check.checkedAt, forKey: "checkedAt")
            object.setValue(check.values.servingSizeGrams, forKey: "servingSizeGrams")
            object.setValue(check.values.energyKilojoulesPer100g, forKey: "energyKilojoulesPer100g")
            object.setValue(check.values.proteinGramsPer100g, forKey: "proteinGramsPer100g")
            object.setValue(check.values.sugarsGramsPer100g, forKey: "sugarsGramsPer100g")
            object.setValue(check.values.saturatedFatGramsPer100g, forKey: "saturatedFatGramsPer100g")
            object.setValue(check.values.sodiumMilligramsPer100g, forKey: "sodiumMilligramsPer100g")
            object.setValue(check.values.declaredAllergens.joined(separator: ","), forKey: "declaredAllergens")
            object.setValue(check.verdict.rawValue, forKey: "verdict")
            object.setValue(check.sourceImageFilename, forKey: "sourceImageFilename")

            let goalObject = try findGoalObject(id: check.goalID)
            object.setValue(goalObject, forKey: "goal")

            for (index, reason) in check.reasons.enumerated() {
                let reasonObject = NSEntityDescription.insertNewObject(forEntityName: EntityName.reason, into: context)
                reasonObject.setValue(reason.id, forKey: "id")
                reasonObject.setValue(reason.nutrientName, forKey: "nutrientName")
                reasonObject.setValue(reason.comparedValue, forKey: "comparedValue")
                reasonObject.setValue(reason.limit, forKey: "limit")
                reasonObject.setValue(reason.message, forKey: "message")
                reasonObject.setValue(reason.severity.rawValue, forKey: "severity")
                reasonObject.setValue(Double(index), forKey: "orderIndex")
                reasonObject.setValue(object, forKey: "check")
            }
            try persistence.save()
        }
    }

    func allChecks() throws -> [LabelCheck] {
        return try fetchChecks(predicate: nil)
    }

    func checks(since date: Date) throws -> [LabelCheck] {
        return try fetchChecks(predicate: NSPredicate(format: "checkedAt >= %@", date as NSDate))
    }

    /// Query: checks since a date that were not suitable, for the goal that is active now.
    func notSuitableChecksForActiveGoal(since date: Date) throws -> [LabelCheck] {
        let predicate = NSPredicate(
            format: "checkedAt >= %@ AND verdict == %@ AND goal.isActive == YES",
            date as NSDate, Verdict.notSuitable.rawValue)
        return try fetchChecks(predicate: predicate)
    }

    /// Counts the checks since a date by verdict. The widget uses this.
    func tally(since date: Date) throws -> VerdictTally {
        var tally = VerdictTally()
        for check in try checks(since: date) {
            switch check.verdict {
            case .suitable: tally.suitable += 1
            case .caution: tally.caution += 1
            case .notSuitable: tally.notSuitable += 1
            }
        }
        return tally
    }

    // MARK: Helpers

    private func fetchChecks(predicate: NSPredicate?) throws -> [LabelCheck] {
        return try context.performAndWait { () throws -> [LabelCheck] in
            let request = NSFetchRequest<NSManagedObject>(entityName: EntityName.check)
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(key: "checkedAt", ascending: false)]
            return try context.fetch(request).map { check(from: $0) }
        }
    }

    private func findGoalObject(id: UUID) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: EntityName.goal)
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func number(_ object: NSManagedObject, _ key: String) -> Double {
        return object.value(forKey: key) as? Double ?? 0
    }

    private func text(_ object: NSManagedObject, _ key: String) -> String {
        return object.value(forKey: key) as? String ?? ""
    }

    private func check(from object: NSManagedObject) -> LabelCheck {
        let allergens = text(object, "declaredAllergens").split(separator: ",").map { String($0) }

        let values = NutritionPanelValues(
            energyKilojoulesPer100g: number(object, "energyKilojoulesPer100g"),
            proteinGramsPer100g: number(object, "proteinGramsPer100g"),
            sugarsGramsPer100g: number(object, "sugarsGramsPer100g"),
            saturatedFatGramsPer100g: number(object, "saturatedFatGramsPer100g"),
            sodiumMilligramsPer100g: number(object, "sodiumMilligramsPer100g"),
            servingSizeGrams: number(object, "servingSizeGrams"),
            declaredAllergens: allergens
        )

        let reasonObjects = (object.value(forKey: "reasons") as? Set<NSManagedObject>) ?? []
        let reasons = reasonObjects
            .sorted { number($0, "orderIndex") < number($1, "orderIndex") }
            .map { reason(from: $0) }

        return LabelCheck(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            goalID: object.value(forKey: "goalID") as? UUID ?? UUID(),
            goalNameAtCheck: text(object, "goalNameAtCheck"),
            productName: text(object, "productName"),
            checkedAt: object.value(forKey: "checkedAt") as? Date ?? Date(),
            values: values,
            verdict: Verdict(rawValue: text(object, "verdict")) ?? .suitable,
            reasons: reasons,
            sourceImageFilename: object.value(forKey: "sourceImageFilename") as? String
        )
    }

    private func reason(from object: NSManagedObject) -> VerdictReason {
        return VerdictReason(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            nutrientName: text(object, "nutrientName"),
            comparedValue: number(object, "comparedValue"),
            limit: number(object, "limit"),
            message: text(object, "message"),
            severity: Verdict(rawValue: text(object, "severity")) ?? .suitable
        )
    }
}
