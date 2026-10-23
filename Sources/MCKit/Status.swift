public func appStatus(trusted: Bool) -> AppStatus {
    trusted ? .working : .needsPermission
}

public func statusTitle(_ status: AppStatus) -> String {
    switch status {
    case .working:
        "MCTweaks is working"
    case .needsPermission:
        "Needs permission to control this Mac…"
    }
}

/// shouldShowWelcome is true on first launch and whenever the permission is missing.
public func shouldShowWelcome(_ input: WelcomeInput) -> Bool {
    input.status != .working || !input.didShowWelcome
}
