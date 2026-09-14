import Testing

@Test func aShortClipIsUnchanged() {
    let clip = "ssh anubis@box\ncd /srv"

    #expect(PreviewText.from(clip, columns: 50) == clip)
}

@Test func aClipOverFiveLinesIsCutToFiveAndEndsWithAnEllipsis() {
    let clip = (1...9).map(String.init).joined(separator: "\n")

    #expect(PreviewText.from(clip, columns: 50) == "1\n2\n3\n4\n5\n…")
}

@Test func aLongLineWrapsAtTheColumns() {
    #expect(PreviewText.from("xxxx", columns: 4) == "xxxx")
    #expect(PreviewText.from("xxxxyyyyzz", columns: 4) == "xxxx\nyyyy\nzz")
}

@Test func aTabTakesFourColumns() {
    #expect(PreviewText.from("\tab", columns: 4) == "    \nab")
}

@Test func anEmptyLineStaysOneLine() {
    #expect(PreviewText.from("a\n\nb", columns: 4) == "a\n\nb")
}

@Test func tenWrappedLinesFitWithoutAnEllipsis() {
    let clip = String(repeating: "x", count: 20)

    #expect(PreviewText.from(clip, columns: 2) == Array(repeating: "xx", count: 10).joined(separator: "\n"))
}

@Test func overTenWrappedLinesKeepsNineAndEndsWithAnEllipsis() {
    let clip = String(repeating: "x", count: 21)

    #expect(PreviewText.from(clip, columns: 2) == (Array(repeating: "xx", count: 9) + ["…"]).joined(separator: "\n"))
}

@Test func theEllipsisCountsInsideTheTenLinesWhenFiveClipLinesAlsoOverflow() {
    let clip = (1...6).map { _ in "xxxx" }.joined(separator: "\n")

    let preview = PreviewText.from(clip, columns: 2)

    #expect(preview.split(separator: "\n", omittingEmptySubsequences: false).count == 10)
    #expect(preview.hasSuffix("\nxx\n…"))
}

@Test func aWindowsLineEndingLeavesNoStrayCharacter() {
    #expect(PreviewText.from("first\r\nsecond", columns: 50) == "first\nsecond")
}

@Test func aTrailingNewlineIsNotCountedAsALine() {
    #expect(PreviewText.from("cmd\n", columns: 50) == "cmd")
    #expect(PreviewText.from("1\n2\n3\n4\n5\n", columns: 50) == "1\n2\n3\n4\n5")
}
