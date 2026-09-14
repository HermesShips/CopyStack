import AppKit

/// An `NSPanel`, not a menu — see ADR 0002.
@MainActor
final class PanelController: NSObject {
    private static let width: CGFloat = 360
    private static let rowHeight: CGFloat = 24
    private static let visibleRows = 10
    private static let emptyHeight: CGFloat = 44
    private static let stripHeight: CGFloat = 32
    private static let cornerRadius: CGFloat = 10
    private static let edgeInset: CGFloat = 8
    private static let deleteButtonSize: CGFloat = 16
    private static let crossPointSize: CGFloat = 9
    private static let gapBelowMenuBar: CGFloat = 4

    private let panel: ClipPanel
    private let tableView = HoverTableView()
    private let emptyLabel = NSTextField(labelWithString: "No clips yet")
    private let gear = NSButton()
    private let onPick: (Clip) -> Void
    private let onDelete: (Clip) -> Void
    private let onPreferences: () -> Void
    private var clips: [Clip] = []
    private let previews: PreviewCoordinator

    init(
        onPick: @escaping (Clip) -> Void,
        onDelete: @escaping (Clip) -> Void,
        onPreferences: @escaping () -> Void
    ) {
        self.onPick = onPick
        self.onDelete = onDelete
        self.onPreferences = onPreferences

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("clip"))
        column.width = Self.width
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        // The default spacing makes the table wider than the panel.
        tableView.intercellSpacing = .zero
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.headerView = nil
        tableView.rowHeight = Self.rowHeight
        tableView.style = .plain
        // Anything opaque here paints over the blur.
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        emptyLabel.textColor = .secondaryLabelColor

        panel = ClipPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.width, height: Self.height(forClipCount: 0)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        // The blur reads as grey behind an opaque window.
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = Self.makeContentView(list: scrollView, emptyLabel: emptyLabel, gear: gear)
        // Tracking areas need it before the pointer ever enters the table.
        panel.acceptsMouseMovedEvents = true
        previews = PreviewCoordinator(tableView: tableView, panel: panel)

        super.init()

        previews.textForRow = { [weak self] row in
            guard let self, clips.indices.contains(row) else { return nil }
            return clips[row].text
        }
        tableView.onPointerMove = { [weak self] point in self?.previews.pointerMoved(to: point) }

        gear.target = self
        gear.action = #selector(gearClicked)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.action = #selector(rowClicked)
        panel.onCancel = { [weak self] in self?.hide() }
        // Clicking outside lands in another app, which drops us from active.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hide),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    func toggle(_ clips: [Clip], below button: NSStatusBarButton) {
        if panel.isVisible {
            hide()
        } else {
            show(clips, below: button)
        }
    }

    @objc func hide() {
        previews.stop()
        guard panel.isVisible else { return }
        close()
        // Hand focus back, or the user's ⌘V lands on CopyStack.
        if NSApp.isActive { NSApp.hide(nil) }
    }

    /// Not hide(): that hands focus away, which something else is about to take.
    func close() {
        previews.stop()
        panel.orderOut(nil)
    }

    func update(_ clips: [Clip]) {
        previews.stop()
        guard panel.isVisible else { return }
        let top = panel.frame.maxY
        fill(clips)
        // Resizing holds the bottom edge, which would walk the panel up the screen.
        panel.setFrameTopLeftPoint(NSPoint(x: panel.frame.minX, y: top))
    }

    private func show(_ clips: [Clip], below button: NSStatusBarButton) {
        fill(clips)
        // A reopened panel keeps its old offset, which hides the newest clip.
        tableView.scroll(.zero)
        panel.setFrameOrigin(origin(below: button))

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func fill(_ clips: [Clip]) {
        self.clips = clips
        tableView.reloadData()
        emptyLabel.isHidden = !clips.isEmpty
        panel.setContentSize(NSSize(width: Self.width, height: Self.height(forClipCount: clips.count)))
    }

    private static func height(forClipCount count: Int) -> CGFloat {
        let listHeight = count == 0 ? emptyHeight : CGFloat(min(count, visibleRows)) * rowHeight
        return listHeight + stripHeight
    }

    private func origin(below button: NSStatusBarButton) -> NSPoint {
        guard let window = button.window else { return .zero }
        let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        var x = buttonFrame.midX - panel.frame.width / 2
        if let screen = window.screen {
            x = min(x, screen.visibleFrame.maxX - panel.frame.width)
            x = max(x, screen.visibleFrame.minX)
        }
        return NSPoint(x: x, y: buttonFrame.minY - panel.frame.height - Self.gapBelowMenuBar)
    }

    @objc private func gearClicked() {
        close()
        onPreferences()
    }

    @objc private func rowClicked() {
        guard clips.indices.contains(tableView.clickedRow) else { return }
        onPick(clips[tableView.clickedRow])
    }

    @objc private func deleteClicked(_ sender: NSButton) {
        let row = tableView.row(for: sender)
        guard clips.indices.contains(row) else { return }
        onDelete(clips[row])
    }
}

