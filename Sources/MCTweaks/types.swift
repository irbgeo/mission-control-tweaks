import CoreGraphics
import MCKit

/// AppState is what the timer last read: Mission Control windows (nil = closed) and Dock icons.
@MainActor
final class AppState {
    var windows: [MCWindow]?
    var dockItems: [DockItem] = []
}

/// TapSnapshot is what the event-tap thread needs to decide on a click; the main thread keeps it up to date.
struct TapSnapshot: Sendable {
    var missionControlOpen = false
    var dockItems: [DockItem] = []
    /// The open menu's frame in global top-left coordinates, nil when no menu is shown.
    var menuFrame: CGRect?
    var swallowNextRightUp = false
}

/// MenuRow is one line of the Dock menu; a nil title is a separator.
struct MenuRow {
    let title: String?
    let action: @MainActor () -> Void
}
