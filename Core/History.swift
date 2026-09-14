/// Every capture rule lives here, and it reaches no system service.
struct History: Equatable {
    static let defaultRetained = 25
    private static let excludedAboveBytes = 100 * 1024

    let retained: Int
    private(set) var clips: [Clip] = []

    init(retained: Int = defaultRetained, clips: [Clip] = []) {
        self.retained = retained
        self.clips = Array(clips.prefix(retained))
    }

    func capturing(_ reading: ClipboardReading) -> History {
        guard let text = reading.text, !reading.isConcealed,
              text.utf8.count <= Self.excludedAboveBytes else { return self }
        var next = clips
        next.removeAll { $0.text == text }
        next.insert(Clip(text: text), at: 0)
        return History(retained: retained, clips: next)
    }

    func deleting(_ clip: Clip) -> History {
        History(retained: retained, clips: clips.filter { $0 != clip })
    }

    func retaining(_ count: Int) -> History {
        History(retained: count, clips: clips)
    }

    func cleared() -> History {
        History(retained: retained)
    }
}
