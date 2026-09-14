@MainActor
final class FakeClipboardReader: ClipboardReader {
    private(set) var changeCount = 1
    private var reading = ClipboardReading(text: nil)

    /// Stands in for a copy made in another app.
    func copy(_ text: String) {
        reading = ClipboardReading(text: text)
        changeCount += 1
    }

    func read() -> ClipboardReading { reading }

    func write(_ text: String) {
        copy(text)
    }
}
