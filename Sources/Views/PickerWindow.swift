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
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.white)
                Text("Harpoon")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.3))

            // Window list
            VStack(spacing: 8) {
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
            .padding()

            // Footer with keybind hints
            VStack(alignment: .leading, spacing: 4) {
                Text("Press 1-9 to jump • ⎋ to cancel")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    KeybindHint(
                        label: "Toggle",
                        keybind: configurationService.configuration.togglePickerDisplayString()
                    )
                    KeybindHint(
                        label: "Mark",
                        keybind: configurationService.configuration.markWindowDisplayString()
                    )
                    KeybindHint(
                        label: "Quick Jump",
                        keybind: configurationService.configuration.quickJumpDisplayString()
                    )
                }
                .font(.caption2)
            }
            .padding()
            .background(Color.black.opacity(0.2))
        }
        .frame(width: UIConstants.Picker.width)
        .background(.ultraThinMaterial)  // GPU-accelerated blur
        .cornerRadius(UIConstants.Card.cornerRadius)
        .shadow(radius: 20)
        .drawingGroup()  // Force Metal rendering
    }
}

struct KeybindHint: View {
    let label: String
    let keybind: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundColor(.secondary)
            Text(keybind)
                .foregroundColor(.white)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
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
