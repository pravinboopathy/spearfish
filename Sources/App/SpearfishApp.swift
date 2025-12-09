//
//  SpearfishApp.swift
//  Spearfish
//
//  Main application entry point
//

import SwiftUI

@main
struct SpearfishApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
