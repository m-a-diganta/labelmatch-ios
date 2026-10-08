import SwiftUI
import PhotosUI

/// Screen: pick a label photo, or open one that was shared to the app.
struct ImportLabelView: View {
    @ObservedObject var viewModel: LabelCheckViewModel
    @State private var pickedItem: PhotosPickerItem?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Form {
            Section {
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Label("Choose a label photo", systemImage: "photo")
                }
                Button {
                    viewModel.typeValuesManually()
                } label: {
                    Label("Type the numbers myself", systemImage: "keyboard")
                }
            } header: {
                Text("Photograph the Nutrition Information Panel")
            } footer: {
                Text("The photo is read on this phone. It is never uploaded.")
            }

            if viewModel.isReading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Reading the label...")
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Section("Shared to LabelMatch") {
                if viewModel.pendingFilenames.isEmpty {
                    Text("No shared photos are waiting. Share a label photo from Photos or Safari and it will appear here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.pendingFilenames, id: \.self) { filename in
                        Button {
                            viewModel.openSharedPhoto(named: filename)
                        } label: {
                            Label("Check a shared label", systemImage: "tray.and.arrow.down")
                        }
                    }
                }
            }
        }
        .navigationTitle("Check a label")
        .onAppear {
            viewModel.refreshInbox()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refreshInbox()
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                viewModel.beginReading()
                // A short pause so the "Reading" message can appear.
                try? await Task.sleep(nanoseconds: 100_000_000)
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    viewModel.readPhoto(data: data)
                } else {
                    viewModel.photoCouldNotBeOpened()
                }
                pickedItem = nil
            }
        }
    }
}
