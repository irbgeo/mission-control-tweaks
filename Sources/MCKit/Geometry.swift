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
