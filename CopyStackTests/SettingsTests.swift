import Foundation
import Testing

private func freshSettings() -> Settings {
    let suite = "CopyStackTests-\(UUID().uuidString)"
    return Settings(defaults: UserDefaults(suiteName: suite)!)
}

@Test func captureIsNotPausedByDefault() {
    #expect(!freshSettings().isPaused)
}

@Test func aPauseIsStored() {
    let settings = freshSettings()

    settings.isPaused = true

    #expect(settings.isPaused)
}
