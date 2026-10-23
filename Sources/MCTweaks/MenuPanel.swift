import AppKit
import MCKit

private let rowHeight: CGFloat = 24
private let separatorHeight: CGFloat = 11
private let padding: CGFloat = 5
private let minWidth: CGFloat = 110
@MainActor private let font = NSFont.menuFont(ofSize: 13)

/// MenuPanel is a menu-looking panel that, unlike NSMenu, does not grab the mouse:
/// the Dock keeps working and the next right-click reaches us at once.
@MainActor
final class MenuPanel {
    private let onClose: @MainActor () -> Void
    private var panel: NSPanel?

    /// onClose runs every time the menu closes, whatever closed it.
    init(
        onClose: @escaping @MainActor () -> Void
    ) {
        self.onClose = onClose
    }

    /// frame is the open menu's frame in Cocoa coordinates.
    var frame: CGRect? {
        panel?.frame
    }

    func show(_ rows: [MenuRow], at click: NSPoint) {
        close()

        let content = MenuContentView(rows: rows) { [weak self] action in
            self?.close()
            action()
        }
        let screen = NSScreen.screens.first { $0.frame.contains(click) } ?? NSScreen.main
        let placement = MenuPlacementInput(
            click: click,
            size: content.frame.size,
            screen: screen?.frame ?? .zero
        )
        let origin = menuOrigin(placement)
        let rect = NSRect(
            origin: origin,
            size: content.frame.size
        )

        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // One level above the × buttons, which sit at .popUpMenu.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.contentView = content
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func close() {
        guard let panel else {
            return
        }
        panel.orderOut(nil)
        self.panel = nil
        onClose()
    }
}

private final class MenuContentView: NSVisualEffectView {
    init(
        rows: [MenuRow],
        onPick: @escaping @MainActor (@escaping @MainActor () -> Void) -> Void
    ) {
        let titles = rows.compactMap(\.title)
        let widths = titles.map { ($0 as NSString).size(withAttributes: [.font: font]).width }
        let widestTitle = widths.max() ?? 0
        let width = max(minWidth, widestTitle + 2 * padding + 24)
        let heights = rows.map { $0.title == nil ? separatorHeight : rowHeight }
        let height = heights.reduce(2 * padding, +)
        let bounds = NSRect(
            x: 0,
            y: 0,
            width: width,
            height: height
        )
        super.init(frame: bounds)

        material = .menu
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true

        var top = height - padding
        for row in rows {
            let thisHeight = row.title == nil ? separatorHeight : rowHeight
            top -= thisHeight
            let frame = NSRect(
                x: padding,
                y: top,
                width: width - 2 * padding,
                height: thisHeight
            )
            // The row closes the menu first, then runs its action.
            let picked = MenuRow(title: row.title) {
                onPick(row.action)
            }
            let view = makeRowView(picked, frame: frame)
            addSubview(view)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    private func makeRowView(_ row: MenuRow, frame: NSRect) -> NSView {
        guard row.title != nil else {
            let separatorFrame = frame.insetBy(dx: 6, dy: 5)
            let separator = NSBox(frame: separatorFrame)
            separator.boxType = .separator
            return separator
        }
        let view = MenuRowView(
            frame: frame,
            row: row
        )
        return view
    }
}

private final class MenuRowView: NSView {
    private let label: NSTextField
    private let onClick: @MainActor () -> Void
    private var hovered = false {
        didSet {
            label.textColor = hovered ? .selectedMenuItemTextColor : .labelColor
            needsDisplay = true
        }
    }

    init(
        frame: NSRect,
        row: MenuRow
    ) {
        self.label = NSTextField(labelWithString: row.title ?? "")
        self.onClick = row.action
        super.init(frame: frame)

        label.font = font
        label.sizeToFit()
        label.frame.origin = NSPoint(
            x: 12,
            y: (frame.height - label.frame.height) / 2
        )
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseEntered(with event: NSEvent) {
        hovered = true
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
    }

    override func mouseDown(with event: NSEvent) {
        // Act on mouse up, like a real menu.
    }

    override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else {
            return
        }
        onClick()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard hovered else {
            return
        }
        NSColor.selectedContentBackgroundColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).fill()
    }
}
