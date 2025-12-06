//
//  HotkeyService.swift
//  HarpoonMac
//
//  Global keyboard event handling via CGEventTap
//

import Carbon
import Cocoa
import Combine
import OSLog

class HotkeyService {
    private let logger = Logger(subsystem: "com.harpoon.mac", category: "HotkeyService")
    private let harpoonService: HarpoonService
    private let appState: AppState
    private let configurationService: ConfigurationService
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var cancellables = Set<AnyCancellable>()

    init(harpoonService: HarpoonService, appState: AppState, configurationService: ConfigurationService) {
        self.harpoonService = harpoonService
        self.appState = appState
        self.configurationService = configurationService

        // Observe configuration changes and restart event tap
        setupConfigurationObserver()
    }

    // MARK: - Public API

    func start() {
        let hasAccess = checkAccessibility()
        logger.debug("Accessibility check result: \(hasAccess)")

        guard hasAccess else {
            logger.error("Cannot start hotkey service without Accessibility permissions")
            return
        }

        setupEventTap()

        if eventTap != nil {
            logger.info("Hotkey service started - Event tap created successfully")
        } else {
            logger.error("Hotkey service failed - Event tap is nil")
        }
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        logger.info("Hotkey service stopped")
    }

    // MARK: - Private Methods

    private func setupConfigurationObserver() {
        configurationService.$configuration
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                self?.logger.info("Configuration changed - restarting event tap")
                self?.restart()
            }
            .store(in: &cancellables)
    }

    private func restart() {
        logger.debug("Restarting hotkey service")
        stop()
        start()
    }

    private func checkAccessibility() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false
        ]
        return AXIsProcessTrustedWithOptions(options)
    }

    private func setupEventTap() {
        let eventMask =
            (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        // Create event tap callback
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
            return service.handleEvent(proxy: proxy, type: type, event: event)
        }

        // Create event tap
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else {
            logger.error("Failed to create event tap")
            return
        }

        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent)
        -> Unmanaged<CGEvent>?
    {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // Priority order: toggle picker -> picker keys -> quick jump -> mark window -> mark position
        if handleTogglePickerKey(keyCode: keyCode, flags: flags) { return nil }
        if appState.isPickerVisible {
            return handlePickerVisibleKeys(keyCode: keyCode, event: event)
        }
        if handleQuickJump(keyCode: keyCode, flags: flags) { return nil }
        if handleMarkWindowKey(keyCode: keyCode, flags: flags) { return nil }
        if handleMarkToPosition(keyCode: keyCode, flags: flags) { return nil }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Key Handlers

    /// Handle leader + toggle key to show/hide picker
    private func handleTogglePickerKey(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let config = configurationService.configuration
        guard config.matchesLeader(flags),
              keyCode == config.togglePickerKey.cgKeyCode else {
            return false
        }

        logger.debug("Toggle picker keybind detected")
        DispatchQueue.main.async { [weak self] in
            self?.appState.togglePicker()
        }
        return true
    }

    /// Handle keys when picker is visible (1-9 to jump, Escape to close)
    private func handlePickerVisibleKeys(keyCode: Int64, event: CGEvent) -> Unmanaged<CGEvent>? {
        if let number = getNumberFromKeyCode(keyCode) {
            DispatchQueue.main.async { [weak self] in
                self?.harpoonService.jumpToWindow(at: number)
                self?.appState.hidePicker()
            }
            return nil
        }

        if keyCode == Int64(kVK_Escape) {
            DispatchQueue.main.async { [weak self] in
                self?.appState.hidePicker()
            }
            return nil
        }

        // Let other keys pass through
        return Unmanaged.passUnretained(event)
    }

    /// Handle leader + number for quick jump (when picker is NOT visible)
    private func handleQuickJump(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let config = configurationService.configuration
        guard config.matchesModifiers(flags, additional: config.quickJumpModifiers),
              let number = getNumberFromKeyCode(keyCode) else {
            return false
        }

        DispatchQueue.main.async { [weak self] in
            self?.harpoonService.jumpToWindow(at: number)
        }
        return true
    }

    /// Handle leader + mark key to mark current window
    private func handleMarkWindowKey(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let config = configurationService.configuration
        guard config.matchesLeader(flags),
              keyCode == config.markWindowKey.cgKeyCode else {
            return false
        }

        DispatchQueue.main.async { [weak self] in
            self?.harpoonService.markCurrentWindow()
        }
        return true
    }

    /// Handle leader + shift + number to mark window at specific position
    private func handleMarkToPosition(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let config = configurationService.configuration
        guard config.matchesModifiers(flags, additional: config.markToPositionModifiers),
              let number = getNumberFromKeyCode(keyCode) else {
            return false
        }

        DispatchQueue.main.async { [weak self] in
            self?.harpoonService.markCurrentWindow(at: number)
        }
        return true
    }

    // MARK: - Helpers

    private func getNumberFromKeyCode(_ keyCode: Int64) -> Int? {
        switch keyCode {
        case Int64(kVK_ANSI_1): return 1
        case Int64(kVK_ANSI_2): return 2
        case Int64(kVK_ANSI_3): return 3
        case Int64(kVK_ANSI_4): return 4
        case Int64(kVK_ANSI_5): return 5
        case Int64(kVK_ANSI_6): return 6
        case Int64(kVK_ANSI_7): return 7
        case Int64(kVK_ANSI_8): return 8
        case Int64(kVK_ANSI_9): return 9
        default: return nil
        }
    }
}
