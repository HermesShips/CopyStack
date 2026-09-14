import AppKit

@main
@MainActor
enum CopyStackApp {
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = ClipStore.inContainer()
    private let settings = Settings()
    private var history = History()
    private var watcher: ClipboardWatcher?
    private var statusItemController: StatusItemController?
    private var panelController: PanelController?
    private var preferencesController: PreferencesController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        history = History(retained: settings.retained, clips: store.load())

        let watcher = ClipboardWatcher(reader: SystemClipboardReader()) { [weak self] reading in
            guard let self else { return }
            update(history.capturing(reading))
        }
        watcher.start()
        self.watcher = watcher

        preferencesController = PreferencesController(
            onRetainedChange: { [weak self] retained in self?.retain(retained) },
            onClear: { [weak self] in self?.clearHistory() },
            onPauseChange: { [weak self] paused in self?.setPaused(paused) }
        )
        panelController = PanelController(
            onPick: { [weak self] clip in self?.pick(clip) },
            onDelete: { [weak self] clip in self?.delete(clip) },
            onPreferences: { [weak self] in self?.showPreferences() }
        )
        statusItemController = StatusItemController(
            onLeftClick: { [weak self] button in self?.togglePanel(from: button) },
            // Hiding the app while the menu opens dismisses the menu, so focus goes back after it.
            onMenuOpen: { [weak self] in self?.panelController?.close() },
            onMenuClose: { [weak self] in self?.handFocusBack() }
        )
        setPaused(settings.isPaused)
    }

    /// The one route that changes the history, so nothing can change it without saving.
    private func update(_ next: History) {
        guard next != history else { return }
        history = next
        store.save(next.clips)
        panelController?.update(next.clips)
    }

    private func togglePanel(from button: NSStatusBarButton) {
        panelController?.toggle(history.clips, below: button)
    }

    private func handFocusBack() {
        guard NSApp.isActive, preferencesController?.isVisible != true else { return }
        NSApp.hide(nil)
    }

    private func pick(_ clip: Clip) {
        watcher?.place(clip.text)
        panelController?.hide()
    }

    private func delete(_ clip: Clip) {
        update(history.deleting(clip))
    }

    private func showPreferences() {
        preferencesController?.show(retained: history.retained, isPaused: settings.isPaused)
    }

    private func retain(_ count: Int) {
        settings.retained = count
        update(history.retaining(count))
    }

    private func setPaused(_ paused: Bool) {
        settings.isPaused = paused
        watcher?.isPaused = paused
        statusItemController?.showPaused(paused)
    }

    private func clearHistory() {
        update(history.cleared())
    }
}
