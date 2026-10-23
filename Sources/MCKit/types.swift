import CoreGraphics
import Foundation

/// A window thumbnail shown in Mission Control. `frame` is in global top-left coordinates.
public struct MCWindow: Equatable, Sendable {
    public let wid: Int
    public let title: String
    public let frame: CGRect

    public init(
        wid: Int,
        title: String,
        frame: CGRect
    ) {
        self.wid = wid
        self.title = title
        self.frame = frame
    }
}

/// An icon in the Dock. `frame` is in global top-left coordinates.
public struct DockItem: Equatable, Sendable {
    public let title: String
    public let frame: CGRect
    public let url: URL?

    public init(
        title: String,
        frame: CGRect,
        url: URL?
    ) {
        self.title = title
        self.frame = frame
        self.url = url
    }
}

public enum MenuEntry: Equatable, Sendable {
    case window(wid: Int, title: String)
    case separator
    case hide
    case quit
    case open
}

public struct DockMenuInput: Sendable {
    public let isRunning: Bool
    public let windows: [MCWindow]

    public init(
        isRunning: Bool,
        windows: [MCWindow]
    ) {
        self.isRunning = isRunning
        self.windows = windows
    }
}

public enum AppStatus: Equatable, Sendable {
    case working
    case needsPermission
}

public struct WelcomeInput: Sendable {
    public let status: AppStatus
    public let didShowWelcome: Bool

    public init(
        status: AppStatus,
        didShowWelcome: Bool
    ) {
        self.status = status
        self.didShowWelcome = didShowWelcome
    }
}

/// MenuPlacementInput uses Cocoa coordinates (bottom-left origin).
public struct MenuPlacementInput: Sendable {
    public let click: CGPoint
    public let size: CGSize
    public let screen: CGRect

    public init(
        click: CGPoint,
        size: CGSize,
        screen: CGRect
    ) {
        self.click = click
        self.size = size
        self.screen = screen
    }
}
