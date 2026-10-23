import AppKit
@preconcurrency import ApplicationServices

MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    let promptOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    let trusted = AXIsProcessTrustedWithOptions(promptOptions)
    if !trusted {
        NSLog("MCTweaks: waiting for Accessibility permission")
    }

    let state = AppState()
    let closeButtons = CloseButtons()
    let dockMenu = DockMenu(state: state)
    let timer = Timer(timeInterval: 0.15, repeats: true) { _ in
        MainActor.assumeIsolated {
            dockMenu.start()
            let windows = readMissionControlWindows()
            state.windows = windows
            if windows != nil {
                state.dockItems = readDockItems()
            }
            closeButtons.update(windows ?? [])
        }
    }
    // .common keeps the timer running while a menu is tracking.
    RunLoop.main.add(timer, forMode: .common)

    app.run()
}
