import AppKit
import ApplicationServices

/// Which edges of the window to move during a resize, determined by a 3x3 grid.
struct ResizeSection {
    let left: Bool
    let top: Bool
    let right: Bool
    let bottom: Bool

    static func from(point: CGPoint, in window: WindowInfo) -> ResizeSection {
        let relX = (point.x - window.position.x) / window.size.width
        let relY = (point.y - window.position.y) / window.size.height

        let left = relX < 1.0 / 3.0
        let right = relX > 2.0 / 3.0
        let top = relY < 1.0 / 3.0
        let bottom = relY > 2.0 / 3.0

        // Center cell: default to bottom-right
        if !left && !right && !top && !bottom {
            return ResizeSection(left: false, top: false, right: true, bottom: true)
        }

        return ResizeSection(left: left, top: top, right: right, bottom: bottom)
    }
}

enum DragState {
    case idle
    case armed
    case moving(window: WindowInfo, mouseStart: CGPoint)
    case resizing(window: WindowInfo, mouseStart: CGPoint, section: ResizeSection)
}

class MoveResizeHandler {
    private let windowManager: WindowManager
    private let preferences: Preferences
    private var state: DragState = .idle

    init(windowManager: WindowManager, preferences: Preferences) {
        self.windowManager = windowManager
        self.preferences = preferences
    }

    /// Handle a CGEvent. Returns nil if the event should be consumed (not passed through).
    func handle(type: CGEventType, event: CGEvent) -> CGEvent? {
        let flags = event.flags
        let modFlag = preferences.modifierKey.cgEventFlag
        let modifierHeld = flags.contains(modFlag)
        let shiftHeld = flags.contains(.maskShift)

        switch type {
        case .flagsChanged:
            return handleFlagsChanged(modifierHeld: modifierHeld, shiftHeld: shiftHeld, event: event)
        case .leftMouseDown:
            return handleMouseDown(event: event, shiftHeld: shiftHeld)
        case .leftMouseUp:
            return handleMouseUp(event: event)
        case .leftMouseDragged:
            return handleMouseDragged(event: event)
        default:
            return event
        }
    }

    // MARK: - Event Handlers

    private func handleFlagsChanged(modifierHeld: Bool, shiftHeld: Bool, event: CGEvent) -> CGEvent {
        if modifierHeld {
            switch state {
            case .idle:
                state = .armed
            default:
                break
            }
        } else {
            // Modifier released — cancel any operation
            state = .idle
        }
        return event
    }

    private func handleMouseDown(event: CGEvent, shiftHeld: Bool) -> CGEvent? {
        switch state {
        case .armed:
            let mousePoint = event.location
            guard let window = windowManager.windowAt(point: mousePoint) else {
                return event
            }
            windowManager.raise(window.element)

            // Check Shift on the click event itself — no state tracking needed
            if shiftHeld {
                let section = ResizeSection.from(point: mousePoint, in: window)
                state = .resizing(window: window, mouseStart: mousePoint, section: section)
            } else {
                state = .moving(window: window, mouseStart: mousePoint)
            }
            return nil

        default:
            return event
        }
    }

    private func handleMouseUp(event: CGEvent) -> CGEvent? {
        switch state {
        case .moving, .resizing:
            state = .armed
            return nil
        default:
            return event
        }
    }

    private func handleMouseDragged(event: CGEvent) -> CGEvent? {
        let shiftHeld = event.flags.contains(.maskShift)

        switch state {
        case .moving(let window, let mouseStart):
            // Switch to resize mid-drag when Shift is pressed
            if shiftHeld {
                if let fresh = windowManager.windowInfo(for: window.element) {
                    let current = event.location
                    let section = ResizeSection.from(point: current, in: fresh)
                    state = .resizing(window: fresh, mouseStart: current, section: section)
                }
                return nil
            }

            let current = event.location
            let dx = current.x - mouseStart.x
            let dy = current.y - mouseStart.y
            let newPos = CGPoint(x: window.position.x + dx, y: window.position.y + dy)
            windowManager.setPosition(newPos, of: window.element)
            return nil

        case .resizing(let window, let mouseStart, let section):
            // Switch to move mid-drag when Shift is released
            if !shiftHeld {
                if let fresh = windowManager.windowInfo(for: window.element) {
                    let current = event.location
                    state = .moving(window: fresh, mouseStart: current)
                }
                return nil
            }

            let current = event.location
            let dx = current.x - mouseStart.x
            let dy = current.y - mouseStart.y

            var newX = window.position.x
            var newY = window.position.y
            var newW = window.size.width
            var newH = window.size.height

            if section.left {
                newX += dx
                newW -= dx
            }
            if section.right {
                newW += dx
            }
            if section.top {
                newY += dy
                newH -= dy
            }
            if section.bottom {
                newH += dy
            }

            // Enforce minimum size
            let minSize: CGFloat = 50
            if newW < minSize {
                if section.left { newX -= (minSize - newW) }
                newW = minSize
            }
            if newH < minSize {
                if section.top { newY -= (minSize - newH) }
                newH = minSize
            }

            windowManager.setPosition(CGPoint(x: newX, y: newY), of: window.element)
            windowManager.setSize(CGSize(width: newW, height: newH), of: window.element)
            return nil

        default:
            return event
        }
    }
}
