/// dockMenu lists the entries of the right-click menu for a Dock icon.
public func dockMenu(_ input: DockMenuInput) -> [MenuEntry] {
    guard input.isRunning else {
        return [.open]
    }

    var entries = input.windows.map { MenuEntry.window(wid: $0.wid, title: $0.title) }
    if !entries.isEmpty {
        entries.append(.separator)
    }
    entries.append(contentsOf: [.hide, .quit])
    return entries
}
