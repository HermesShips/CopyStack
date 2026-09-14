struct ClipboardReading: Equatable {
    /// Nil for a non-text copy.
    let text: String?
    let isConcealed: Bool

    init(text: String?, isConcealed: Bool = false) {
        self.text = text
        self.isConcealed = isConcealed
    }
}
