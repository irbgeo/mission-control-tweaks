import CoreGraphics
import Testing
@testable import MCKit

@Test func cocoaRectFlipsY() {
    let ax = CGRect(x: 10, y: 100, width: 50, height: 30)
    #expect(cocoaRect(ax, primaryHeight: 1000) == CGRect(x: 10, y: 870, width: 50, height: 30))
}

@Test func closeButtonCentredOnTopLeft() {
    let w = CGRect(x: 100, y: 200, width: 300, height: 400)
    #expect(closeButtonRect(for: w) == CGRect(x: 89, y: 189, width: 22, height: 22))
}
