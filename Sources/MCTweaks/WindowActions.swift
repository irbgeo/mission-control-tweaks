import AppKit

/// closeWindow presses the window's red close button.
func closeWindow(wid: Int) {
    let window = axWindow(wid: wid)
    let button = window.flatMap { axAttr($0, kAXCloseButtonAttribute) }
    guard let button, CFGetTypeID(button) == AXUIElementGetTypeID() else {
        NSLog("MCTweaks: no AX close button for window \(wid)")
        return
    }

    let closeButton = button as! AXUIElement
    axPress(closeButton, kAXPressAction)
}

/// raiseWindow brings the window to the front and activates its app.
func raiseWindow(wid: Int) {
    let app = ownerApp(ofWindow: wid)
    if let window = axWindow(wid: wid) {
        axPress(window, kAXRaiseAction)
    }
    app?.activate()
}

func ownerApp(ofWindow wid: Int) -> NSRunningApplication? {
    guard let pid = ownerPID(ofWindow: wid) else {
        return nil
    }
    return NSRunningApplication(processIdentifier: pid)
}

private func ownerPID(ofWindow wid: Int) -> pid_t? {
    let info = CGWindowListCopyWindowInfo(.optionIncludingWindow, CGWindowID(wid)) as? [[String: Any]]
    let pid = info?.first?[kCGWindowOwnerPID as String] as? Int
    guard let pid else {
        return nil
    }
    return pid_t(pid)
}

private func axWindow(wid: Int) -> AXUIElement? {
    guard let pid = ownerPID(ofWindow: wid) else {
        return nil
    }

    let app = AXUIElementCreateApplication(pid)
    let windows = axAttr(app, kAXWindowsAttribute) as? [AXUIElement] ?? []
    let match = windows.first { window in
        var id: CGWindowID = 0
        let err = _AXUIElementGetWindow(window, &id)
        return err == .success && Int(id) == wid
    }
    return match
}
