import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var eventTap: EventTap?
    private var handler: MoveResizeHandler?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let preferences = Preferences()
        statusBarController = StatusBarController(preferences: preferences)

        if PermissionHelper.requestAccessibilityIfNeeded() {
            startEventTap(preferences: preferences)
        } else {
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    self?.permissionTimer = nil
                    self?.startEventTap(preferences: preferences)
                }
            }
        }
    }

    private func startEventTap(preferences: Preferences) {
        let windowManager = WindowManager()
        handler = MoveResizeHandler(windowManager: windowManager, preferences: preferences)
        eventTap = EventTap(handler: handler!)
        eventTap?.start()
    }
}
