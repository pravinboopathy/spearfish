//
//  SettingsWindow.swift
//  HarpoonMac
//
//  Settings configuration panel
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)

            Text("Coming soon...")
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(width: 500, height: 400)
        .padding()
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
