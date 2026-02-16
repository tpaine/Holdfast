import AppKit
import ApplicationServices

struct WindowInfo {
    let element: AXUIElement
    var position: CGPoint
    var size: CGSize
}

class WindowManager {
    func windowAt(point: CGPoint) -> WindowInfo? {
        guard let (pid, _) = windowOwner(at: point) else { return nil }
        let app = AXUIElementCreateApplication(pid)

        // Try to get the window under the cursor by iterating windows
        var windowList: AnyObject?
        if AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowList) == .success,
           let windows = windowList as? [AXUIElement] {
            // Find the topmost window containing the point
            for window in windows {
                if let info = windowInfo(for: window), frameContains(info: info, point: point) {
                    return info
                }
            }
        }

        // Fallback to focused window
        var focusedWindow: AnyObject?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success else {
            return nil
        }
        // AXUIElement is a CFTypeRef; cast through CFTypeRef to avoid the "always succeeds" warning
        let window = focusedWindow as! AXUIElement
        return windowInfo(for: window)
    }

    func setPosition(_ position: CGPoint, of element: AXUIElement) {
        var pos = position
        let value = AXValueCreate(.cgPoint, &pos)!
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)
    }

    func setSize(_ size: CGSize, of element: AXUIElement) {
        var sz = size
        let value = AXValueCreate(.cgSize, &sz)!
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value)
    }

    func raise(_ element: AXUIElement) {
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)

        // Also raise the owning app
        var pid: pid_t = 0
        if AXUIElementGetPid(element, &pid) == .success {
            if let app = NSRunningApplication(processIdentifier: pid) {
                app.activate()
            }
        }
    }

    // MARK: - Private

    private func windowOwner(at point: CGPoint) -> (pid_t, CGWindowID)? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for entry in windowList {
            guard let boundsDict = entry[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = boundsDict["X"], let y = boundsDict["Y"],
                  let w = boundsDict["Width"], let h = boundsDict["Height"],
                  let ownerPID = entry[kCGWindowOwnerPID as String] as? pid_t,
                  let windowID = entry[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }

            let frame = CGRect(x: x, y: y, width: w, height: h)
            if frame.contains(point) {
                // Skip our own app
                if ownerPID == ProcessInfo.processInfo.processIdentifier { continue }
                // Skip windows with layer != 0 (menu bar, dock, etc.)
                if let layer = entry[kCGWindowLayer as String] as? Int, layer != 0 { continue }
                return (ownerPID, windowID)
            }
        }
        return nil
    }

    func windowInfo(for element: AXUIElement) -> WindowInfo? {
        var posValue: AnyObject?
        var sizeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

        return WindowInfo(element: element, position: position, size: size)
    }

    private func frameContains(info: WindowInfo, point: CGPoint) -> Bool {
        let frame = CGRect(origin: info.position, size: info.size)
        return frame.contains(point)
    }
}
