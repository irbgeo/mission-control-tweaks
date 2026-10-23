import AppKit
import MCKit

/// DockMenu shows an app menu for a Dock icon right-clicked while Mission Control is open.
@MainActor
final class DockMenu {
    private let state: AppState
    private var tap: DockTap?
    // Clears the click watcher's menu frame however the menu closes (item picked, click outside, Mission Control closed).
    private lazy var panel = MenuPanel { [weak self] in
        self?.tap?.snapshot.withLock { $0.menuFrame = nil }
    }

    init(
        state: AppState
    ) {
        self.state = state
    }

    /// start creates the click watcher once; call it again until it succeeds (it needs Accessibility permission).
    func start() {
        guard tap == nil, AXIsProcessTrusted() else {
            return
        }

        let tap = DockTap(
            onRightClick: { [weak self] url, location in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        self?.show(url: url, at: location)
                    }
                }
            },
            onClickOutsideMenu: { [weak self] in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        self?.close()
                    }
                }
            }
        )
        let started = tap.start()
        guard started else {
            NSLog("MCTweaks: cannot create event tap yet")
            return
        }
        self.tap = tap
    }

    /// sync passes the latest Mission Control state to the click watcher and closes the menu when Mission Control closes.
    func sync() {
        let open = state.windows != nil
        let items = state.dockItems
        tap?.snapshot.withLock { snapshot in
            snapshot.missionControlOpen = open
            snapshot.dockItems = items
        }
        if !open && panel.frame != nil {
            close()
        }
    }

    private func show(url: URL, at location: CGPoint) {
        let app = runningApp(url: url)
        let windows = windowsOf(app)
        let input = DockMenuInput(
            isRunning: app != nil,
            windows: windows
        )
        let entries = dockMenu(input)
        let rows = entries.map { entry in
            let target = MenuTarget(
                entry: entry,
                app: app,
                url: url
            )
            return target.row()
        }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let click = NSPoint(
            x: location.x,
            y: primaryHeight - location.y
        )
        panel.show(rows, at: click)
        let frame = panel.frame.map { cocoaRect($0, primaryHeight: primaryHeight) }
        tap?.snapshot.withLock { $0.menuFrame = frame }
    }

    private func close() {
        panel.close()
    }

    /// windowsOf matches by the window's owner process: Mission Control's bundle id is not always the app's.
    private func windowsOf(_ app: NSRunningApplication?) -> [MCWindow] {
        guard let app else {
            return []
        }
        let all = state.windows ?? []
        let windows = all.filter { window in
            let owner = ownerApp(ofWindow: window.wid)
            return owner?.processIdentifier == app.processIdentifier
        }
        return windows
    }

    private func runningApp(url: URL) -> NSRunningApplication? {
        let path = url.standardizedFileURL.path
        let apps = NSWorkspace.shared.runningApplications
        let app = apps.first { $0.bundleURL?.standardizedFileURL.path == path }
        return app
    }
}

/// MenuTarget turns one menu entry into a row and runs it.
@MainActor
private struct MenuTarget {
    let entry: MenuEntry
    let app: NSRunningApplication?
    let url: URL

    func row() -> MenuRow {
        let title: String?
        switch entry {
        case .separator:
            title = nil
        case let .window(_, windowTitle):
            title = windowTitle.isEmpty ? "(untitled)" : windowTitle
        case .hide:
            title = "Hide"
        case .quit:
            title = "Quit"
        case .open:
            title = "Open"
        }

        let row = MenuRow(title: title) {
            run()
        }
        return row
    }

    private func run() {
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
