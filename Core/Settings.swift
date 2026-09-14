import Foundation

/// The retained count and the pause are settings, not history data.
struct Settings {
    static let retainedRange = 10...200
    private static let retainedKey = "retained"
    private static let isPausedKey = "isPaused"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var retained: Int {
        get {
            let stored = defaults.integer(forKey: Self.retainedKey)
            return stored == 0 ? History.defaultRetained : Self.clampedRetained(stored)
        }
        nonmutating set { defaults.set(Self.clampedRetained(newValue), forKey: Self.retainedKey) }
    }

    var isPaused: Bool {
        get { defaults.bool(forKey: Self.isPausedKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.isPausedKey) }
    }

    static func clampedRetained(_ count: Int) -> Int {
        min(max(count, retainedRange.lowerBound), retainedRange.upperBound)
    }
}
