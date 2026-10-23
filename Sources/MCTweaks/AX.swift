import ApplicationServices

/// Private, but stable for years (used by AltTab, yabai): maps an AX window to its CGWindowID.
@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ id: UnsafeMutablePointer<CGWindowID>) -> AXError

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
        let posValue = axAttr(element, kAXPositionAttribute),
        let sizeValue = axAttr(element, kAXSizeAttribute)
    else {
        return nil
    }

    var origin = CGPoint.zero
    var size = CGSize.zero
    // AX always returns AXValue for these attributes, so the forced casts cannot fail.
    AXValueGetValue(posValue as! AXValue, .cgPoint, &origin)
    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
    let frame = CGRect(
        origin: origin,
        size: size
    )
    return frame
}

func axPress(_ element: AXUIElement, _ action: String) {
    AXUIElementPerformAction(element, action as CFString)
}
