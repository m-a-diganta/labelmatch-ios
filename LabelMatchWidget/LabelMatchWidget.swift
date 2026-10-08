import WidgetKit
import SwiftUI

// MARK: The data the widget shows

struct RecentCheck: Identifiable {
    let id: UUID
    let name: String
    let verdict: Verdict
}

struct LabelMatchEntry: TimelineEntry {
    let date: Date
    let goalName: String?
    let keyTargets: [String]
    let tally: VerdictTally
    let recent: [RecentCheck]

    static let sample = LabelMatchEntry(
        date: Date(),
        goalName: "Build muscle",
        keyTargets: ["Protein at least 30 g per serve", "Sugars under 10 g per 100 g"],
        tally: VerdictTally(suitable: 5, caution: 1, notSuitable: 2),
        recent: [
            RecentCheck(id: UUID(), name: "Protein bar", verdict: .suitable),
            RecentCheck(id: UUID(), name: "Peanut biscuit", verdict: .notSuitable),
            RecentCheck(id: UUID(), name: "Greek yoghurt", verdict: .caution)
        ]
    )
}

/// Reads the goal and this week's checks from the shared store.
/// The widget only reads. It never changes any data.
enum WidgetDataLoader {

    static func load() -> LabelMatchEntry {
        let persistence = PersistenceController()
        let goalRepository = CoreDataNutritionGoalRepository(persistence: persistence)
        let checkRepository = CoreDataLabelCheckRepository(persistence: persistence)

        let goal = try? goalRepository.activeGoal()
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let tally = (try? checkRepository.tally(since: weekStart)) ?? VerdictTally()
        let latest = ((try? checkRepository.allChecks()) ?? []).prefix(3)
        let recent = latest.map { RecentCheck(id: $0.id, name: $0.productName, verdict: $0.verdict) }

        return LabelMatchEntry(
            date: Date(),
            goalName: goal?.name,
            keyTargets: goal.map { targets(for: $0) } ?? [],
            tally: tally,
            recent: recent
        )
    }

    private static func targets(for goal: NutritionGoal) -> [String] {
        var lines: [String] = []
        if let value = goal.proteinMinPerServeGrams {
            lines.append("Protein at least \(format(value)) g per serve")
        }
        if let value = goal.energyMaxPerServeKilojoules {
            lines.append("Energy under \(format(value)) kJ per serve")
        }
        if let value = goal.sugarMaxPer100g {
            lines.append("Sugars under \(format(value)) g per 100 g")
        }
        if let value = goal.saturatedFatMaxPer100g {
            lines.append("Saturated fat under \(format(value)) g per 100 g")
        }
        if let value = goal.sodiumMaxPer100gMilligrams {
            lines.append("Sodium under \(format(value)) mg per 100 g")
        }
        if !goal.avoidedAllergens.isEmpty {
            lines.append("Avoid: " + goal.avoidedAllergens.joined(separator: ", "))
        }
        return lines
    }

    private static func format(_ value: Double) -> String {
        return value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

// MARK: Timeline

struct LabelMatchProvider: TimelineProvider {

    func placeholder(in context: Context) -> LabelMatchEntry {
        return .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (LabelMatchEntry) -> Void) {
        completion(context.isPreview ? .sample : WidgetDataLoader.load())
    }

    // The app asks for a new timeline after every saved check or goal change.
    func getTimeline(in context: Context, completion: @escaping (Timeline<LabelMatchEntry>) -> Void) {
        let entry = WidgetDataLoader.load()
        let refresh = Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: Views

private func color(for verdict: Verdict) -> Color {
    switch verdict {
    case .suitable: return .green
    case .caution: return .orange
    case .notSuitable: return .red
    }
}

private func iconName(for verdict: Verdict) -> String {
    switch verdict {
    case .suitable: return "checkmark.circle.fill"
    case .caution: return "exclamationmark.triangle.fill"
    case .notSuitable: return "xmark.octagon.fill"
    }
}

private func shortTitle(for verdict: Verdict) -> String {
    switch verdict {
    case .suitable: return "suitable"
    case .caution: return "caution"
    case .notSuitable: return "not suitable"
    }
}

private let noGoalMessage = "No goal yet. Open LabelMatch and choose a goal."
private let noChecksMessage = "No checks this week. Import a label to start."

private struct TallyView: View {
    let tally: VerdictTally

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            row(.suitable, tally.suitable)
            row(.caution, tally.caution)
            row(.notSuitable, tally.notSuitable)
        }
    }

    private func row(_ verdict: Verdict, _ count: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color(for: verdict))
                .frame(width: 8, height: 8)
            Text("\(count) \(shortTitle(for: verdict))")
                .font(.caption)
        }
    }
}

private struct SmallWidgetView: View {
    let entry: LabelMatchEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let goalName = entry.goalName {
                Text(goalName)
                    .font(.headline)
                    .lineLimit(1)
                Text("This week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if entry.tally.total == 0 {
                    Text(noChecksMessage)
                        .font(.caption)
                } else {
                    TallyView(tally: entry.tally)
                }
            } else {
                Text("LabelMatch")
                    .font(.headline)
                Text(noGoalMessage)
                    .font(.caption)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MediumWidgetView: View {
    let entry: LabelMatchEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            SmallWidgetView(entry: entry)

            VStack(alignment: .leading, spacing: 6) {
                Text("Latest checks")
                    .font(.caption)
                    .bold()
                if entry.recent.isEmpty {
                    Text(entry.goalName == nil ? noGoalMessage : noChecksMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.recent) { check in
                        HStack(spacing: 6) {
                            Image(systemName: iconName(for: check.verdict))
                                .foregroundStyle(color(for: check.verdict))
                            Text(check.name)
                                .lineLimit(1)
                        }
                        .font(.caption)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct LockScreenWidgetView: View {
    let entry: LabelMatchEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let goalName = entry.goalName {
                Text(goalName)
                    .font(.headline)
                    .lineLimit(1)
                if let firstTarget = entry.keyTargets.first {
                    Text(firstTarget)
                        .font(.caption2)
                        .lineLimit(1)
                }
                Text("This week: \(entry.tally.suitable) ok, \(entry.tally.notSuitable) to avoid")
                    .font(.caption2)
                    .lineLimit(1)
            } else {
                Text("LabelMatch")
                    .font(.headline)
                Text("Choose a goal in the app")
                    .font(.caption2)
            }
        }
    }
}

struct LabelMatchWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LabelMatchEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: The widget

struct LabelMatchWidget: Widget {
    let kind = "LabelMatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LabelMatchProvider()) { entry in
            LabelMatchWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("LabelMatch")
        .description("Your goal's targets and this week's label checks.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
