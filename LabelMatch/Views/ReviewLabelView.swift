import SwiftUI

/// Screen: check and correct the numbers that were read.
/// Nothing is judged until the shopper confirms.
struct ReviewLabelView: View {
    @ObservedObject var viewModel: LabelCheckViewModel

    var body: some View {
        Form {
            Section("Product") {
                TextField("Product name", text: $viewModel.productName)
            }

            Section {
                numberRow("Energy (kJ)", text: $viewModel.energyText)
                numberRow("Protein (g)", text: $viewModel.proteinText)
                numberRow("Sugars (g)", text: $viewModel.sugarsText)
                numberRow("Saturated fat (g)", text: $viewModel.saturatedFatText)
                numberRow("Sodium (mg)", text: $viewModel.sodiumText)
            } header: {
                Text("Numbers per 100 g")
            } footer: {
                Text("Check each number against the label and correct anything that was misread.")
            }

            Section("Serving") {
                numberRow("Serving size (g)", text: $viewModel.servingSizeText)
            }

            Section("Allergens declared on the label") {
                TextField("For example peanuts, milk", text: $viewModel.allergensText)
            }

            Section {
                Button("Check against my goal") {
                    viewModel.assess()
                }
                Button("Start over") {
                    viewModel.startOver()
                }
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Review the numbers")
    }

    private func numberRow(_ title: String, text: Binding<String>) -> some View {
        LabeledContent(title) {
            TextField("Type a number", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
