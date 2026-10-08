import SwiftUI

/// Screen: the verdict and the reasons behind it.
struct VerdictView: View {
    @ObservedObject var viewModel: LabelCheckViewModel

    var body: some View {
        List {
            if let check = viewModel.result {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: icon(for: check.verdict))
                            .font(.system(size: 44))
                            .foregroundStyle(color(for: check.verdict))
                        Text(check.verdict.title)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(color(for: check.verdict))
                        Text(check.productName)
                            .font(.headline)
                        Text("Judged against: \(check.goalNameAtCheck)")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Why") {
                    if check.reasons.isEmpty {
                        Text("Nothing on this label breaks your goal.")
                    }
                    ForEach(check.reasons) { reason in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: icon(for: reason.severity))
                                .foregroundStyle(color(for: reason.severity))
                            Text(reason.message)
                        }
                    }
                }

                if !check.values.declaredAllergens.isEmpty {
                    Section("Allergens on the label") {
                        Text(check.values.declaredAllergens.joined(separator: ", "))
                    }
                }
            }

            Section {
                Button("Check another label") {
                    viewModel.startOver()
                }
            }
        }
        .navigationTitle("Verdict")
    }

    private func color(for verdict: Verdict) -> Color {
        switch verdict {
        case .suitable: return .green
        case .caution: return .orange
        case .notSuitable: return .red
        }
    }

    private func icon(for verdict: Verdict) -> String {
        switch verdict {
        case .suitable: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .notSuitable: return "xmark.octagon.fill"
        }
    }
}
