//
//  HarpoonWindow.swift
//  HarpoonMac
//
//  Model representing a pinned window in the harpoon list
//

import Foundation
import ApplicationServices

struct HarpoonWindow: Codable, Identifiable, Equatable {
    let cgWindowId: CGWindowID
    let pid: pid_t
    var position: Int  // 1-9
    let bundleId: String  // For icon/display purposes
    let appName: String
    var windowTitle: String
    var lastAccessed: Date?

    // Use cgWindowId as the Identifiable id
    var id: CGWindowID { cgWindowId }

    init(
        cgWindowId: CGWindowID,
        pid: pid_t,
        position: Int,
        bundleId: String,
        appName: String,
        windowTitle: String,
        lastAccessed: Date? = nil
    ) {
        self.cgWindowId = cgWindowId
        self.pid = pid
        self.position = position
        self.bundleId = bundleId
        self.appName = appName
        self.windowTitle = windowTitle
        self.lastAccessed = lastAccessed
    }

    // Create from current window metadata
    init(position: Int, windowInfo: WindowInfo) {
        self.init(
            cgWindowId: windowInfo.cgWindowId,
            pid: windowInfo.pid,
            position: position,
            bundleId: windowInfo.bundleId,
            appName: windowInfo.appName,
            windowTitle: windowInfo.title
        )
    }
}

// Helper struct for window information from CG Window API
struct WindowInfo {
    let cgWindowId: CGWindowID
    let pid: pid_t
    let bundleId: String
    let title: String
    let appName: String
}
