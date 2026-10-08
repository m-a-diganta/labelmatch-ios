import UIKit
import UniformTypeIdentifiers

/// Receives a label photo from the share sheet.
/// It copies the photo into the App Group Inbox folder and closes.
/// It never reads the text and never opens the Core Data store.
final class ShareViewController: UIViewController {

    private let messageLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        messageLabel.text = "Saving the label to LabelMatch..."
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24)
        ])

        savePhoto()
    }

    private func savePhoto() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first(where: {
                  $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
              }) else {
            finish(message: "There was no photo to save.")
            return
        }

        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
            var saved = false
            if let url = url {
                saved = self.copyToInbox(url)
            }
            DispatchQueue.main.async {
                if saved {
                    self.finish(message: "Saved. Open LabelMatch to check it.")
                } else {
                    self.finish(message: "I couldn't save that photo. Try sharing it again.")
                }
            }
        }
    }

    // The temporary file only lives during this call, so we copy it straight away.
    nonisolated private func copyToInbox(_ source: URL) -> Bool {
        // Same App Group as the main app.
        let groupID = "group.com.diganta.labelmatch"
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            return false
        }
        let inbox = container.appendingPathComponent("Inbox", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
            let ext = source.pathExtension.isEmpty ? "jpg" : source.pathExtension
            let name = "label-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString.prefix(6)).\(ext)"
            try FileManager.default.copyItem(at: source, to: inbox.appendingPathComponent(name))
            return true
        } catch {
            return false
        }
    }

    // Show the result for a moment, then close the share sheet.
    private func finish(message: String) {
        messageLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
