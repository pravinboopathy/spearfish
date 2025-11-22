//
//  AppDelegate.swift
//  HarpoonMac
//
//  App lifecycle and menu bar management
//

import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var appState: AppState?
    var pickerWindowController: PickerWindowController?

    // Services
    var configService: ConfigService?
    var windowService: WindowService?
    var harpoonService: HarpoonService?
    var hotkeyService: HotkeyService?
    var iconCacheService: IconCacheService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🎯 Harpoon macOS starting...")

        // Initialize app state
        appState = AppState()

        // Initialize services
        setupServices()

        // Create menu bar icon
        setupMenuBar()

        // Check for Accessibility permissions
        checkAccessibilityPermissions()

        print("✅ Harpoon macOS ready")
    }

    func setupServices() {
        // Initialize services in dependency order
        configService = ConfigService()
        iconCacheService = IconCacheService()
        windowService = WindowService(iconCache: iconCacheService!)
        harpoonService = HarpoonService(
            windowService: windowService!,
            configService: configService!,
            appState: appState
        )
        hotkeyService = HotkeyService(
            harpoonService: harpoonService!,
            appState: appState!
        )

        // Initialize picker window controller
        pickerWindowController = PickerWindowController(
            appState: appState!,
            harpoonService: harpoonService!,
            windowService: windowService!
        )

        // Load configuration and update app state
        let config = configService!.loadConfig()
        appState?.updatePinnedWindows(config.pinnedWindows)

        // Start hotkey monitoring
        hotkeyService?.start()

        // Setup picker visibility observer
        setupPickerObserver()
    }

    func setupPickerObserver() {
        print("🎬 Setting up picker observer")
        // Observe picker visibility changes
        appState?.$isPickerVisible.sink { [weak self] isVisible in
            print("👀 Picker visibility changed to: \(isVisible)")
            if isVisible {
                print("📂 Calling pickerWindowController.show()")
                self?.pickerWindowController?.show()
            } else {
                print("📪 Calling pickerWindowController.hide()")
                self?.pickerWindowController?.hide()
            }
        }.store(in: &cancellables)
        print("🎬 Picker observer setup complete")
    }

    private var cancellables = Set<AnyCancellable>()

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // TODO: Add custom icon
            button.image = NSImage(systemSymbolName: "target", accessibilityDescription: "Harpoon")
            button.action = #selector(menuBarIconClicked)
        }

        setupMenu()
    }

    func setupMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Mark Current Window", action: #selector(markCurrentWindow), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Show Harpoon Picker", action: #selector(showPicker), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Harpoon", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()

        if !trusted {
            print("⚠️  Accessibility permissions not granted")
            showAccessibilityAlert()
        } else {
            print("✅ Accessibility permissions granted")
        }
    }

    func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Harpoon needs Accessibility permissions to manage windows. Please grant permission in System Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Open System Preferences
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else {
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: - Menu Actions

    @objc func menuBarIconClicked() {
        // Toggle picker on menu bar icon click
        appState?.togglePicker()
    }

    @objc func markCurrentWindow() {
        harpoonService?.markCurrentWindow()
    }

    @objc func showPicker() {
        appState?.showPicker()
    }

    @objc func showSettings() {
        // TODO: Implement settings window
        print("Settings not yet implemented")
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
