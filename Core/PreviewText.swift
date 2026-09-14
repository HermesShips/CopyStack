enum PreviewText {
    static let lineLimit = 5
    static let wrappedLineLimit = 10
    static let tabWidth = 4

    static func from(_ text: String, columns: Int) -> String {
        // A tab counts as one column but draws as several.
        let text = text.replacingOccurrences(of: "\t", with: String(repeating: " ", count: tabWidth))
        var lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        // A trailing newline is not a line, and counting it can add a "…" promising nothing.
        if lines.count > 1, lines.last?.isEmpty == true { lines.removeLast() }
        let wrapped = lines.prefix(lineLimit).flatMap { wrap($0, columns: max(columns, 1)) }
        guard lines.count > lineLimit || wrapped.count > wrappedLineLimit else {
            return wrapped.joined(separator: "\n")
        }
        return (wrapped.prefix(wrappedLineLimit - 1) + ["…"]).joined(separator: "\n")
    }

    private static func wrap(_ line: Substring, columns: Int) -> [String] {
        guard !line.isEmpty else { return [""] }
        var rest = line
        var pieces: [String] = []
        while !rest.isEmpty {
            pieces.append(String(rest.prefix(columns)))
            rest = rest.dropFirst(columns)
        }
        return pieces
    }
}
