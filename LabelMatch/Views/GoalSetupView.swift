import SwiftUI

/// Screen: choose and edit the goal you are following.
struct GoalSetupView: View {
    @ObservedObject var viewModel: GoalSetupViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    Picker("Goal type", selection: kindBinding) {
                        ForEach(GoalKind.allCases, id: \.self) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    TextField("Goal name", text: $viewModel.name)
                }

                Section("Targets and limits (leave empty for none)") {
                    numberRow("Protein per serve, at least (g)", text: $viewModel.proteinText)
                    numberRow("Energy per serve, at most (kJ)", text: $viewModel.energyText)
                    numberRow("Sugars per 100 g, at most (g)", text: $viewModel.sugarText)
                    numberRow("Saturated fat per 100 g, at most (g)", text: $viewModel.saturatedFatText)
                    numberRow("Sodium per 100 g, at most (mg)", text: $viewModel.sodiumText)
                }

                Section("Allergens to avoid") {
                    TextField("For example peanut, milk", text: $viewModel.allergensText)
                }

                Section {
                    Button("Save as my active goal") {
                        viewModel.save()
                    }
                    if let message = viewModel.statusMessage {
                        Text(message)
                            .foregroundStyle(.teal)
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Goals")
            .onAppear {
                viewModel.loadIfNeeded()
            }
        }
    }

    private var kindBinding: Binding<GoalKind> {
        Binding(get: { viewModel.kind },
                set: { viewModel.chooseKind($0) })
    }

    private func numberRow(_ title: String, text: Binding<String>) -> some View {
        LabeledContent(title) {
            TextField("Not set", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
