//
//  HotkeyService.swift
//  HarpoonMac
//
//  Global keyboard event handling via CGEventTap
//

import Cocoa
import Carbon

class HotkeyService {
    private let harpoonService: HarpoonService
    private let appState: AppState
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(harpoonService: HarpoonService, appState: AppState) {
        self.harpoonService = harpoonService
        self.appState = appState
    }

    // MARK: - Public API

    func start() {
        let hasAccess = checkAccessibility()
        print("🔍 Accessibility check result: \(hasAccess)")

        guard hasAccess else {
            print("❌ Cannot start hotkey service without Accessibility permissions")
            return
        }

        setupEventTap()

        if eventTap != nil {
            print("✅ Hotkey service started - Event tap created successfully")
        } else {
            print("❌ Hotkey service failed - Event tap is nil")
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

        print("⏸️  Hotkey service stopped")
    }

    // MARK: - Private Methods

    private func checkAccessibility() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false]
        return AXIsProcessTrustedWithOptions(options)
    }

    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

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
            print("❌ Failed to create event tap")
            return
        }

        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle key down events
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags

            // Check for Cmd+` (toggle picker)
            if flags.contains(.maskCommand) {
                print("🎹 Cmd key pressed with keyCode: \(keyCode), kVK_ANSI_Grave: \(kVK_ANSI_Grave)")
                if keyCode == Int64(kVK_ANSI_Grave) {  // Backtick key (`)
                    print("🎯 Cmd+` detected - toggling picker!")
                    handleTogglePicker()
                    return nil  // Suppress event
                }
            }

            // Check for number keys when picker is visible
            if appState.isPickerVisible {
                if let number = getNumberFromKeyCode(keyCode) {
                    handleNumberKey(number)
                    appState.hidePicker()
                    return nil  // Suppress event
                }

                // Handle Escape to close picker
                if keyCode == Int64(kVK_Escape) {
                    appState.hidePicker()
                    return nil
                }
            }

            // Check for Leader+1-9 (quick jump)
            if flags.contains(.maskCommand) {
                if let number = getNumberFromKeyCode(keyCode) {
                    handleQuickJump(number)
                    return nil  // Suppress event
                }
            }

            // Check for Cmd+Shift+M (mark current window)
            if flags.contains(.maskCommand) && flags.contains(.maskShift) {
                if keyCode == Int64(kVK_ANSI_M) {
                    harpoonService.markCurrentWindow()
                    return nil
                }

                // Check for Cmd+Shift+1-9 (mark to specific position)
                if let number = getNumberFromKeyCode(keyCode) {
                    harpoonService.markCurrentWindow(at: number)
                    return nil
                }
            }
        }

        // Pass through other events
        return Unmanaged.passUnretained(event)
    }

    private func handleTogglePicker() {
        print("🔄 handleTogglePicker called")
        DispatchQueue.main.async { [weak self] in
            print("📱 About to toggle picker on main thread")
            self?.appState.togglePicker()
            print("📱 Picker toggled - isVisible: \(self?.appState.isPickerVisible ?? false)")
        }
    }

    private func handleNumberKey(_ number: Int) {
        harpoonService.jumpToWindow(at: number)
    }

    private func handleQuickJump(_ number: Int) {
        harpoonService.jumpToWindow(at: number)
    }

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
