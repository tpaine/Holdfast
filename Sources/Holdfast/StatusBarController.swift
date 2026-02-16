import AppKit
import ServiceManagement

class StatusBarController {
    private let statusItem: NSStatusItem
    private let preferences: Preferences
    private var modifierItems: [NSMenuItem] = []

    init(preferences: Preferences) {
        self.preferences = preferences
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: "Holdfast")
        }

        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(title: "Modifier Key", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        for key in ModifierKey.allCases {
            let item = NSMenuItem(title: key.label, action: #selector(modifierSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = key.rawValue
            item.state = preferences.modifierKey == key ? .on : .off
            modifierItems.append(item)
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Holdfast", action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func modifierSelected(_ sender: NSMenuItem) {
        guard let key = ModifierKey(rawValue: sender.tag) else { return }
        preferences.modifierKey = key
        for item in modifierItems {
            item.state = item.tag == key.rawValue ? .on : .off
        }
    }

    @objc private func toggleLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Login Item Error"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}
