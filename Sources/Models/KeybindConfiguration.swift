//
//  KeybindConfiguration.swift
//  HarpoonMac
//
//  Keybind configuration model
//

import Carbon
import Foundation

struct KeybindConfiguration: Codable, Equatable {
    // MARK: - Configuration Properties

    /// Leader modifier key (Option, Control, Command, Shift)
    var leaderModifier: ModifierKey

    /// Key to toggle picker (with leader)
    var togglePickerKey: KeyCode

    /// Key to mark current window (with leader)
    var markWindowKey: KeyCode

    /// Additional modifiers required for quick jump (leader+number)
    var quickJumpModifiers: ModifierSet

    /// Additional modifiers required for mark to position (leader+shift+number)
    var markToPositionModifiers: ModifierSet

    // MARK: - Default Configuration

    static let `default` = KeybindConfiguration(
        leaderModifier: .control,
        togglePickerKey: .h,                      // Ctrl+H to toggle picker
        markWindowKey: .m,                        // Ctrl+M to mark ("harpoon")
        quickJumpModifiers: [],                   // Ctrl+1-9 to quick jump
        markToPositionModifiers: [.option]        // Ctrl+Option+1-9 to mark at position
    )

    // MARK: - Modifier Key Definition

    enum ModifierKey: String, Codable {
        case option
        case control
        case command
        case shift

        var cgEventFlag: CGEventFlags {
            switch self {
            case .option: return .maskAlternate
            case .control: return .maskControl
            case .command: return .maskCommand
            case .shift: return .maskShift
            }
        }

        var displayName: String {
            switch self {
            case .option: return "⌥"
            case .control: return "⌃"
            case .command: return "⌘"
            case .shift: return "⇧"
            }
        }
    }

    // MARK: - Modifier Set

    struct ModifierSet: Equatable, OptionSet, Codable {
        let rawValue: Int

        static let shift = ModifierSet(rawValue: 1 << 0)
        static let control = ModifierSet(rawValue: 1 << 1)
        static let option = ModifierSet(rawValue: 1 << 2)
        static let command = ModifierSet(rawValue: 1 << 3)

        private static let allModifiers: [(ModifierSet, String)] = [
            (.shift, "shift"), (.control, "control"), (.option, "option"), (.command, "command")
        ]

        init(rawValue: Int) {
            self.rawValue = rawValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let names = try container.decode([String].self)
            var result = 0
            for (modifier, name) in Self.allModifiers {
                if names.contains(name) { result |= modifier.rawValue }
            }
            self.rawValue = result
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            var names: [String] = []
            for (modifier, name) in Self.allModifiers {
                if contains(modifier) { names.append(name) }
            }
            try container.encode(names)
        }

        func toCGEventFlags() -> CGEventFlags {
            var flags = CGEventFlags()
            if contains(.shift) { flags.insert(.maskShift) }
            if contains(.control) { flags.insert(.maskControl) }
            if contains(.option) { flags.insert(.maskAlternate) }
            if contains(.command) { flags.insert(.maskCommand) }
            return flags
        }

        var displayName: String {
            var parts: [String] = []
            if contains(.control) { parts.append("⌃") }
            if contains(.option) { parts.append("⌥") }
            if contains(.shift) { parts.append("⇧") }
            if contains(.command) { parts.append("⌘") }
            return parts.isEmpty ? "" : parts.joined()
        }
    }

    // MARK: - Key Code Definition

    enum KeyCode: String, Codable {
        case tab, h, m, escape
        case one, two, three, four, five, six, seven, eight, nine

        var cgKeyCode: Int64 {
            switch self {
            case .tab: return 48
            case .h: return 4
            case .m: return 46
            case .escape: return 53
            case .one: return 18
            case .two: return 19
            case .three: return 20
            case .four: return 21
            case .five: return 23
            case .six: return 22
            case .seven: return 26
            case .eight: return 28
            case .nine: return 25
            }
        }

        var displayName: String {
            switch self {
            case .tab: return "⇥"
            case .h: return "H"
            case .m: return "M"
            case .escape: return "⎋"
            case .one: return "1"
            case .two: return "2"
            case .three: return "3"
            case .four: return "4"
            case .five: return "5"
            case .six: return "6"
            case .seven: return "7"
            case .eight: return "8"
            case .nine: return "9"
            }
        }
    }

    // MARK: - Helper Methods

    /// Check if event flags match the leader modifier
    func matchesLeader(_ flags: CGEventFlags) -> Bool {
        return flags.contains(leaderModifier.cgEventFlag)
    }

    /// Check if event flags match leader + additional modifiers
    func matchesModifiers(_ flags: CGEventFlags, additional: ModifierSet) -> Bool {
        guard matchesLeader(flags) else { return false }

        let additionalFlags = additional.toCGEventFlags()

        // Check that all required additional modifiers are present
        for flag in [CGEventFlags.maskShift, .maskControl, .maskAlternate, .maskCommand] {
            if additionalFlags.contains(flag) && !flags.contains(flag) {
                return false
            }
        }

        // Check that no unrequired modifiers are present (except leader)
        // Allow leader modifier to be present
        let allowedFlags = additionalFlags.union(leaderModifier.cgEventFlag)
        let presentModifiers = flags.intersection([.maskShift, .maskControl, .maskCommand, .maskAlternate])

        // Every present modifier must be in allowed flags
        return presentModifiers.isSubset(of: allowedFlags)
    }

    /// Get display string for toggle picker keybind
    func togglePickerDisplayString() -> String {
        return "\(leaderModifier.displayName)\(togglePickerKey.displayName)"
    }

    /// Get display string for mark window keybind
    func markWindowDisplayString() -> String {
        return "\(leaderModifier.displayName)\(markWindowKey.displayName)"
    }

    /// Get display string for quick jump keybind
    func quickJumpDisplayString() -> String {
        let additional = quickJumpModifiers.displayName
        return additional.isEmpty ? "\(leaderModifier.displayName)1-9" : "\(leaderModifier.displayName)\(additional)1-9"
    }

    /// Get display string for mark to position keybind
    func markToPositionDisplayString() -> String {
        let additional = markToPositionModifiers.displayName
        return "\(leaderModifier.displayName)\(additional)1-9"
    }

    // MARK: - Validation

    func validate() -> [String] {
        var errors: [String] = []

        // Prevent using same key for multiple actions
        if togglePickerKey == markWindowKey {
            errors.append("Toggle picker and mark window cannot use the same key")
        }

        // Prevent using leader modifier as additional modifier
        if case .shift = leaderModifier, markToPositionModifiers.contains(.shift) {
            errors.append("Cannot use shift as both leader and additional modifier")
        }

        return errors
    }
}
