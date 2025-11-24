//
//  WindowCardView.swift
//  HarpoonMac
//
//  Individual window card in picker list
//

import SwiftUI

struct WindowCardView: View {
    let window: HarpoonWindow
    let icon: NSImage?

    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(window.position)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 40)

            // App icon
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)  // GPU-accelerated scaling
                    .frame(width: 48, height: 48)
                    .cornerRadius(8)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.gray)
            }

            // Window info
            VStack(alignment: .leading, spacing: 4) {
                Text(window.appName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(window.windowTitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .frame(height: 72)  // Fixed height for performance
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .compositingGroup()  // Layer flattening for GPU
    }
}

struct EmptySlotView: View {
    let position: Int
    let markKeybind: String

    var body: some View {
        HStack(spacing: 12) {
            // Position number
            Text("\(position)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 40)

            // Placeholder icon
            Image(systemName: "app.dashed")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.gray.opacity(0.3))

            // Placeholder text
            Text("Empty - Press \(markKeybind) to mark a window")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)

            Spacer()
        }
        .padding(12)
        .frame(height: 72)  // Fixed height for performance
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .compositingGroup()  // Layer flattening for GPU
    }
}

// Preview provider for development
#if DEBUG
struct WindowCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WindowCardView(
                window: HarpoonWindow(
                    cgWindowId: 123,
                    pid: 456,
                    position: 1,
                    bundleId: "com.microsoft.VSCode",
                    appName: "Visual Studio Code",
                    windowTitle: "Dashboard.tsx - Visual Studio Code"
                ),
                icon: NSImage(systemSymbolName: "app.fill", accessibilityDescription: "App")
            )

            EmptySlotView(position: 2, markKeybind: "⌥M")
        }
        .frame(width: 400)
        .padding()
        .background(Color.black)
    }
}
#endif
