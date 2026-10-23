import CoreGraphics
import Testing
@testable import MCKit

private let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
private let size = CGSize(width: 120, height: 60)

@Test func placesMenuAboveClickCentred() {
    let input = MenuPlacementInput(click: CGPoint(x: 500, y: 40), size: size, screen: screen)
    #expect(menuOrigin(input) == CGPoint(x: 440, y: 52))
}

@Test func keepsMenuInsideScreenHorizontally() {
    let left = MenuPlacementInput(click: CGPoint(x: 10, y: 40), size: size, screen: screen)
    let right = MenuPlacementInput(click: CGPoint(x: 1505, y: 40), size: size, screen: screen)
    #expect(menuOrigin(left).x == CGFloat(4))
    #expect(menuOrigin(right).x == CGFloat(1388))
}

@Test func keepsMenuInsideScreenVertically() {
    let top = MenuPlacementInput(click: CGPoint(x: 500, y: 960), size: size, screen: screen)
    #expect(menuOrigin(top).y == CGFloat(918))
}
