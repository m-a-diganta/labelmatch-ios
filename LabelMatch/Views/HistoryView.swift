import SwiftUI

/// Screen: past checks, and the things to avoid this week.
struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Only things to avoid this week", isOn: $viewModel.showOnlyThingsToAvoid)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    if viewModel.checks.isEmpty {
                        Text(emptyMessage)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.checks) { check in
                        NavigationLink {
                            HistoryDetailView(check: check)
                        } label: {
                            HistoryRow(check: check)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .onAppear {
                viewModel.load()
            }
            .onChange(of: viewModel.showOnlyThingsToAvoid) { _, _ in
                viewModel.load()
            }
        }
    }

    private var emptyMessage: String {
        if viewModel.showOnlyThingsToAvoid {
            return "Nothing to avoid this week. Every label you checked fits your goal."
        }
        return "No labels checked yet. Check a label on the Check tab and it will appear here."
    }
}

private struct HistoryRow: View {
    let check: LabelCheck

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: check.verdict.iconName)
                .foregroundStyle(check.verdict.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(check.productName)
                    .font(.headline)
                Text("\(check.verdict.title) for \(check.goalNameAtCheck)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(check.checkedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct HistoryDetailView: View {
    let check: LabelCheck

    var body: some View {
        List {
            Section {
                Label(check.verdict.title, systemImage: check.verdict.iconName)
                    .font(.headline)
                    .foregroundStyle(check.verdict.color)
                Text("Judged against: \(check.goalNameAtCheck)")
                    .foregroundStyle(.secondary)
            }

            Section("Why") {
                if check.reasons.isEmpty {
                    Text("Nothing on this label broke the goal.")
                }
                ForEach(check.reasons) { reason in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: reason.severity.iconName)
                            .foregroundStyle(reason.severity.color)
                        Text(reason.message)
                    }
                }
            }

            Section("Numbers per 100 g") {
                Text("Energy \(number(check.values.energyKilojoulesPer100g)) kJ")
                Text("Protein \(number(check.values.proteinGramsPer100g)) g")
                Text("Sugars \(number(check.values.sugarsGramsPer100g)) g")
                Text("Saturated fat \(number(check.values.saturatedFatGramsPer100g)) g")
                Text("Sodium \(number(check.values.sodiumMilligramsPer100g)) mg")
                Text("Serving size \(number(check.values.servingSizeGrams)) g")
            }
        }
        .navigationTitle(check.productName)
    }

    private func number(_ value: Double) -> String {
        return value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

// Colours and icons for each verdict, used by the History and Compare screens.
extension Verdict {
    var color: Color {
        switch self {
        case .suitable: return .green
        case .caution: return .orange
        case .notSuitable: return .red
        }
    }

    var iconName: String {
        switch self {
        case .suitable: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .notSuitable: return "xmark.octagon.fill"
        }
    }
}
