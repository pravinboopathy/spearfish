//
//  HarpoonWindow.swift
//  HarpoonMac
//
//  Model representing a pinned window in the harpoon list
//

import Foundation
import ApplicationServices

struct HarpoonWindow: Codable, Identifiable, Equatable {
    let id: UUID
    var position: Int  // 1-9
    let bundleId: String
    var windowTitle: String
    let appName: String
    var lastAccessed: Date?

    init(
        id: UUID = UUID(),
        position: Int,
        bundleId: String,
        windowTitle: String,
        appName: String,
        lastAccessed: Date? = nil
    ) {
        self.id = id
        self.position = position
        self.bundleId = bundleId
        self.windowTitle = windowTitle
        self.appName = appName
        self.lastAccessed = lastAccessed
    }

    // Create from current window metadata
    init(position: Int, windowInfo: WindowInfo) {
        self.init(
            position: position,
            bundleId: windowInfo.bundleId,
            windowTitle: windowInfo.title,
            appName: windowInfo.appName
        )
    }
}

// Helper struct for window information from Accessibility API
struct WindowInfo {
    let bundleId: String
    let title: String
    let appName: String
    let windowRef: AXUIElement  // Not stored, used for activation
}
