import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let onLeftClick: (NSStatusBarButton) -> Void
    private let onMenuOpen: () -> Void
    private let onMenuClose: () -> Void

    init(
        onLeftClick: @escaping (NSStatusBarButton) -> Void,
        onMenuOpen: @escaping () -> Void,
        onMenuClose: @escaping () -> Void
    ) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.onLeftClick = onLeftClick
        self.onMenuOpen = onMenuOpen
        self.onMenuClose = onMenuClose
        super.init()

        guard let button = statusItem.button else { return }
        button.image = Self.icon(paused: false)
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    func showPaused(_ paused: Bool) {
        statusItem.button?.image = Self.icon(paused: paused)
    }

    private static func icon(paused: Bool) -> NSImage? {
        let description = paused ? "\(AppInfo.displayName), paused" : AppInfo.displayName
        guard let base = NSImage(systemSymbolName: "square.stack", accessibilityDescription: description) else {
            return nil
        }
        guard paused else {
            base.isTemplate = true
            return base
        }
        // SF Symbols has no square.stack.slash.
        let slashed = NSImage(size: base.size, flipped: false) { rect in
            base.draw(in: rect)
            let slash = NSBezierPath()
            slash.move(to: NSPoint(x: rect.minX + 1, y: rect.maxY - 1))
            slash.line(to: NSPoint(x: rect.maxX - 1, y: rect.minY + 1))
            slash.lineCapStyle = .round
            NSGraphicsContext.current?.compositingOperation = .clear
            slash.lineWidth = 3.5
            slash.stroke()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            NSColor.black.setStroke()
            slash.lineWidth = 1.5
            slash.stroke()
            return true
        }
        slashed.isTemplate = true
        slashed.accessibilityDescription = description
        return slashed
    }

    @objc private func statusItemClicked() {
        guard let button = statusItem.button, let event = NSApp.currentEvent else { return }
        // Control-click arrives as a left-up carrying .control, never as .rightMouseUp.
        let isSecondaryClick = event.type == .rightMouseUp
            || (event.type == .leftMouseUp && event.modifierFlags.contains(.control))
        if isSecondaryClick {
            onMenuOpen()
            showQuitMenu(from: button)
            // The menu swallows the click that dismisses it, so a left click on the icon is replayed here.
            if Self.isLeftClick(NSApp.currentEvent, on: button) {
                onLeftClick(button)
            } else {
                onMenuClose()
            }
        } else {
            onLeftClick(button)
        }
    }

    /// Attached only for this click: a menu left on the item would swallow every left click.
    private func showQuitMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(
            withTitle: "Quit \(AppInfo.displayName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusItem.menu = menu
        button.performClick(nil)
        statusItem.menu = nil
    }

    private static func isLeftClick(_ event: NSEvent?, on button: NSStatusBarButton) -> Bool {
        guard let event, event.type == .leftMouseUp, !event.modifierFlags.contains(.control),
              let window = button.window else { return false }
        return window.convertToScreen(button.convert(button.bounds, to: nil)).contains(NSEvent.mouseLocation)
    }
}
