import AppKit
import MCKit

private let windowManagerID = "com.apple.WindowManager"
private let dockID = "com.apple.dock"
private let mcDisplayID = "mc.display"

/// readMissionControlWindows returns the windows of the current Space shown in Mission Control, or nil when it is closed.
func readMissionControlWindows() -> [MCWindow]? {
    guard let wm = appElement(windowManagerID) else {
        return nil
    }

    let displays = axChildren(wm).filter { axString($0, kAXIdentifierAttribute) == mcDisplayID }
    guard !displays.isEmpty else {
        return nil
    }

    let all = displays.flatMap(windowButtons)
    let onScreen = onScreenWindowIDs()
    let windows = currentSpaceWindows(all, onScreen: onScreen)
    return windows
}

func readDockItems() -> [DockItem] {
    guard let dock = appElement(dockID) else {
        return []
    }

    let lists = axChildren(dock).filter { axString($0, kAXRoleAttribute) == kAXListRole }
    let elements = lists.flatMap(axChildren)
    let items = elements.compactMap(dockItem)
    return items
}

/// onScreenWindowIDs lists normal (layer 0) on-screen windows; during Mission Control these are exactly the current Space's windows.
func onScreenWindowIDs() -> Set<Int> {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
    let ids = info.compactMap { w -> Int? in
        guard w[kCGWindowLayer as String] as? Int == 0 else {
            return nil
        }
        return w[kCGWindowNumber as String] as? Int
    }
    return Set(ids)
}

private func appElement(_ bundleID: String) -> AXUIElement? {
    let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    guard let app = apps.first else {
        return nil
    }
    return AXUIElementCreateApplication(app.processIdentifier)
}

private func windowButtons(_ display: AXUIElement) -> [MCWindow] {
    let buttons = axChildren(display).filter { axString($0, kAXRoleAttribute) == kAXButtonRole }
    let windows = buttons.compactMap(mcWindow)
    return windows
}

private func mcWindow(_ button: AXUIElement) -> MCWindow? {
    guard
        let wid = axAttr(button, "wid") as? Int,
        let frame = axFrame(button)
    else {
        return nil
    }

    let identifier = axString(button, kAXIdentifierAttribute) ?? ""
    let bundle = bundleID(fromMCIdentifier: identifier)
    let window = MCWindow(
        wid: wid,
        title: axString(button, kAXTitleAttribute) ?? "",
        bundleID: bundle,
        frame: frame
    )
    return window
}

private func dockItem(_ element: AXUIElement) -> DockItem? {
    guard axString(element, kAXRoleAttribute) == "AXDockItem", let frame = axFrame(element) else {
        return nil
    }

    let url = axAttr(element, kAXURLAttribute) as? URL
    let item = DockItem(
        title: axString(element, kAXTitleAttribute) ?? "",
        frame: frame,
        url: url
    )
    return item
}
