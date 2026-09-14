# Set the clipboard; do not paste

Picking a clip writes it to the pasteboard and stops there — the user presses ⌘V. Auto-paste means synthesising a keystroke into the frontmost app, which needs Accessibility permission and puts CopyStack outside the sandbox. Sandboxed costs nothing else: CopyClip ships every screen we copied from with only `app-sandbox` and `network.client`.

## Consequences

An ad-hoc-signed build loses its Accessibility grant on every rebuild. Adding auto-paste later costs a re-approval per dev cycle, not just an entitlement.
