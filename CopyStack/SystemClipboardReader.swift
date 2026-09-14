import AppKit

@MainActor
final class SystemClipboardReader: ClipboardReader {
    /// What a password manager marks its copies with.
    private static let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    private let pasteboard = NSPasteboard.general

    var changeCount: Int { pasteboard.changeCount }

    func read() -> ClipboardReading {
        ClipboardReading(
            text: pasteboard.string(forType: .string),
            isConcealed: pasteboard.pasteboardItems?.contains { $0.types.contains(Self.concealed) } ?? false
        )
    }

    func write(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
