import AppKit
import MCKit

MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    // Only one copy: a second launch (e.g. an old login item) quits at once.
    let bundleID = Bundle.main.bundleIdentifier ?? ""
    let current = NSRunningApplication.current
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).filter { $0 != current }
    if !bundleID.isEmpty && !others.isEmpty {
        exit(0)
    }

    limitAXWaiting()

    // Open at Login is on by default, once: later launches respect the user's choice.
    // Users who already finished the Welcome window (older versions) made their choice too.
    let defaults = UserDefaults.standard
    let didShowWelcome = defaults.bool(forKey: didShowWelcomeKey)
    let didSetLoginDefault = defaults.bool(forKey: didSetLoginDefaultKey)
    if !didSetLoginDefault && !didShowWelcome {
        LoginItem.set(true)
    }
    defaults.set(true, forKey: didSetLoginDefaultKey)

    let model = WelcomeModel()
    model.refresh()

    let state = AppState()
    let closeButtons = CloseButtons()
    let dockMenu = DockMenu(state: state)
    let welcome = WelcomeWindow(model: model)
    let statusBar = StatusBar(
        model: model,
        welcome: welcome
    )
    let delegate = AppDelegate(welcome: welcome)
    app.delegate = delegate

    let welcomeInput = WelcomeInput(
        status: model.status,
        didShowWelcome: didShowWelcome
    )
    if shouldShowWelcome(welcomeInput) {
        welcome.show()
    }

    var tick = 0
    let timer = Timer(timeInterval: 0.15, repeats: true) { _ in
        MainActor.assumeIsolated {
            dockMenu.start()
            let windows = readMissionControlWindows()
            state.windows = windows
            if windows != nil {
                state.dockItems = readDockItems()
            }
            closeButtons.update(windows ?? [])
            dockMenu.sync()

            // About every 0.5 s: enough for the Welcome window to notice a new permission.
            tick += 1
            if tick % 3 == 0 {
                model.refresh()
            }
        }
    }
    // .common keeps the timer running while a menu is tracking.
    RunLoop.main.add(timer, forMode: .common)

    withExtendedLifetime((statusBar, delegate)) {
        app.run()
    }
}
