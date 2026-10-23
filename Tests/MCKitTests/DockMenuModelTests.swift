import CoreGraphics
import Testing
@testable import MCKit

@Test func notRunningGetsOpen() {
    let input = DockMenuInput(isRunning: false, windows: [])
    #expect(dockMenu(input) == [.open])
}

@Test func runningWithWindows() {
    let w = MCWindow(wid: 7, title: "Chat", bundleID: "t", frame: .zero)
    let input = DockMenuInput(isRunning: true, windows: [w])
    #expect(dockMenu(input) == [.window(wid: 7, title: "Chat"), .separator, .hide, .quit])
}

@Test func runningWithoutWindows() {
    let input = DockMenuInput(isRunning: true, windows: [])
    #expect(dockMenu(input) == [.hide, .quit])
}
