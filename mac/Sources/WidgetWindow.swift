import Cocoa
import WebKit

/// A frameless, see-through window: only what the page draws (the device) is visible.
final class WidgetWindow: NSWindow {
    convenience init(size: NSSize) {
        self.init(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        collectionBehavior = [.fullScreenNone]
    }

    // Borderless windows can't take keyboard focus by default, which would make the task box untypeable.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// The web view that fills the window. When the page says the press landed on the shell (not a button),
/// dragging moves the whole window instead of selecting text.
final class DragWebView: WKWebView {
    var dragArmed = false
    var onDragStart: (() -> Void)?
    private var startMouse: NSPoint?
    private var startOrigin: NSPoint?
    private var dragging = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        startMouse = NSEvent.mouseLocation
        startOrigin = window?.frame.origin
        dragging = false
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragArmed, let startMouse, let startOrigin, let window else {
            super.mouseDragged(with: event)
            return
        }
        let now = NSEvent.mouseLocation
        if !dragging {
            guard abs(now.x - startMouse.x) + abs(now.y - startMouse.y) > 3 else { return }
            dragging = true
            onDragStart?()
        }
        window.setFrameOrigin(NSPoint(x: startOrigin.x + now.x - startMouse.x, y: startOrigin.y + now.y - startMouse.y))
    }

    override func mouseUp(with event: NSEvent) {
        dragArmed = false
        dragging = false
        super.mouseUp(with: event)
    }
}
