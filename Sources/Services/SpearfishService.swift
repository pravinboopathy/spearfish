//
//  SpearfishService.swift
//  Spearfish
//
//  Core spearfish logic - manages pinned windows
//

import Foundation
import OSLog

class SpearfishService {
    private let logger = Logger(subsystem: "com.spearfish.mac", category: "SpearfishService")
    private let windowService: WindowService
    private var pinnedWindows: [SpearfishWindow] = []
    private weak var appState: AppState?

    init(windowService: WindowService, appState: AppState? = nil) {
        self.windowService = windowService
        self.appState = appState
    }

    // MARK: - Public API

    func getPinnedWindows() -> [SpearfishWindow] {
        return pinnedWindows
    }

    func markCurrentWindow() {
        guard let currentWindow = windowService.getCurrentWindow() else {
            logger.error("No current window to mark")
            appState?.showToast(.error("No focused window to mark"))
            return
        }

        // Find first empty slot (position 1-9)
        let existingPositions = Set(pinnedWindows.map { $0.position })
        guard let nextPosition = (1...9).first(where: { !existingPositions.contains($0) }) else {
            logger.error("All spearfish slots are full")
            appState?.showToast(.error("All slots full (1-9)"))
            return
        }

        markWindow(currentWindow, at: nextPosition)
    }

    func markCurrentWindow(at position: Int) {
        guard position >= 1 && position <= 9 else {
            logger.error("Invalid position: \(position)")
            appState?.showToast(.error("Invalid position: \(position)"))
            return
        }

        guard let currentWindow = windowService.getCurrentWindow() else {
            logger.error("No current window to mark")
            appState?.showToast(.error("No focused window to mark"))
            return
        }

        markWindow(currentWindow, at: position)
    }

    func markWindow(_ windowInfo: WindowInfo, at position: Int) {
        // Remove existing window at this position if any
        pinnedWindows.removeAll { $0.position == position }

        // Add new window
        let spearfishWindow = SpearfishWindow(position: position, windowInfo: windowInfo)
        pinnedWindows.append(spearfishWindow)

        // Sort by position
        pinnedWindows.sort { $0.position < $1.position }

        // Save to config
        savePinnedWindows()

        logger.info("Marked window '\(windowInfo.title)' at position \(position)")
        appState?.showToast(.success("Marked to position \(position)"))
    }

    func removeWindow(at position: Int) {
        pinnedWindows.removeAll { $0.position == position }
        savePinnedWindows()
        logger.info("Removed window at position \(position)")
    }

    func jumpToWindow(at position: Int) {
        guard let spearfishWindow = pinnedWindows.first(where: { $0.position == position }) else {
            logger.error("No window at position \(position)")
            appState?.showToast(.error("No window at position \(position)"))
            return
        }

        // Check if window still exists
        guard windowService.isWindowValid(spearfishWindow.cgWindowId) else {
            logger.error("Window no longer exists: \(spearfishWindow.windowTitle)")
            appState?.showToast(.error("Window no longer exists"))
            // Remove from list
            removeWindow(at: position)
            return
        }

        // Create WindowInfo from SpearfishWindow
        let windowInfo = WindowInfo(
            cgWindowId: spearfishWindow.cgWindowId,
            pid: spearfishWindow.pid,
            bundleId: spearfishWindow.bundleId,
            title: spearfishWindow.windowTitle,
            appName: spearfishWindow.appName
        )

        // Activate window
        windowService.activateWindow(windowInfo)

        // Update last accessed time
        if let index = pinnedWindows.firstIndex(where: { $0.id == spearfishWindow.id }) {
            pinnedWindows[index].lastAccessed = Date()
            savePinnedWindows()
        }
    }

    func validateWindows() {
        // Query window list once and build set of valid IDs
        let validWindowIds = Set(windowService.getAllWindows().map { $0.cgWindowId })

        // Filter pinned windows against the set
        let validWindows = pinnedWindows.filter { validWindowIds.contains($0.cgWindowId) }

        if validWindows.count != pinnedWindows.count {
            let removedCount = pinnedWindows.count - validWindows.count
            pinnedWindows = validWindows
            savePinnedWindows()
            logger.info("Cleaned up \(removedCount) closed windows")
        }
    }

    // MARK: - Private Methods

    private func savePinnedWindows() {
        // Update app state to reflect changes
        appState?.updatePinnedWindows(pinnedWindows)

        // Prune unused icons from cache
        let activeBundleIds = Set(pinnedWindows.map { $0.bundleId })
        windowService.pruneIconCache(keeping: activeBundleIds)
    }
}
