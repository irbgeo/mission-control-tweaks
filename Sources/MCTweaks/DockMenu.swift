import AppKit
import MCKit

/// DockMenu catches right-clicks on Dock icons while Mission Control is open and shows an app menu.
@MainActor
final class DockMenu {
    private let state: AppState
    private var tap: CFMachPort?
    private var swallowNextUp = false

    init(
        state: AppState
    ) {
        self.state = state
    }

    /// start creates the event tap once; call it again until it succeeds (it needs Accessibility permission).
    func start() {
        guard tap == nil, AXIsProcessTrusted() else {
            return
        }

        let mask = (1 << CGEventType.rightMouseDown.rawValue) | (1 << CGEventType.rightMouseUp.rawValue)
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: dockMenuTapCallback,
            userInfo: selfPointer
        )
        guard let tap else {
            NSLog("MCTweaks: cannot create event tap (Accessibility permission?)")
            return
        }

        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    /// handle returns false when the event must be swallowed.
    func handle(type: CGEventType, location: CGPoint) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return true
        case .rightMouseUp:
            let pass = !swallowNextUp
            swallowNextUp = false
            return pass
        case .rightMouseDown:
            return handleRightDown(location)
        default:
            return true
        }
    }

    private func handleRightDown(_ location: CGPoint) -> Bool {
        guard state.windows != nil, let item = dockItem(at: location, in: state.dockItems), let url = item.url else {
            return true
        }

        swallowNextUp = true
        // Show the menu after the tap callback returns; popUp runs its own tracking loop.
        DispatchQueue.main.async {
            self.showMenu(url: url, at: location)
        }
        return false
    }

    private func showMenu(url: URL, at location: CGPoint) {
        let app = runningApp(url: url)
        let windows = (state.windows ?? []).filter { $0.bundleID == app?.bundleIdentifier }
        let input = DockMenuInput(
            isRunning: app != nil,
            windows: windows
        )
        let entries = dockMenu(input)

        let menu = NSMenu()
        for entry in entries {
            let target = MenuTarget(
                entry: entry,
                app: app,
                url: url
            )
            let item = target.menuItem()
            menu.addItem(item)
        }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let point = NSPoint(x: location.x, y: primaryHeight - location.y)
        menu.popUp(positioning: nil, at: point, in: nil)
    }

    private func runningApp(url: URL) -> NSRunningApplication? {
        let path = url.standardizedFileURL.path
        let apps = NSWorkspace.shared.runningApplications
        let app = apps.first { $0.bundleURL?.standardizedFileURL.path == path }
        return app
    }
}

private let dockMenuTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let menu = Unmanaged<DockMenu>.fromOpaque(userInfo).takeUnretainedValue()
    let location = event.location
    // The tap's run loop source is on the main run loop.
    let pass = MainActor.assumeIsolated {
        menu.handle(type: type, location: location)
    }
    return pass ? Unmanaged.passUnretained(event) : nil
}

/// MenuTarget runs one menu entry; NSMenuItem keeps it alive as representedObject.
@MainActor
private final class MenuTarget: NSObject {
    private let entry: MenuEntry
    private let app: NSRunningApplication?
    private let url: URL

    init(
        entry: MenuEntry,
        app: NSRunningApplication?,
        url: URL
    ) {
        self.entry = entry
        self.app = app
        self.url = url
    }

    func menuItem() -> NSMenuItem {
        let title: String
        switch entry {
        case .separator:
            return NSMenuItem.separator()
        case let .window(_, windowTitle):
            title = windowTitle.isEmpty ? "(untitled)" : windowTitle
        case .hide:
            title = "Hide"
        case .quit:
            title = "Quit"
        case .open:
            title = "Open"
        }

        let item = NSMenuItem(title: title, action: #selector(run), keyEquivalent: "")
        item.target = self
        item.representedObject = self
        return item
    }

    @objc private func run() {
        let optionHeld = NSEvent.modifierFlags.contains(.option)
        switch entry {
        case let .window(wid, _):
            raiseWindow(wid: wid)
        case .hide:
            app?.hide()
        case .quit where optionHeld:
            app?.forceTerminate()
        case .quit:
            app?.terminate()
        case .open:
            NSWorkspace.shared.open(url)
        case .separator:
            break
        }
    }
}
