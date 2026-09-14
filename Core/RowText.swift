enum RowText {
    /// A guard above what 360 points holds, so the field does the visible cut.
    static let characterLimit = 60

    static func from(_ text: String) -> String {
        let firstLine = text.prefix(while: { !$0.isNewline })
        guard firstLine.count > characterLimit else { return String(firstLine) }
        return firstLine.prefix(characterLimit - 1) + "…"
    }
}
