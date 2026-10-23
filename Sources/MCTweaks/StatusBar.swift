import AppKit
import MCKit

private let releasesURLKey = "MCTReleasesURL"

/// StatusBar is the menu bar icon: status, Open at Login, help, updates, quit.
@MainActor
final class StatusBar: NSObject, NSMenuDelegate {
    private let model: WelcomeModel
    private let welcome: WelcomeWindow
    private let item: NSStatusItem

    init(
        model: WelcomeModel,
        welcome: WelcomeWindow
    ) {
        self.model = model
        self.welcome = welcome
        self.item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        let image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "MCTweaks")
        image?.isTemplate = true
        item.button?.image = image
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        model.refresh()
        menu.removeAllItems()

        let title = statusTitle(model.status)
        let needsAction = model.status != .working
        let statusItem = NSMenuItem(title: title, action: needsAction ? #selector(showWelcome) : nil, keyEquivalent: "")
        statusItem.target = self
        menu.addItem(statusItem)
        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = model.loginEnabled ? .on : .off
        menu.addItem(loginItem)
        let helpItem = targetedItem("How to Use…", action: #selector(showHelp))
        menu.addItem(helpItem)
        if releasesURL() != nil {
            let updatesItem = targetedItem("Check for Updates…", action: #selector(openReleases))
            menu.addItem(updatesItem)
        }
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit MCTweaks", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    private func targetedItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func releasesURL() -> URL? {
        let value = Bundle.main.object(forInfoDictionaryKey: releasesURLKey) as? String ?? ""
        guard !value.isEmpty else {
            return nil
        }
        return URL(string: value)
    }

    @objc private func showWelcome() {
        welcome.show()
    }

    @objc private func toggleLogin() {
        let on = !model.loginEnabled
        model.setLogin(on)
    }

    @objc private func showHelp() {
        let alert = NSAlert()
        alert.messageText = "How to use MCTweaks"
        alert.informativeText = """
        Open Mission Control (F3 or swipe up with three fingers).

        • Click × on a window to close it.
        • ⌥ Option-click × to quit the window's app.
        • Right-click a Dock icon for its menu: windows, Hide, Quit (hold ⌥ for Force Quit).
        """
        NSApp.activate()
        alert.runModal()
    }

    @objc private func openReleases() {
        guard let url = releasesURL() else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
