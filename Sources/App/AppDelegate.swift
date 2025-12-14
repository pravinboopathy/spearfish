//
//  AppDelegate.swift
//  Spearfish
//
//  App lifecycle and menu bar management
//

import Cocoa
import Combine
import SwiftUI
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.spearfish.mac", category: "AppDelegate")
    var statusItem: NSStatusItem?
    var appState: AppState?
    var pickerWindowController: PickerWindowController?
    var toastWindowController: ToastWindowController?

    // Services
    var configurationService: ConfigurationService?
    var windowService: WindowService?
    var spearfishService: SpearfishService?
    var hotkeyService: HotkeyService?
    var iconCacheService: IconCacheService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Spearfish macOS starting")

        // Initialize app state
        appState = AppState()

        // Initialize services
        setupServices()

        // Create menu bar icon
        setupMenuBar()

        // Check for Accessibility permissions
        checkAccessibilityPermissions()

        logger.info("Spearfish macOS ready")
    }

    func setupServices() {
        // Initialize services in dependency order using local variables
        let config = ConfigurationService()
        let iconCache = IconCacheService()
        let window = WindowService(iconCache: iconCache)
        let spearfish = SpearfishService(windowService: window, appState: appState)
        let hotkey = HotkeyService(
            spearfishService: spearfish,
            appState: appState!,
            configurationService: config
        )
        let picker = PickerWindowController(
            appState: appState!,
            configurationService: config,
            spearfishService: spearfish,
            windowService: window
        )
        let toast = ToastWindowController(appState: appState!)

        // Assign to instance properties
        configurationService = config
        iconCacheService = iconCache
        windowService = window
        spearfishService = spearfish
        hotkeyService = hotkey
        pickerWindowController = picker
        toastWindowController = toast

        // Start hotkey monitoring
        hotkeyService?.start()

        // Setup picker visibility observer
        setupPickerObserver()
    }

    func setupPickerObserver() {
        logger.debug("Setting up picker observer")
        // Observe picker visibility changes
        appState?.$isPickerVisible.sink { [weak self] isVisible in
            self?.logger.debug("Picker visibility changed to: \(isVisible)")
            if isVisible {
                self?.logger.debug("Calling pickerWindowController.show()")
                self?.pickerWindowController?.show()
            } else {
                self?.logger.debug("Calling pickerWindowController.hide()")
                self?.pickerWindowController?.hide()
            }
        }.store(in: &cancellables)
        logger.debug("Picker observer setup complete")
    }

    private var cancellables = Set<AnyCancellable>()

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            let icon = NSImage.menuBarIcon
            icon.size = NSSize(width: 18, height: 18)
            button.image = icon
            button.action = #selector(menuBarIconClicked)
        }

        setupMenu()
    }

    func setupMenu() {
        let menu = NSMenu()

        menu.addItem(
            NSMenuItem(
                title: "Mark Current Window", action: #selector(markCurrentWindow),
                keyEquivalent: "m"))
        menu.addItem(
            NSMenuItem(
                title: "Show Spearfish Picker", action: #selector(showPicker), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Spearfish", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()

        if !trusted {
            logger.error("Accessibility permissions not granted")
            showAccessibilityAlert()
        } else {
            logger.info("Accessibility permissions granted")
        }
    }

    func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText =
            "Spearfish needs Accessibility permissions to manage windows. Please grant permission in System Settings, then reopen the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Open System Settings
            let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }

        // Quit in both cases - user will reopen after granting permission
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Menu Actions

    @objc func menuBarIconClicked() {
        // Toggle picker on menu bar icon click
        appState?.togglePicker()
    }

    @objc func markCurrentWindow() {
        spearfishService?.markCurrentWindow()
    }

    @objc func showPicker() {
        appState?.showPicker()
    }

    @objc func showSettings() {
        logger.info("Settings not yet implemented")
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSImage Extension for SVG Loading

extension NSImage {
    static var menuBarIcon: NSImage = {
        let url = Bundle.module.url(forResource: "SpearfishIcon", withExtension: "svg")!
        let image = NSImage(contentsOf: url)!
        image.isTemplate = true
        return image
    }()
}
