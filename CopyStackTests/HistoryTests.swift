import Testing

@Test func aTextReadingBecomesAClip() {
    let history = History().capturing(ClipboardReading(text: "ssh anubis@box"))

    #expect(history.clips.map(\.text) == ["ssh anubis@box"])
}

@Test func theNewestClipSitsAtTheTop() {
    let history = History()
        .capturing(ClipboardReading(text: "first"))
        .capturing(ClipboardReading(text: "second"))
        .capturing(ClipboardReading(text: "third"))

    #expect(history.clips.map(\.text) == ["third", "second", "first"])
}

@Test func aNonTextReadingIsAnExcludedCopy() {
    let history = History().capturing(ClipboardReading(text: nil))

    #expect(history.clips.isEmpty)
}

@Test func aConcealedReadingIsAnExcludedCopy() {
    let history = History().capturing(ClipboardReading(text: "hunter2", isConcealed: true))

    #expect(history.clips.isEmpty)
}

@Test func aReadingOverOneHundredKilobytesIsAnExcludedCopy() {
    let atTheLimit = String(repeating: "x", count: 100 * 1024)
    let overIt = atTheLimit + "x"

    #expect(History().capturing(ClipboardReading(text: atTheLimit)).clips.count == 1)
    #expect(History().capturing(ClipboardReading(text: overIt)).clips.isEmpty)
}

@Test func anExcludedCopyIsDroppedWholeAndNeverShortened() {
    let history = History()
        .capturing(ClipboardReading(text: "swiftc --version"))
        .capturing(ClipboardReading(text: String(repeating: "x", count: 200 * 1024)))

    #expect(history.clips.map(\.text) == ["swiftc --version"])
}

@Test func copyingTextAgainMovesItsClipToTheTopAndAddsNoRow() {
    let history = History()
        .capturing(ClipboardReading(text: "first"))
        .capturing(ClipboardReading(text: "second"))
        .capturing(ClipboardReading(text: "first"))

    #expect(history.clips.map(\.text) == ["first", "second"])
}

@Test func theHistoryStopsAtTwentyFiveClipsAndDropsTheOldest() {
    var history = History()
    for number in 1...30 {
        history = history.capturing(ClipboardReading(text: "clip \(number)"))
    }

    #expect(history.clips.count == 25)
    #expect(history.clips.first?.text == "clip 30")
    #expect(history.clips.last?.text == "clip 6")
}

@Test func aSmallerRetainedCountHoldsFewerClips() {
    var history = History(retained: 3)
    for number in 1...5 {
        history = history.capturing(ClipboardReading(text: "clip \(number)"))
    }

    #expect(history.clips.map(\.text) == ["clip 5", "clip 4", "clip 3"])
}

@Test func aLoadedHistoryNeverExceedsTheRetainedCount() {
    let history = History(retained: 2, clips: [Clip(text: "a"), Clip(text: "b"), Clip(text: "c")])

    #expect(history.clips.map(\.text) == ["a", "b"])
}

@Test func deletingOneClipLeavesTheOthersInOrder() {
    let history = History(clips: [Clip(text: "a"), Clip(text: "b"), Clip(text: "c")])

    #expect(history.deleting(Clip(text: "b")).clips.map(\.text) == ["a", "c"])
}

@Test func aLoweredRetainedCountTrimsTheHistoryAtOnce() {
    var history = History()
    for number in 1...5 {
        history = history.capturing(ClipboardReading(text: "clip \(number)"))
    }

    let trimmed = history.retaining(2)

    #expect(trimmed.retained == 2)
    #expect(trimmed.clips.map(\.text) == ["clip 5", "clip 4"])
}

@Test func clearingEmptiesTheHistoryAndKeepsTheRetainedCount() {
    let history = History(retained: 12, clips: [Clip(text: "a"), Clip(text: "b")])

    let cleared = history.cleared()

    #expect(cleared.clips.isEmpty)
    #expect(cleared.retained == 12)
}
