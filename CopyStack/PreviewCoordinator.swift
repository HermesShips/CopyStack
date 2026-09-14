import AppKit

/// The hover machine: one pointer position in, one preview window out.
@MainActor
final class PreviewCoordinator {
    private static let delay: TimeInterval = 0.3

    /// Nil for a row the panel no longer holds.
    var textForRow: ((Int) -> String?)?

    private let preview = PreviewPanel()
    private let tableView: NSTableView
    private let panel: NSPanel
    private var trackedRow: Int?
    private var timer: Timer?

    init(tableView: NSTableView, panel: NSPanel) {
        self.tableView = tableView
        self.panel = panel
    }

    /// One event decides the whole move, so crossing rows can never close and reopen the window.
    func pointerMoved(to point: NSPoint?) {
        let row = rowUnder(point)
        guard row != trackedRow else { return }
        trackedRow = row
        timer?.invalidate()

        guard let row, wasCut(row) else { return preview.hide() }
        guard !preview.isVisible else { return show(row) }
        timer = Timer.scheduledTimer(withTimeInterval: Self.delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.show(row) }
        }
    }

    func stop() {
        timer?.invalidate()
        trackedRow = nil
        preview.hide()
    }

    private func rowUnder(_ point: NSPoint?) -> Int? {
        guard let point else { return nil }
        let row = tableView.row(at: tableView.convert(point, from: nil))
        return row >= 0 ? row : nil
    }

    private func show(_ row: Int) {
        guard let text = textForRow?(row) else { return }
        let rowFrame = tableView.convert(tableView.rect(ofRow: row), to: nil)
        preview.show(
            text,
            leftOf: panel.frame,
            topAt: panel.convertPoint(toScreen: NSPoint(x: 0, y: rowFrame.maxY)).y,
            on: panel.screen
        )
    }

    /// Both cuts count: `RowText` trims the string, then the field trims what is left to the pixels.
    private func wasCut(_ row: Int) -> Bool {
        guard let text = textForRow?(row) else { return false }
        if RowText.from(text) != text { return true }
        guard let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView,
              let field = cell.textField, let font = field.font else { return false }
        return (text as NSString).size(withAttributes: [.font: font]).width > field.bounds.width
    }
}
