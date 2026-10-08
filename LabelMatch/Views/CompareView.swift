import SwiftUI

/// Screen: compare two checks that were made against the same goal.
struct CompareView: View {
    @ObservedObject var viewModel: CompareViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.checks.isEmpty {
                        Text("No labels checked yet. Check two labels on the Check tab, then come back to compare them.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.checks) { check in
                        Button {
                            viewModel.toggle(check)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: viewModel.isSelected(check) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(.teal)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(check.productName)
                                        .foregroundStyle(.primary)
                                    Text("\(check.verdict.title) for \(check.goalNameAtCheck)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Pick two checks")
                } footer: {
                    Text("Both checks must have been judged against the same goal.")
                }

                Section {
                    Button("Compare the two") {
                        viewModel.compare()
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                if let result = viewModel.result {
                    resultSections(result)
                }
            }
            .navigationTitle("Compare")
            .onAppear {
                viewModel.load()
            }
        }
    }

    @ViewBuilder
    private func resultSections(_ result: ComparisonResult) -> some View {
        Section("Result") {
            Text(result.explanation)
                .bold()
        }

        Section {
            ForEach(result.lines, id: \.nutrientName) { line in
                HStack {
                    Text(line.nutrientName)
                    Spacer()
                    Text("\(format(line.firstValue)) \(line.unit)")
                        .frame(width: 90, alignment: .trailing)
                    Text("\(format(line.secondValue)) \(line.unit)")
                        .frame(width: 90, alignment: .trailing)
                }
            }
        } header: {
            HStack {
                Text("Per 100 g")
                Spacer()
                Text(name(at: 0))
                    .lineLimit(1)
                    .frame(width: 90, alignment: .trailing)
                Text(name(at: 1))
                    .lineLimit(1)
                    .frame(width: 90, alignment: .trailing)
            }
        }
    }

    private func name(at index: Int) -> String {
        let checks = viewModel.selectedChecks
        return index < checks.count ? checks[index].productName : ""
    }

    private func format(_ value: Double) -> String {
        return value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
