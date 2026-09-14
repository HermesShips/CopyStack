import Foundation

/// Anything it cannot read starts empty, so CopyStack never fails to start over its own data.
struct ClipStore {
    private static let version = 1
    private static let fileName = "clips.json"

    private let url: URL

    init(url: URL) {
        self.url = url
    }

    static func inContainer() -> ClipStore {
        let manager = FileManager.default
        let directory = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? manager.temporaryDirectory
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        return ClipStore(url: directory.appendingPathComponent(fileName))
    }

    func load() -> [Clip] {
        guard let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(StoredClips.self, from: data),
              file.version == Self.version else { return [] }
        return file.clips
    }

    func save(_ clips: [Clip]) {
        guard let data = try? JSONEncoder().encode(StoredClips(version: Self.version, clips: clips)) else { return }
        try? data.write(to: url, options: .atomic)
        // An atomic write makes a new file each time, so the permissions must be set again.
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}

private struct StoredClips: Codable {
    let version: Int
    let clips: [Clip]
}
