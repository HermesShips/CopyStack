import AppKit

/// The second floating window of ADR 0002.
@MainActor
final class PreviewPanel {
    private static let cornerRadius: CGFloat = 8
    private static let inset: CGFloat = 10
    private static let gap: CGFloat = 8

    private let panel: NSPanel
    private let field = NSTextField(labelWithString: "")
    private let padding: CGFloat
    private let advance: CGFloat

    init() {
        let font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        field.font = font
        field.maximumNumberOfLines = 0
        // PreviewText does the wrapping; a wide glyph (emoji, CJK) is clipped, not rewrapped.
        field.lineBreakMode = .byClipping
        // The label pads its text.
        padding = field.fittingSize.width
        advance = ("0" as NSString).size(withAttributes: [.font: font]).width

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = Self.makeContentView(around: field)
    }

    var isVisible: Bool { panel.isVisible }

    func show(_ text: String, leftOf panelFrame: NSRect, topAt top: CGFloat, on screen: NSScreen?) {
        // Never wider than the Panel.
        let maxWidth = panelFrame.width
        let columns = Int((maxWidth - 2 * Self.inset - padding) / advance)
        field.stringValue = PreviewText.from(text, columns: columns)
        panel.setContentSize(size(maxWidth: maxWidth))
        panel.setFrameTopLeftPoint(origin(leftOf: panelFrame, topAt: top, on: screen))
        panel.orderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func size(maxWidth: CGFloat) -> NSSize {
        let text = field.fittingSize
        return NSSize(
            width: min(text.width + 2 * Self.inset, maxWidth),
            height: text.height + 2 * Self.inset
        )
    }

    private func origin(leftOf panelFrame: NSRect, topAt top: CGFloat, on screen: NSScreen?) -> NSPoint {
        let width = panel.frame.width
        var x = panelFrame.minX - Self.gap - width
        var y = top
        if let visible = screen?.visibleFrame {
            if x < visible.minX {
                x = min(panelFrame.maxX + Self.gap, visible.maxX - width)
            }
            y = min(y, visible.maxY)
            y = max(y, visible.minY + panel.frame.height)
        }
        return NSPoint(x: x, y: y)
    }

    private static func makeContentView(around field: NSView) -> NSView {
        let effect = BlurredBox.make(cornerRadius: cornerRadius)

        field.translatesAutoresizingMaskIntoConstraints = false
        effect.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: effect.leadingAnchor, constant: inset),
            field.trailingAnchor.constraint(equalTo: effect.trailingAnchor, constant: -inset),
            field.topAnchor.constraint(equalTo: effect.topAnchor, constant: inset),
            field.bottomAnchor.constraint(equalTo: effect.bottomAnchor, constant: -inset),
        ])
        return effect
    }
}
