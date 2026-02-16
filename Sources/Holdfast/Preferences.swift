import AppKit
import Carbon.HIToolbox

enum ModifierKey: Int, CaseIterable {
    case option = 0
    case control = 1
    case command = 2

    var label: String {
        switch self {
        case .control: return "⌃ Control"
        case .option: return "⌥ Option"
        case .command: return "⌘ Command"
        }
    }

    var cgEventFlag: CGEventFlags {
        switch self {
        case .control: return .maskControl
        case .option: return .maskAlternate
        case .command: return .maskCommand
        }
    }
}

class Preferences {
    private let modifierKeyKey = "modifierKey"
    private let defaults = UserDefaults.standard

    var modifierKey: ModifierKey {
        get {
            let raw = defaults.integer(forKey: modifierKeyKey)
            return ModifierKey(rawValue: raw) ?? .option
        }
        set {
            defaults.set(newValue.rawValue, forKey: modifierKeyKey)
        }
    }
}
