import CoreGraphics

/// bundleID strips the ".space.<N>" suffix Mission Control adds to window identifiers.
public func bundleID(fromMCIdentifier id: String) -> String {
    let parts = id.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count > 2, parts[parts.count - 2] == "space", let last = parts.last, !last.isEmpty, last.allSatisfy(\.isNumber) else {
        return id
    }

    let kept = parts.dropLast(2)
    return kept.joined(separator: ".")
}

/// currentSpaceWindows keeps the windows that are on screen; Mission Control also lists full-screen apps of other Spaces.
public func currentSpaceWindows(_ windows: [MCWindow], onScreen: Set<Int>) -> [MCWindow] {
    windows.filter { onScreen.contains($0.wid) }
}

public func dockItem(at point: CGPoint, in items: [DockItem]) -> DockItem? {
    items.first { $0.frame.contains(point) }
}
