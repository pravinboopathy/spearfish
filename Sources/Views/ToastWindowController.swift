//
//  ToastWindowController.swift
//  HarpoonMac
//
//  Manages the floating toast notification window
//

import Combine
import SwiftUI

class ToastWindowController {
    private var window: NSPanel?
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    private var dismissTimer: Timer?

    init(appState: AppState) {
        self.appState = appState
        setupObserver()
    }

    private func setupObserver() {
        appState.$currentToast
            .receive(on: DispatchQueue.main)
            .sink { [weak self] toast in
                if let toast = toast {
                    self?.show(toast: toast)
                } else {
                    self?.hide()
                }
            }
            .store(in: &cancellables)
    }

    private func show(toast: Toast) {
        // Cancel any existing dismiss timer
        dismissTimer?.invalidate()

        if window == nil {
            createWindow()
        }

        // Update content
        window?.contentView = NSHostingView(rootView: ToastContentView(toast: toast))

        // Position at bottom center of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (UIConstants.Toast.width / 2)
            let y = screenFrame.minY + UIConstants.Toast.bottomOffset

            window?.setFrame(NSRect(x: x, y: y, width: UIConstants.Toast.width, height: UIConstants.Toast.height), display: true)
        }

        window?.orderFront(nil)

        // Auto-dismiss after 1 second
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.appState.dismissToast()
        }
    }

    private func hide() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        window?.orderOut(nil)
    }

    private func createWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: UIConstants.Toast.width, height: UIConstants.Toast.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false

        window = panel
    }
}

// MARK: - Toast Content View

private struct ToastContentView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.title2)
                .foregroundColor(iconColor)

            Text(toast.message)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(UIConstants.Toast.cornerRadius)
        .shadow(radius: 10)
    }

    private var iconColor: Color {
        switch toast.type {
        case .success: return .green
        case .error: return .orange
        case .info: return .blue
        }
    }

    private var backgroundColor: Color {
        Color.black.opacity(0.8)
    }
}
