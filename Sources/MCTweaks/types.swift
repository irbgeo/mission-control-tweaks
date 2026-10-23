import MCKit

/// AppState is what the timer last read: Mission Control windows (nil = closed) and Dock icons.
@MainActor
final class AppState {
    var windows: [MCWindow]?
    var dockItems: [DockItem] = []
}
