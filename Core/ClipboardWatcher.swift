import Foundation

/// Polls the clipboard, because macOS raises no change event.
@MainActor
final class ClipboardWatcher {
    private static let interval: TimeInterval = 0.5

    private let reader: ClipboardReader
    private let onCapture: (ClipboardReading) -> Void
    private var lastSeenChange: Int
    private var timer: Timer?
    var isPaused = false {
        // A copy made while paused must not be captured on resume.
        didSet { lastSeenChange = reader.changeCount }
    }

    init(reader: ClipboardReader, onCapture: @escaping (ClipboardReading) -> Void) {
        self.reader = reader
        self.onCapture = onCapture
        self.lastSeenChange = reader.changeCount
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: Self.interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        // .common, so an open menu or a drag does not stop capture.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func poll() {
        guard !isPaused, reader.changeCount != lastSeenChange else { return }
        lastSeenChange = reader.changeCount
        onCapture(reader.read())
    }

    /// Writing bumps the change counter, so swallow it or the app captures its own clip.
    func place(_ text: String) {
        reader.write(text)
        lastSeenChange = reader.changeCount
    }
}
