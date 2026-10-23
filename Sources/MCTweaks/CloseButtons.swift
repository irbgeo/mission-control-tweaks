import AppKit
import MCKit

/// CloseButtons keeps one small "×" panel on the top-left corner of each Mission Control window.
@MainActor
final class CloseButtons {
    private var panels: [Int: NSPanel] = [:]

    func update(_ windows: [MCWindow]) {
        let wanted = Set(windows.map(\.wid))
        for (wid, panel) in panels where !wanted.contains(wid) {
            panel.orderOut(nil)
            panels[wid] = nil
        }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        for window in windows {
            let axRect = closeButtonRect(for: window.frame)
            let frame = cocoaRect(axRect, primaryHeight: primaryHeight)
            // Touch WindowServer only for new or moved buttons, not every tick.
            if let panel = panels[window.wid] {
                if panel.frame != frame {
                    panel.setFrame(frame, display: false)
                }
                continue
            }
            let panel = makePanel(wid: window.wid)
            panels[window.wid] = panel
            panel.setFrame(frame, display: false)
            panel.orderFrontRegardless()
        }
    }

    private func makePanel(wid: Int) -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        // Above the Mission Control layer drawn by Dock/WindowManager.
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.contentView = CloseButtonView(wid: wid)
        return panel
    }
}

private final class CloseButtonView: NSView {
    private let wid: Int

    init(wid: Int) {
        self.wid = wid
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        let circle = bounds.insetBy(dx: 1, dy: 1)
        NSColor(white: 0.15, alpha: 0.9).setFill()
        NSBezierPath(ovalIn: circle).fill()
        NSColor(white: 1, alpha: 0.6).setStroke()
        NSBezierPath(ovalIn: circle).stroke()

        let cross = NSBezierPath()
        let inset = bounds.insetBy(dx: 7, dy: 7)
        cross.move(to: NSPoint(x: inset.minX, y: inset.minY))
        cross.line(to: NSPoint(x: inset.maxX, y: inset.maxY))
        cross.move(to: NSPoint(x: inset.minX, y: inset.maxY))
        cross.line(to: NSPoint(x: inset.maxX, y: inset.minY))
        cross.lineWidth = 2
        NSColor.white.setStroke()
        cross.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        guard event.modifierFlags.contains(.option) else {
            closeWindow(wid: wid)
            return
        }

        let app = ownerApp(ofWindow: wid)
        app?.terminate()
    }
}
