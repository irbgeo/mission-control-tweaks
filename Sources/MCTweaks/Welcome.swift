import AppKit
@preconcurrency import ApplicationServices
import MCKit
import SwiftUI

let didShowWelcomeKey = "didShowWelcome"
let didSetLoginDefaultKey = "didSetLoginDefault"

/// WelcomeModel is the live state the Welcome window and the menu bar show.
@MainActor
@Observable
final class WelcomeModel {
    private(set) var status: AppStatus = .needsPermission
    private(set) var loginEnabled = false
    private(set) var loginNeedsApproval = false

    func refresh() {
        let trusted = AXIsProcessTrusted()
        let newStatus = appStatus(trusted: trusted)
        let newLoginEnabled = LoginItem.isEnabled
        let newNeedsApproval = LoginItem.needsApproval
        // Assign only on change, so SwiftUI does not redraw every tick.
        if newStatus != status {
            status = newStatus
        }
        if newLoginEnabled != loginEnabled {
            loginEnabled = newLoginEnabled
        }
        if newNeedsApproval != loginNeedsApproval {
            loginNeedsApproval = newNeedsApproval
        }
    }

    func setLogin(_ on: Bool) {
        LoginItem.set(on)
        refresh()
    }

    /// askForAccessibility removes a stale permission entry, then shows the macOS prompt, which adds MCTweaks to the list again.
    /// A stale entry stays "on" in Settings but belongs to an older build; macOS then neither trusts the app nor asks again.
    func askForAccessibility() {
        resetOwnAccessibilityEntry()
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func resetOwnAccessibilityEntry() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", bundleID]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("MCTweaks: tccutil reset failed: \(error)")
        }
    }
}

/// WelcomeWindow hosts WelcomeView; it remembers it was shown once everything works.
@MainActor
final class WelcomeWindow: NSObject, NSWindowDelegate {
    private let model: WelcomeModel
    private var window: NSWindow?

    init(
        model: WelcomeModel
    ) {
        self.model = model
    }

    func show() {
        let window = self.window ?? makeWindow()
        self.window = window
        NSApp.activate()
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard model.status == .working else {
            return
        }
        UserDefaults.standard.set(true, forKey: didShowWelcomeKey)
    }

    private func makeWindow() -> NSWindow {
        let view = WelcomeView(model: model) { [weak self] in
            self?.window?.close()
        }
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "Welcome to MCTweaks"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        return window
    }
}

private struct WelcomeView: View {
    let model: WelcomeModel
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            permissionStep
            loginStep
            if model.status == .working {
                allSet
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to MCTweaks")
                    .font(.title2.bold())
                Text("Close windows and use Dock menus right in Mission Control.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var permissionStep: some View {
        let granted = model.status == .working
        return VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(granted ? "Permission is allowed" : "Allow MCTweaks to control this Mac")
                    .font(.headline)
            } icon: {
                Image(systemName: granted ? "checkmark.circle.fill" : "1.circle.fill")
                    .foregroundStyle(granted ? .green : .accentColor)
            }
            if !granted {
                Text("MCTweaks needs it to see Mission Control and close windows. Click the button, then turn on the switch next to **MCTweaks** (the page is called **Device Control and Data Access** on macOS 27, **Accessibility** on older versions).")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open System Settings") {
                    model.askForAccessibility()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var loginStep: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Open at Login", isOn: Binding(
                get: { model.loginEnabled },
                set: { model.setLogin($0) }
            ))
            if model.loginNeedsApproval {
                Button("Approve in Login Items…") {
                    LoginItem.openSettings()
                }
                .buttonStyle(.link)
            }
        }
    }

    private var allSet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All set! Open Mission Control (**F3** or swipe up with three fingers). Click **×** to close a window, **⌥-click** to quit its app, and right-click a Dock icon for its menu.")
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}
