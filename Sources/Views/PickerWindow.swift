//
//  PickerWindow.swift
//  HarpoonMac
//
//  GPU-optimized vertical picker UI
//

import SwiftUI

struct PickerView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var configurationService: ConfigurationService
    let harpoonService: HarpoonService
    let windowService: WindowService

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text("HarpoonMac")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("⎋ close")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.03))

            // Window list
            VStack(spacing: 6) {
                ForEach(1...9, id: \.self) { position in
                    if let window = appState.pinnedWindows.first(where: { $0.position == position }) {
                        WindowCardView(
                            window: window,
                            icon: windowService.getIcon(for: window.bundleId)
                        )
                    } else {
                        EmptySlotView(
                            position: position,
                            markKeybind: configurationService.configuration.markWindowDisplayString()
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Footer with keybind hints
            HStack(spacing: 16) {
                KeybindHint(
                    label: "Toggle",
                    keybind: configurationService.configuration.togglePickerDisplayString()
                )
                KeybindHint(
                    label: "Mark",
                    keybind: configurationService.configuration.markWindowDisplayString()
                )
                KeybindHint(
                    label: "Jump",
                    keybind: configurationService.configuration.quickJumpDisplayString()
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.03))
        }
        .frame(width: UIConstants.Picker.width)
        .background(.ultraThinMaterial)  // GPU-accelerated blur
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
        .drawingGroup()  // Force Metal rendering
    }
}

struct KeybindHint: View {
    let label: String
    let keybind: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
            Text(keybind)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .cornerRadius(5)
        }
    }
}

class PickerWindowController {
    private var window: NSWindow?
    private let appState: AppState
    private let configurationService: ConfigurationService
    private let harpoonService: HarpoonService
    private let windowService: WindowService

    init(
        appState: AppState,
        configurationService: ConfigurationService,
        harpoonService: HarpoonService,
        windowService: WindowService
    ) {
        self.appState = appState
        self.configurationService = configurationService
        self.harpoonService = harpoonService
        self.windowService = windowService
    }

    func show() {
        if window == nil {
            createWindow()
        }

        window?.makeKeyAndOrderFront(nil)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func createWindow() {
        let contentView = PickerView(
            appState: appState,
            configurationService: configurationService,
            harpoonService: harpoonService,
            windowService: windowService
        )

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: UIConstants.Picker.width, height: UIConstants.Picker.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .popUpMenu  // Higher level to stay above screenshot tool
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false  // Don't hide when app loses focus
        panel.contentView = NSHostingView(rootView: contentView)

        window = panel

        // Store window reference in app state
        appState.pickerWindow = window
    }
}
