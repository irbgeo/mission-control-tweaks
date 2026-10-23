import CoreGraphics

private let closeButtonSize: CGFloat = 22

/// cocoaRect converts a global top-left rect (AX, CGEvent) to Cocoa bottom-left screen coordinates.
public func cocoaRect(_ ax: CGRect, primaryHeight: CGFloat) -> CGRect {
    let rect = CGRect(
        x: ax.minX,
        y: primaryHeight - ax.maxY,
        width: ax.width,
        height: ax.height
    )
    return rect
}

/// closeButtonRect is a square centred on the window's top-left corner, in the same coordinates as `window`.
public func closeButtonRect(for window: CGRect) -> CGRect {
    let half = closeButtonSize / 2
    let rect = CGRect(
        x: window.minX - half,
        y: window.minY - half,
        width: closeButtonSize,
        height: closeButtonSize
    )
    return rect
}

private let menuMargin: CGFloat = 4
private let menuGap: CGFloat = 12

/// menuOrigin puts the menu just above the click, centred on it, and keeps it on the screen (Cocoa coordinates).
public func menuOrigin(_ input: MenuPlacementInput) -> CGPoint {
    let minX = input.screen.minX + menuMargin
    let maxX = input.screen.maxX - input.size.width - menuMargin
    let minY = input.screen.minY + menuMargin
    let maxY = input.screen.maxY - input.size.height - menuMargin
    let x = input.click.x - input.size.width / 2
    let y = input.click.y + menuGap
    let origin = CGPoint(
        x: min(max(x, minX), maxX),
        y: min(max(y, minY), maxY)
    )
    return origin
}