extension PanelController {
    private static func makeContentView(list: NSView, emptyLabel: NSView, gear: NSButton) -> NSView {
        let effect = BlurredBox.make(cornerRadius: cornerRadius)

        let strip = makeStrip(gear: gear)
        for view in [list, emptyLabel, strip] {
            view.translatesAutoresizingMaskIntoConstraints = false
            effect.addSubview(view)
        }
        NSLayoutConstraint.activate([
            // Without it the window sizes its width from the constraints, and collapses.
            effect.widthAnchor.constraint(equalToConstant: width),

            list.topAnchor.constraint(equalTo: effect.topAnchor),
            list.leadingAnchor.constraint(equalTo: effect.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: effect.trailingAnchor),
            list.bottomAnchor.constraint(equalTo: strip.topAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: list.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: list.centerYAnchor),

            strip.leadingAnchor.constraint(equalTo: effect.leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: effect.trailingAnchor),
            strip.bottomAnchor.constraint(equalTo: effect.bottomAnchor),
            strip.heightAnchor.constraint(equalToConstant: stripHeight),
        ])
        return effect
    }

    private static func makeStrip(gear: NSButton) -> NSView {
        let strip = NSView()

        let separator = NSBox()
        separator.boxType = .separator

        gear.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Preferences")
        gear.imagePosition = .imageOnly
        gear.isBordered = false
        gear.contentTintColor = .secondaryLabelColor

        for view in [separator, gear] {
            view.translatesAutoresizingMaskIntoConstraints = false
            strip.addSubview(view)
        }
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: strip.topAnchor),
            separator.leadingAnchor.constraint(equalTo: strip.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: strip.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            gear.trailingAnchor.constraint(equalTo: strip.trailingAnchor, constant: -edgeInset),
            gear.centerYAnchor.constraint(equalTo: strip.centerYAnchor),
        ])
        return strip
    }

    private func makeRowCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let field = NSTextField(labelWithString: "")
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail

        let delete = NSButton()
        delete.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Delete clip")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: Self.crossPointSize, weight: .light))
        delete.imagePosition = .imageOnly
        delete.isBordered = false
        delete.contentTintColor = .secondaryLabelColor
        delete.target = self
        delete.action = #selector(deleteClicked)
        // A long clip must give way, not the cross.
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let glyphMargin = (Self.deleteButtonSize - (delete.image?.size.width ?? Self.deleteButtonSize)) / 2

        let cell = NSTableCellView()
        cell.identifier = identifier
        for view in [field, delete] {
            view.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(view)
        }
        cell.textField = field
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: Self.edgeInset),
            field.trailingAnchor.constraint(equalTo: delete.leadingAnchor, constant: -6),
            field.centerYAnchor.constraint(equalTo: cell.centerYAnchor),

            // The glyph, not the wider click area, sits at the edge inset.
            delete.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -Self.edgeInset + glyphMargin),
            delete.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            delete.widthAnchor.constraint(equalToConstant: Self.deleteButtonSize),
            delete.heightAnchor.constraint(equalToConstant: Self.deleteButtonSize),
        ])
        return cell
    }
}

extension PanelController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        clips.count
    }
}

extension PanelController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        HoverRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("clipRow")
        let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
            ?? makeRowCell(identifier: identifier)
        cell.textField?.stringValue = RowText.from(clips[row].text)
        return cell
    }
}

private final class HoverRowView: NSTableRowView {
    private var isHovered = false {
        didSet { needsDisplay = true }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func drawBackground(in dirtyRect: NSRect) {
        guard isHovered else { return }
        NSColor.unemphasizedSelectedContentBackgroundColor.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 1), xRadius: 5, yRadius: 5).fill()
    }
}

/// Reports the pointer by position: crossing rows is one event, not an exit and an enter.
private final class HoverTableView: NSTableView {
    var onPointerMove: ((NSPoint?) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseMoved(with event: NSEvent) {
        onPointerMove?(event.locationInWindow)
    }

    override func mouseExited(with event: NSEvent) {
        onPointerMove?(nil)
    }
}

/// A borderless panel takes key status only if it says so, and Esc must reach us.
private final class ClipPanel: NSPanel {
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
