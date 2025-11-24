//
//  AppState.swift
//  HarpoonMac
//
//  Global application state
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isPickerVisible: Bool = false
    @Published var pinnedWindows: [HarpoonWindow] = []

    // Picker window reference
    var pickerWindow: NSWindow?

    func showPicker() {
        print("✨ AppState.showPicker called")
        isPickerVisible = true
        print("✨ isPickerVisible set to true")
    }

    func hidePicker() {
        print("🔻 AppState.hidePicker called")
        isPickerVisible = false
        pickerWindow?.orderOut(nil)
        print("🔻 isPickerVisible set to false")
    }

    func togglePicker() {
        print("🔀 AppState.togglePicker called - current state: \(isPickerVisible)")
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
