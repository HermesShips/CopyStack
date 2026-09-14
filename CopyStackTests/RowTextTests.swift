import Testing

@Test func aSingleLineClipIsUnchanged() {
    #expect(RowText.from("ssh anubis@box") == "ssh anubis@box")
}

@Test func aMultiLineClipYieldsItsFirstLineOnly() {
    #expect(RowText.from("git rebase -i main\r\nthen force push\nand tell the team") == "git rebase -i main")
}

@Test func aLineLongerThanTheRowIsCut() {
    let cut = RowText.from(String(repeating: "x", count: 200))

    #expect(cut.count == RowText.characterLimit)
    #expect(cut.hasSuffix("…"))
}
