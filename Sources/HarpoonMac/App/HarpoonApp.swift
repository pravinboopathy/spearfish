//
//  HarpoonApp.swift
//  HarpoonMac
//
//  Main application entry point
//

import SwiftUI

@main
struct HarpoonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
