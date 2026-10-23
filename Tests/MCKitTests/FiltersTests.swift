import CoreGraphics
import Testing
@testable import MCKit

@Test func keepsOnlyOnScreenWindows() {
    let a = MCWindow(wid: 41, title: "a", frame: .zero)
    let b = MCWindow(wid: 100, title: "b", frame: .zero)
    #expect(currentSpaceWindows([a, b], onScreen: [41, 3249]).map(\.wid) == [41])
}

@Test func hitsDockItem() {
    let items = [
        DockItem(title: "Finder", frame: CGRect(x: 392, y: 987, width: 47, height: 59), url: nil),
        DockItem(title: "Slack", frame: CGRect(x: 439, y: 987, width: 47, height: 59), url: nil),
    ]
    #expect(dockItem(at: CGPoint(x: 450, y: 1000), in: items)?.title == "Slack")
    #expect(dockItem(at: CGPoint(x: 450, y: 900), in: items) == nil)
}
