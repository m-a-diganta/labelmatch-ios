import Foundation

/// Reads label photos from the App Group Inbox folder.
/// The Share Extension puts photos there.
struct FileSharedInboxRepository: SharedInboxRepository {
    let folderURL: URL

    init(folderURL: URL = AppGroup.inboxURL) {
        self.folderURL = folderURL
    }

    func pendingFilenames() throws -> [String] {
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let names = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
        return names.filter { !$0.hasPrefix(".") }.sorted()
    }

    func photoData(named filename: String) throws -> Data {
        return try Data(contentsOf: folderURL.appendingPathComponent(filename))
    }

    func removePhoto(named filename: String) throws {
        try FileManager.default.removeItem(at: folderURL.appendingPathComponent(filename))
    }
}
