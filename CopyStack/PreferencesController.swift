import AppKit

/// One window, no tabs.
@MainActor
final class PreferencesController: NSObject {
    private static let width: CGFloat = 320
    private static let margin: CGFloat = 20
    private static let fieldWidth: CGFloat = 56

    private let window: NSWindow
    private let retainedField = NSTextField()
    private let retainedStepper = NSStepper()
    private let loginCheckbox = NSButton(checkboxWithTitle: "Start \(AppInfo.displayName) at login", target: nil, action: nil)
    private let captureCheckbox = NSButton(checkboxWithTitle: "Record clipboard history", target: nil, action: nil)
    private let onRetainedChange: (Int) -> Void
    private let onClear: () -> Void
    private let onPauseChange: (Bool) -> Void

    init(
        onRetainedChange: @escaping (Int) -> Void,
        onClear: @escaping () -> Void,
        onPauseChange: @escaping (Bool) -> Void
    ) {
        self.onRetainedChange = onRetainedChange
        self.onClear = onClear
        self.onPauseChange = onPauseChange

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(AppInfo.displayName) Preferences"
        window.isReleasedWhenClosed = false
        // Without it the window opens on the space it was born in, not the one the user is on.
        window.collectionBehavior = [.moveToActiveSpace]

        super.init()

        window.contentView = makeContentView()
        window.center()
    }

    var isVisible: Bool { window.isVisible }

    func show(retained: Int, isPaused: Bool) {
        retainedStepper.integerValue = retained
        retainedField.integerValue = retained
        // Read each time: the user can remove the login item in System Settings.
        loginCheckbox.state = LoginItem.isEnabled ? .on : .off
        captureCheckbox.state = isPaused ? .off : .on
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeContentView() -> NSView {
        loginCheckbox.target = self
        loginCheckbox.action = #selector(loginCheckboxChanged)
        captureCheckbox.target = self
        captureCheckbox.action = #selector(captureCheckboxChanged)

        retainedField.alignment = .right
        retainedField.formatter = Self.makeRetainedFormatter()
        retainedField.target = self
        retainedField.action = #selector(retainedFieldChanged)

        retainedStepper.minValue = Double(Settings.retainedRange.lowerBound)
        retainedStepper.maxValue = Double(Settings.retainedRange.upperBound)
        retainedStepper.increment = 1
        retainedStepper.valueWraps = false
        retainedStepper.target = self
        retainedStepper.action = #selector(retainedStepperChanged)

        let retainedRow = NSStackView(views: [
            NSTextField(labelWithString: "Clips retained:"),
            retainedField,
            retainedStepper,
        ])
        retainedRow.spacing = 8

        let deleteButton = NSButton(
            title: "Delete All History",
            target: self,
            action: #selector(deleteAllClicked)
        )

        let version = NSTextField(labelWithString: Self.versionText)
        version.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        version.textColor = .secondaryLabelColor

        let quitButton = NSButton(
            title: "Quit",
            target: NSApp,
            action: #selector(NSApplication.terminate(_:))
        )

        let content = NSView()
        for view in [loginCheckbox, captureCheckbox, retainedRow, deleteButton, version, quitButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }
        NSLayoutConstraint.activate([
            content.widthAnchor.constraint(equalToConstant: Self.width),

            loginCheckbox.topAnchor.constraint(equalTo: content.topAnchor, constant: Self.margin),
            loginCheckbox.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Self.margin),

            captureCheckbox.topAnchor.constraint(equalTo: loginCheckbox.bottomAnchor, constant: 8),
            captureCheckbox.leadingAnchor.constraint(equalTo: loginCheckbox.leadingAnchor),

            retainedRow.topAnchor.constraint(equalTo: captureCheckbox.bottomAnchor, constant: Self.margin),
            retainedRow.leadingAnchor.constraint(equalTo: loginCheckbox.leadingAnchor),
            retainedField.widthAnchor.constraint(equalToConstant: Self.fieldWidth),

            deleteButton.topAnchor.constraint(equalTo: retainedRow.bottomAnchor, constant: Self.margin),
            deleteButton.leadingAnchor.constraint(equalTo: retainedRow.leadingAnchor),

            quitButton.topAnchor.constraint(equalTo: deleteButton.bottomAnchor, constant: Self.margin),
            quitButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Self.margin),
            quitButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Self.margin),

            version.leadingAnchor.constraint(equalTo: retainedRow.leadingAnchor),
            version.firstBaselineAnchor.constraint(equalTo: quitButton.firstBaselineAnchor),
        ])
        return content
    }

    private static func makeRetainedFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = NSNumber(value: Settings.retainedRange.lowerBound)
        formatter.maximum = NSNumber(value: Settings.retainedRange.upperBound)
        return formatter
    }

    private static var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Version \(version ?? "unknown")"
    }

    @objc private func loginCheckboxChanged() {
        do {
            try LoginItem.set(loginCheckbox.state == .on)
        } catch {
            NSAlert(error: error).beginSheetModal(for: window)
        }
        // A login item awaiting approval in System Settings does not start the app yet.
        loginCheckbox.state = LoginItem.isEnabled ? .on : .off
    }

    @objc private func captureCheckboxChanged() {
        onPauseChange(captureCheckbox.state == .off)
    }

    @objc private func retainedStepperChanged() {
        apply(retainedStepper.integerValue)
    }

    @objc private func retainedFieldChanged() {
        apply(retainedField.integerValue)
    }

    private func apply(_ retained: Int) {
        let clamped = Settings.clampedRetained(retained)
        retainedField.integerValue = clamped
        retainedStepper.integerValue = clamped
        onRetainedChange(clamped)
    }

    @objc private func deleteAllClicked() {
        let alert = NSAlert()
        alert.messageText = "Delete all clips?"
        alert.informativeText = "The whole history goes, and it cannot be brought back."
        alert.addButton(withTitle: "Delete All History")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            self?.onClear()
        }
    }
}
