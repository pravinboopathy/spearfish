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
    private let userDefaultsKey = "com.harpoon.mac.keybindConfiguration"

    @Published private(set) var configuration: KeybindConfiguration {
        didSet {
            saveConfiguration()
        }
    }

    // MARK: - Initialization

    init() {
        // Load configuration from UserDefaults or use default
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(KeybindConfiguration.self, from: data)
        {
            self.configuration = decoded
            logger.info("Loaded configuration from UserDefaults")
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

    private func saveConfiguration() {
        guard let encoded = try? JSONEncoder().encode(configuration) else {
            logger.error("Failed to encode configuration")
            return
        }

        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        logger.debug("Configuration saved to UserDefaults")
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
