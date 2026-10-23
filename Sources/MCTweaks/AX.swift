import ApplicationServices

/// How long one AX call may wait for another app; AX's default is about 6 s, which would freeze our main thread.
private let axTimeoutSeconds: Float = 0.25

/// Private, but stable for years (used by AltTab, yabai): maps an AX window to its CGWindowID.
@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ id: UnsafeMutablePointer<CGWindowID>) -> AXError

/// limitAXWaiting makes every AX call of this process give up after axTimeoutSeconds.
func limitAXWaiting() {
    let systemWide = AXUIElementCreateSystemWide()
    AXUIElementSetMessagingTimeout(systemWide, axTimeoutSeconds)
}

func axAttr(_ element: AXUIElement, _ name: String) -> AnyObject? {
    var value: AnyObject?
    let err = AXUIElementCopyAttributeValue(element, name as CFString, &value)
    guard err == .success else {
        return nil
    }
    return value
}

func axChildren(_ element: AXUIElement) -> [AXUIElement] {
    let children = axAttr(element, kAXChildrenAttribute) as? [AXUIElement]
    return children ?? []
}

func axString(_ element: AXUIElement, _ name: String) -> String? {
    axAttr(element, name) as? String
}

/// axFrame reads AXPosition + AXSize (global top-left coordinates).
func axFrame(_ element: AXUIElement) -> CGRect? {
    guard
        let posValue = axValue(element, kAXPositionAttribute),
        let sizeValue = axValue(element, kAXSizeAttribute)
    else {
        return nil
    }

    var origin = CGPoint.zero
    var size = CGSize.zero
    AXValueGetValue(posValue, .cgPoint, &origin)
    AXValueGetValue(sizeValue, .cgSize, &size)
    let frame = CGRect(
        origin: origin,
        size: size
    )
    return frame
}

/// axValue returns the attribute only if it really is an AXValue: other apps may return anything.
private func axValue(_ element: AXUIElement, _ name: String) -> AXValue? {
    guard let value = axAttr(element, name), CFGetTypeID(value) == AXValueGetTypeID() else {
        return nil
    }
    // The type ID check above makes this cast safe.
    return (value as! AXValue)
}

func axPress(_ element: AXUIElement, _ action: String) {
    AXUIElementPerformAction(element, action as CFString)
}
