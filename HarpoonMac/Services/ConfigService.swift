//
//  ConfigService.swift
//  HarpoonMac
//
//  Configuration management - reads/writes config.json from ~/.config/harpoon/
//

import Foundation

struct HarpoonConfig: Codable {
    var disableNativeCommandTab: Bool
    var leaderKey: String  // "command", "option", "control", "command+option"
    var pinnedWindows: [HarpoonWindow]
    var settings: Settings

    struct Settings: Codable {
        var launchAtLogin: Bool
    }

    static var `default`: HarpoonConfig {
        HarpoonConfig(
            disableNativeCommandTab: false,
            leaderKey: "command",
            pinnedWindows: [],
            settings: Settings(launchAtLogin: false)
        )
    }
}

class ConfigService {
    private let configDirectory: URL
    private let configFile: URL

    init() {
        // Use XDG_CONFIG_HOME or default to ~/.config/harpoon/
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let configHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? "\(homeDirectory.path)/.config"

        configDirectory = URL(fileURLWithPath: configHome).appendingPathComponent("harpoon")
        configFile = configDirectory.appendingPathComponent("config.json")

        // Create config directory if it doesn't exist
        createConfigDirectoryIfNeeded()
    }

    func createConfigDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: configDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
                print("✅ Created config directory: \(configDirectory.path)")
            } catch {
                print("❌ Failed to create config directory: \(error)")
            }
        }
    }

    func loadConfig() -> HarpoonConfig {
        guard FileManager.default.fileExists(atPath: configFile.path) else {
            print("ℹ️  No config file found, using defaults")
            let defaultConfig = HarpoonConfig.default
            saveConfig(defaultConfig)
            return defaultConfig
        }

        do {
            let data = try Data(contentsOf: configFile)
            let config = try JSONDecoder().decode(HarpoonConfig.self, from: data)
            print("✅ Loaded config from: \(configFile.path)")
            return config
        } catch {
            print("❌ Failed to load config: \(error)")
            print("ℹ️  Using default config")
            return HarpoonConfig.default
        }
    }

    func saveConfig(_ config: HarpoonConfig) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFile)
            print("✅ Saved config to: \(configFile.path)")
        } catch {
            print("❌ Failed to save config: \(error)")
        }
    }

    func updatePinnedWindows(_ windows: [HarpoonWindow]) {
        var config = loadConfig()
        config.pinnedWindows = windows
        saveConfig(config)
    }
}
