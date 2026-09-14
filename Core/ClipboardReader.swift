/// The app's only touch point for the system pasteboard, so a test can swap it.
@MainActor
protocol ClipboardReader: AnyObject {
    var changeCount: Int { get }

    /// Reports only; every capture rule lives in History.
    func read() -> ClipboardReading

    func write(_ text: String)
}
