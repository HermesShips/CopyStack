import Testing

@MainActor
@Test func aCopyBecomesACapture() {
    let reader = FakeClipboardReader()
    var captured: [String?] = []
    let watcher = ClipboardWatcher(reader: reader) { captured.append($0.text) }

    reader.copy("git rebase -i")
    watcher.poll()

    #expect(captured == ["git rebase -i"])
}

@MainActor
@Test func onlyANewCopyIsCaptured() {
    let reader = FakeClipboardReader()
    var captured: [String?] = []
    let watcher = ClipboardWatcher(reader: reader) { captured.append($0.text) }

    reader.copy("xcodegen generate")
    watcher.poll()
    watcher.poll()
    watcher.poll()

    #expect(captured == ["xcodegen generate"])
}

@MainActor
@Test func whatIsAlreadyOnTheClipboardAtLaunchIsNotACopy() {
    let reader = FakeClipboardReader()
    reader.copy("copied before CopyStack started")
    var captured: [String?] = []
    let watcher = ClipboardWatcher(reader: reader) { captured.append($0.text) }

    watcher.poll()

    #expect(captured.isEmpty)
}

@MainActor
@Test func aClipPutBackOnTheClipboardIsNotCapturedAgain() {
    let reader = FakeClipboardReader()
    var captured: [String?] = []
    let watcher = ClipboardWatcher(reader: reader) { captured.append($0.text) }

    watcher.place("brew install xcodegen")
    watcher.poll()

    #expect(reader.read() == ClipboardReading(text: "brew install xcodegen"))
    #expect(captured.isEmpty)
}

@MainActor
@Test func aPausedWatcherCapturesNothing() {
    let reader = FakeClipboardReader()
    var captured: [String?] = []
    let watcher = ClipboardWatcher(reader: reader) { captured.append($0.text) }

    watcher.isPaused = true
    reader.copy("export API_KEY=secret")
    watcher.poll()

    #expect(captured.isEmpty)
}

@MainActor
@Test func aCopyMadeWhilePausedIsNotCapturedOnResume() {
    let reader = FakeClipboardReader()
    var captured: [String?] = []
    let watcher = ClipboardWatcher(reader: reader) { captured.append($0.text) }

    watcher.isPaused = true
    reader.copy("export API_KEY=secret")
    watcher.isPaused = false
    watcher.poll()
    reader.copy("git status")
    watcher.poll()

    #expect(captured == ["git status"])
}
