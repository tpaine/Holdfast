import AppKit
import ApplicationServices

enum PermissionHelper {
    /// Returns true if already trusted. If not, shows the system prompt and returns false.
    static func requestAccessibilityIfNeeded() -> Bool {
        if AXIsProcessTrusted() {
            return true
        }
        // Show the system accessibility prompt (the only dialog needed)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        return false
    }
}
