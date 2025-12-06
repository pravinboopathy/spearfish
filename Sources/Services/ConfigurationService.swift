//
//  ConfigurationService.swift
//  HarpoonMac
//
//  Configuration persistence and observation
//

import Combine
import Foundation
import OSLog

class ConfigurationService: ObservableObject {
    private let logger = Logger(subsystem: "com.harpoon.mac", category: "ConfigurationService")

    @Published private(set) var configuration: KeybindConfiguration {
        didSet {
            saveConfiguration()
        }
    }

    // MARK: - Config File Paths

    private static var configDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/harpoon_mac")
    }

    private static var configFileURL: URL {
        configDirectoryURL.appendingPathComponent("config.json")
    }

    // MARK: - Initialization

    init() {
        // Load configuration from file or use default
        if let data = try? Data(contentsOf: Self.configFileURL),
           let decoded = try? JSONDecoder().decode(KeybindConfiguration.self, from: data)
        {
            self.configuration = decoded
            logger.info("Loaded configuration from \(Self.configFileURL.path)")
        } else {
            self.configuration = .default
            logger.info("Using default configuration")
            saveConfiguration()
        }
    }

    // MARK: - Public API

    /// Update configuration with validation
    func updateConfiguration(_ newConfiguration: KeybindConfiguration) throws {
        let errors = newConfiguration.validate()
        guard errors.isEmpty else {
            logger.error("Configuration validation failed: \(errors.joined(separator: ", "))")
            throw ConfigurationError.validationFailed(errors)
        }

        logger.info("Updating configuration")
        self.configuration = newConfiguration
    }

    /// Reset configuration to defaults
    func resetToDefaults() {
        logger.info("Resetting configuration to defaults")
        self.configuration = .default
    }

    // MARK: - Private Methods

    private func ensureConfigDirectoryExists() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: Self.configDirectoryURL.path) {
            try fileManager.createDirectory(at: Self.configDirectoryURL, withIntermediateDirectories: true)
            logger.debug("Created config directory at \(Self.configDirectoryURL.path)")
        }
    }

    private func saveConfiguration() {
        do {
            try ensureConfigDirectoryExists()

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(configuration)

            try data.write(to: Self.configFileURL, options: .atomic)
            logger.debug("Configuration saved to \(Self.configFileURL.path)")
        } catch {
            logger.error("Failed to save configuration: \(error.localizedDescription)")
        }
    }

    // MARK: - Error Types

    enum ConfigurationError: Error, LocalizedError {
        case validationFailed([String])

        var errorDescription: String? {
            switch self {
            case .validationFailed(let errors):
                return "Configuration validation failed: \(errors.joined(separator: ", "))"
            }
        }
    }
}
