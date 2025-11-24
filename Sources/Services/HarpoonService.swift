//
//  HarpoonService.swift
//  HarpoonMac
//
//  Core harpoon logic - manages pinned windows
//

import Foundation

class HarpoonService {
    private let windowService: WindowService
    private let configService: ConfigService
    private var pinnedWindows: [HarpoonWindow] = []
    private weak var appState: AppState?

    init(windowService: WindowService, configService: ConfigService, appState: AppState? = nil) {
        self.windowService = windowService
        self.configService = configService
        self.appState = appState

        // Load pinned windows from config
        loadPinnedWindows()
    }

    // MARK: - Public API

    func getPinnedWindows() -> [HarpoonWindow] {
        return pinnedWindows
    }

    func markCurrentWindow() {
        guard let currentWindow = windowService.getCurrentWindow() else {
            print("❌ No current window to mark")
            return
        }

        // Find first empty slot (position 1-9)
        let existingPositions = Set(pinnedWindows.map { $0.position })
        guard let nextPosition = (1...9).first(where: { !existingPositions.contains($0) }) else {
            print("❌ All harpoon slots are full")
            return
        }

        markWindow(currentWindow, at: nextPosition)
    }

    func markCurrentWindow(at position: Int) {
        guard position >= 1 && position <= 9 else {
            print("❌ Invalid position: \(position)")
            return
        }

        guard let currentWindow = windowService.getCurrentWindow() else {
            print("❌ No current window to mark")
            return
        }

        markWindow(currentWindow, at: position)
    }

    func markWindow(_ windowInfo: WindowInfo, at position: Int) {
        // Remove existing window at this position if any
        pinnedWindows.removeAll { $0.position == position }

        // Add new window
        let harpoonWindow = HarpoonWindow(position: position, windowInfo: windowInfo)
        pinnedWindows.append(harpoonWindow)

        // Sort by position
        pinnedWindows.sort { $0.position < $1.position }

        // Save to config
        savePinnedWindows()

        print("✅ Marked window '\(windowInfo.title)' at position \(position)")
    }

    func removeWindow(at position: Int) {
        pinnedWindows.removeAll { $0.position == position }
        savePinnedWindows()
        print("✅ Removed window at position \(position)")
    }

    func jumpToWindow(at position: Int) {
        guard let harpoonWindow = pinnedWindows.first(where: { $0.position == position }) else {
            print("❌ No window at position \(position)")
            return
        }

        // Find actual window
        guard let windowInfo = windowService.findWindow(for: harpoonWindow) else {
            print("❌ Window not found: \(harpoonWindow.windowTitle)")
            return
        }

        // Activate window
        windowService.activateWindow(windowInfo)

        // Update last accessed time
        if let index = pinnedWindows.firstIndex(where: { $0.id == harpoonWindow.id }) {
            pinnedWindows[index].lastAccessed = Date()
            savePinnedWindows()
        }
    }

    func validateWindows() {
        // Remove windows that no longer exist
        let validWindows = pinnedWindows.filter { window in
            windowService.findWindow(for: window) != nil
        }

        if validWindows.count != pinnedWindows.count {
            pinnedWindows = validWindows
            savePinnedWindows()
            print("ℹ️  Cleaned up \(pinnedWindows.count - validWindows.count) closed windows")
        }
    }

    // MARK: - Private Methods

    private func loadPinnedWindows() {
        let config = configService.loadConfig()
        pinnedWindows = config.pinnedWindows
        print("✅ Loaded \(pinnedWindows.count) pinned windows")
    }

    private func savePinnedWindows() {
        configService.updatePinnedWindows(pinnedWindows)
        appState?.updatePinnedWindows(pinnedWindows)
    }
}
