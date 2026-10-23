import AppKit
import MCKit
import Synchronization

/// DockTap watches right and left clicks on its own thread, so a busy main thread never delays the user's clicks.
/// It swallows a right-click on a Dock icon while Mission Control is open and reports clicks outside the open menu.
final class DockTap: @unchecked Sendable {
    // @unchecked: `port` is written once before the thread starts, then used only on the tap thread.
    let snapshot = Mutex(TapSnapshot())
    private let onRightClick: @Sendable (URL, CGPoint) -> Void
    private let onClickOutsideMenu: @Sendable () -> Void
    private var port: CFMachPort?

    init(
        onRightClick: @escaping @Sendable (URL, CGPoint) -> Void,
        onClickOutsideMenu: @escaping @Sendable () -> Void
    ) {
        self.onRightClick = onRightClick
        self.onClickOutsideMenu = onClickOutsideMenu
    }

    /// start returns false when the tap cannot be created yet (no Accessibility permission).
    func start() -> Bool {
        let types: [CGEventType] = [.rightMouseDown, .rightMouseUp, .leftMouseDown]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: dockTapCallback,
            userInfo: selfPointer
        )
        guard port != nil else {
            return false
        }

        let thread = Thread { [self] in
            runLoop()
        }
        thread.name = "MCTweaks event tap"
        thread.start()
        return true
    }

    /// handle returns false when the event must be swallowed.
    func handle(type: CGEventType, location: CGPoint) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let port {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return true
        case .rightMouseUp:
            let swallow = snapshot.withLock { state in
                let swallow = state.swallowNextRightUp
                state.swallowNextRightUp = false
                return swallow
            }
            return !swallow
        case .rightMouseDown:
            return handleRightDown(location)
        case .leftMouseDown:
            reportIfOutsideMenu(location)
            return true
        default:
            return true
        }
    }

    private func runLoop() {
        guard let port else {
            return
        }
        let source = CFMachPortCreateRunLoopSource(nil, port, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        CFRunLoopRun()
    }

    private func handleRightDown(_ location: CGPoint) -> Bool {
        let url = snapshot.withLock { state -> URL? in
            guard state.missionControlOpen, let item = dockItem(at: location, in: state.dockItems), let url = item.url else {
                return nil
            }
            state.swallowNextRightUp = true
            return url
        }
        guard let url else {
            reportIfOutsideMenu(location)
            return true
        }

        onRightClick(url, location)
        return false
    }

    private func reportIfOutsideMenu(_ location: CGPoint) {
        let frame = snapshot.withLock { $0.menuFrame }
        guard let frame, !frame.contains(location) else {
            return
        }
        onClickOutsideMenu()
    }
}

private let dockTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let tap = Unmanaged<DockTap>.fromOpaque(userInfo).takeUnretainedValue()
    let location = event.location
    let pass = tap.handle(type: type, location: location)
    return pass ? Unmanaged.passUnretained(event) : nil
}
