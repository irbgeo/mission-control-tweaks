import Testing
@testable import MCKit

@Test func statusFromPermission() {
    #expect(appStatus(trusted: true) == .working)
    #expect(appStatus(trusted: false) == .needsPermission)
}

@Test func statusTitles() {
    #expect(statusTitle(.working) == "MCTweaks is working")
    #expect(statusTitle(.needsPermission) == "Needs permission to control this Mac…")
}

@Test(arguments: [
    (AppStatus.working, true, false),
    (AppStatus.working, false, true),
    (AppStatus.needsPermission, true, true),
])
func welcomeVisibility(status: AppStatus, didShow: Bool, expected: Bool) {
    let input = WelcomeInput(status: status, didShowWelcome: didShow)
    #expect(shouldShowWelcome(input) == expected)
}
