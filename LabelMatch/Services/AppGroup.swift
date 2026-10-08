import Foundation

/// The App Group shared by the app, the widget and the Share Extension.
enum AppGroup {
    static let identifier = "group.com.diganta.labelmatch"

    /// The shared folder. If the App Group is not set up yet, this falls back
    /// to the app's own Documents folder so the app never crashes.
    static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return url
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// The Core Data store file.
    static var storeURL: URL {
        return containerURL.appendingPathComponent("LabelMatch.sqlite")
    }

    /// Label photos from the Share Extension wait in this folder.
    static var inboxURL: URL {
        return containerURL.appendingPathComponent("Inbox", isDirectory: true)
    }
}
