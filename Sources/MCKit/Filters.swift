import CoreGraphics

/// currentSpaceWindows keeps the windows that are on screen; Mission Control also lists full-screen apps of other Spaces.
public func currentSpaceWindows(_ windows: [MCWindow], onScreen: Set<Int>) -> [MCWindow] {
    windows.filter { onScreen.contains($0.wid) }
}

public func dockItem(at point: CGPoint, in items: [DockItem]) -> DockItem? {
    items.first { $0.frame.contains(point) }
}
