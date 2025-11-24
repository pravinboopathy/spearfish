//
//  WindowService.swift
//  HarpoonMac
//
//  Window operations via Accessibility API
//

import Cocoa
import ApplicationServices

class WindowService {
    private let iconCache: IconCacheService

    init(iconCache: IconCacheService) {
        self.iconCache = iconCache
    }

    // MARK: - Window Enumeration

    func getAllWindows() -> [WindowInfo] {
        var windows: [WindowInfo] = []

        // Get all running applications
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }

            // Create AX UI element for the application
            let appElement = AXUIElementCreateApplication(app.processIdentifier)

            // Get windows for this app
            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

            guard result == .success,
                  let windowArray = windowsRef as? [AXUIElement] else {
                continue
            }

            for windowRef in windowArray {
                if let windowInfo = getWindowInfo(windowRef: windowRef, bundleId: bundleId, appName: app.localizedName ?? "Unknown") {
                    windows.append(windowInfo)
                }
            }
        }

        return windows
    }

    func getCurrentWindow() -> WindowInfo? {
        // Get the frontmost application
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontApp.bundleIdentifier else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Get focused window
        var focusedWindowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef)

        guard result == .success,
              let windowRef = focusedWindowRef else {
            return nil
        }

        return getWindowInfo(windowRef: windowRef as! AXUIElement, bundleId: bundleId, appName: frontApp.localizedName ?? "Unknown")
    }

    private func getWindowInfo(windowRef: AXUIElement, bundleId: String, appName: String) -> WindowInfo? {
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute as CFString, &titleRef)

        guard let title = titleRef as? String, !title.isEmpty else {
            return nil
        }

        return WindowInfo(
            bundleId: bundleId,
            title: title,
            appName: appName,
            windowRef: windowRef
        )
    }

    // MARK: - Window Activation

    func activateWindow(_ windowInfo: WindowInfo) {
        // Find the window and activate it
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.bundleIdentifier == windowInfo.bundleId }) else {
            print("❌ App not found: \(windowInfo.bundleId)")
            return
        }

        // Activate the application
        app.activate(options: [.activateIgnoringOtherApps])

        // Find and focus the specific window
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
              let windowArray = windowsRef as? [AXUIElement] else {
            return
        }

        for windowRef in windowArray {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute as CFString, &titleRef)

            if let title = titleRef as? String, title == windowInfo.title {
                // Focus this window
                AXUIElementSetAttributeValue(windowRef, kAXMainAttribute as CFString, true as CFTypeRef)
                AXUIElementPerformAction(windowRef, kAXRaiseAction as CFString)
                print("✅ Activated window: \(title)")
                return
            }
        }
    }

    // MARK: - Window Matching

    func findWindow(for harpoonWindow: HarpoonWindow) -> WindowInfo? {
        let allWindows = getAllWindows()

        // Try exact match first
        if let exactMatch = allWindows.first(where: {
            $0.bundleId == harpoonWindow.bundleId && $0.title == harpoonWindow.windowTitle
        }) {
            return exactMatch
        }

        // Try fuzzy match on title
        if let fuzzyMatch = allWindows.first(where: {
            $0.bundleId == harpoonWindow.bundleId &&
            fuzzyMatchTitle($0.title, harpoonWindow.windowTitle)
        }) {
            return fuzzyMatch
        }

        return nil
    }

    private func fuzzyMatchTitle(_ title1: String, _ title2: String) -> Bool {
        // Simple fuzzy matching - remove common suffixes and compare
        let cleaned1 = title1.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " •", with: "")
        let cleaned2 = title2.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " •", with: "")
        return cleaned1.contains(cleaned2) || cleaned2.contains(cleaned1)
    }

    // MARK: - App Icons

    func getIcon(for bundleId: String) -> NSImage? {
        return iconCache.getIcon(for: bundleId)
    }
}
