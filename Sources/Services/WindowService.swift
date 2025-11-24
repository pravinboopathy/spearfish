//
//  WindowService.swift
//  HarpoonMac
//
//  Window operations via Accessibility API
//

import Cocoa
import ApplicationServices

// Private Accessibility API for CGWindowID <-> AXUIElement conversion
@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ windowId: UnsafeMutablePointer<CGWindowID>) -> AXError

class WindowService {
    private let iconCache: IconCacheService

    init(iconCache: IconCacheService) {
        self.iconCache = iconCache
    }

    // MARK: - Window Enumeration

    func getAllWindows() -> [WindowInfo] {
        var windows: [WindowInfo] = []

        // Get all on-screen windows from CG Window API
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[CFString: Any]] else {
            return []
        }

        for windowDict in windowList {
            // Extract window properties
            guard let cgWindowId = windowDict[kCGWindowNumber] as? CGWindowID,
                  let pid = windowDict[kCGWindowOwnerPID] as? pid_t,
                  let layer = windowDict[kCGWindowLayer] as? Int,
                  let ownerName = windowDict[kCGWindowOwnerName] as? String,
                  let windowTitle = windowDict[kCGWindowName] as? String else {
                continue
            }

            // Filter to normal windows (layer 0) with titles
            guard layer == 0, !windowTitle.isEmpty else {
                continue
            }

            // Get bundle ID from running application
            let runningApp = NSWorkspace.shared.runningApplications.first { $0.processIdentifier == pid }
            let bundleId = runningApp?.bundleIdentifier ?? ""

            let windowInfo = WindowInfo(
                cgWindowId: cgWindowId,
                pid: pid,
                bundleId: bundleId,
                title: windowTitle,
                appName: ownerName
            )
            windows.append(windowInfo)
        }

        return windows
    }

    func getCurrentWindow() -> WindowInfo? {
        // Get the frontmost application
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontApp.bundleIdentifier else {
            return nil
        }

        let pid = frontApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        // Get focused window via AX API
        var focusedWindowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success,
              let axWindow = focusedWindowRef else {
            return nil
        }

        let axWindowElement = axWindow as! AXUIElement

        // Get window title
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axWindowElement, kAXTitleAttribute as CFString, &titleRef)
        guard let title = titleRef as? String, !title.isEmpty else {
            return nil
        }

        // Convert AXUIElement to CGWindowID using private API
        var cgWindowId: CGWindowID = 0
        guard _AXUIElementGetWindow(axWindowElement, &cgWindowId) == .success else {
            return nil
        }

        return WindowInfo(
            cgWindowId: cgWindowId,
            pid: pid,
            bundleId: bundleId,
            title: title,
            appName: frontApp.localizedName ?? "Unknown"
        )
    }

    // MARK: - Window Activation

    private func getAXUIElement(for cgWindowId: CGWindowID, pid: pid_t) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let axWindows = windowsRef as? [AXUIElement] else {
            return nil
        }

        for axWindow in axWindows {
            var foundWindowId: CGWindowID = 0
            if _AXUIElementGetWindow(axWindow, &foundWindowId) == .success,
               foundWindowId == cgWindowId {
                return axWindow
            }
        }

        return nil
    }

    func activateWindow(_ windowInfo: WindowInfo) {
        // Find the app by PID
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.processIdentifier == windowInfo.pid }) else {
            print("❌ App not found for PID: \(windowInfo.pid)")
            return
        }

        // Activate the application
        app.activate(options: [.activateIgnoringOtherApps])

        // Convert CGWindowID to AXUIElement
        guard let axWindow = getAXUIElement(for: windowInfo.cgWindowId, pid: windowInfo.pid) else {
            print("❌ Window not found: \(windowInfo.cgWindowId)")
            return
        }

        // Focus and raise the window
        AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, true as CFTypeRef)
        AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
        print("✅ Activated window: \(windowInfo.title)")
    }

    // MARK: - Window Validation

    func isWindowValid(_ cgWindowId: CGWindowID) -> Bool {
        // Query CG Window API to check if window exists across all spaces
        // Use .optionAll instead of .optionOnScreenOnly to include windows on other desktops
        guard let windowList = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[CFString: Any]] else {
            return false
        }

        return windowList.contains { windowDict in
            guard let windowId = windowDict[kCGWindowNumber] as? CGWindowID else {
                return false
            }
            return windowId == cgWindowId
        }
    }

    // MARK: - App Icons

    func getIcon(for bundleId: String) -> NSImage? {
        return iconCache.getIcon(for: bundleId)
    }
}
