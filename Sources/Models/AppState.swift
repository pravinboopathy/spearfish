//
//  AppState.swift
//  HarpoonMac
//
//  Global application state
//

import Foundation
import SwiftUI
import OSLog

class AppState: ObservableObject {
    private let logger = Logger(subsystem: "com.harpoon.mac", category: "AppState")
    @Published var isPickerVisible: Bool = false
    @Published var pinnedWindows: [HarpoonWindow] = []

    // Picker window reference
    var pickerWindow: NSWindow?

    func showPicker() {
        logger.debug("AppState.showPicker called")
        isPickerVisible = true
        logger.debug("isPickerVisible set to true")
    }

    func hidePicker() {
        logger.debug("AppState.hidePicker called")
        isPickerVisible = false
        pickerWindow?.orderOut(nil)
        logger.debug("isPickerVisible set to false")
    }

    func togglePicker() {
        logger.debug("AppState.togglePicker called - current state: \(self.isPickerVisible)")
        if isPickerVisible {
            hidePicker()
        } else {
            showPicker()
        }
    }

    func updatePinnedWindows(_ windows: [HarpoonWindow]) {
        pinnedWindows = windows
    }
}
