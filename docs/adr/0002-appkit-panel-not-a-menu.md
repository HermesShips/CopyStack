# An AppKit panel, not a menu and not SwiftUI

The drop-down is an `NSPanel`, not an `NSMenu`: a menu has no fixed-height scrolling viewport, and the reference design (Control Center's Wi-Fi list) scrolls inside a bounded list.

It is AppKit throughout rather than a SwiftUI mix because the hover preview is a second floating window positioned outside the panel — AppKit work under either design. SwiftUI would save code only on the row views and the Preferences form, which does not pay for two layout systems bridged by `NSHostingView`.
