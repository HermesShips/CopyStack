import Foundation
import Testing

private func temporaryFile() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("CopyStackTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("clips.json")
}

@Test func savedClipsLoadBackInTheSameOrder() throws {
    let store = ClipStore(url: try temporaryFile())
    let clips = [Clip(text: "third"), Clip(text: "second"), Clip(text: "first")]

    store.save(clips)

    #expect(store.load() == clips)
}

@Test func aMissingFileLoadsAnEmptyHistory() throws {
    #expect(ClipStore(url: try temporaryFile()).load().isEmpty)
}

@Test func aDamagedFileLoadsAnEmptyHistory() throws {
    let url = try temporaryFile()
    try Data("this is not JSON".utf8).write(to: url)

    #expect(ClipStore(url: url).load().isEmpty)
}

@Test func aFileFromAnUnknownVersionLoadsAnEmptyHistory() throws {
    let url = try temporaryFile()
    try Data(#"{"version": 99, "clips": [{"text": "from the future"}]}"#.utf8).write(to: url)

    #expect(ClipStore(url: url).load().isEmpty)
}

@Test func theFileRecordsAVersionAndStoresEachClipAsAnObject() throws {
    let url = try temporaryFile()
    ClipStore(url: url).save([Clip(text: "ssh anubis@box")])

    let json = try JSONSerialization.jsonObject(with: try Data(contentsOf: url)) as? [String: Any]

    #expect(json?["version"] as? Int == 1)
    #expect((json?["clips"] as? [[String: Any]])?.first?["text"] as? String == "ssh anubis@box")
}
