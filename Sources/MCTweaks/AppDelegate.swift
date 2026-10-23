import AppKit

/// AppDelegate shows the Welcome window when the user opens the app again while it already runs.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let welcome: WelcomeWindow

    init(
        welcome: WelcomeWindow
    ) {
        self.welcome = welcome
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        welcome.show()
        return false
    }
}
