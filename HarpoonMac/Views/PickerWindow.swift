//
//  PickerWindow.swift
//  HarpoonMac
//
//  GPU-optimized vertical picker UI
//

import SwiftUI

struct PickerView: View {
    @ObservedObject var appState: AppState
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
                        EmptySlotView(position: position)
                    }
                }
            }
            .padding()
        }
        .frame(width: 400)
        .background(.ultraThinMaterial)  // GPU-accelerated blur
        .cornerRadius(12)
        .shadow(radius: 20)
        .drawingGroup()  // Force Metal rendering
    }
}

class PickerWindowController {
    private var window: NSWindow?
    private let appState: AppState
    private let harpoonService: HarpoonService
    private let windowService: WindowService

    init(appState: AppState, harpoonService: HarpoonService, windowService: WindowService) {
        self.appState = appState
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
            harpoonService: harpoonService,
            windowService: windowService
        )

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.level = .floating
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.contentView = NSHostingView(rootView: contentView)

        // Store window reference in app state
        appState.pickerWindow = window
    }
}
