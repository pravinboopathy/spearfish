//
//  WindowCardView.swift
//  Spearfish
//
//  Individual window card in picker list
//

import SwiftUI

struct WindowCardView: View {
    let window: SpearfishWindow
    let icon: NSImage?

    var body: some View {
        HStack(spacing: UIConstants.Card.spacing) {
            // Position number
            Text("\(window.position)")
                .font(.system(size: UIConstants.Card.positionFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: UIConstants.Card.positionWidth)

            // App icon
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)  // GPU-accelerated scaling
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }

            // Window info
            VStack(alignment: .leading, spacing: 2) {
                Text(window.appName)
                    .font(.system(size: UIConstants.Card.titleFontSize, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(window.windowTitle)
                    .font(.system(size: UIConstants.Card.subtitleFontSize))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(UIConstants.Card.padding)
        .frame(height: UIConstants.Card.height)
        .background(Color.white.opacity(0.08))
        .cornerRadius(UIConstants.Card.cornerRadius)
        .compositingGroup()  // Layer flattening for GPU
    }
}

struct EmptySlotView: View {
    let position: Int
    let markKeybind: String

    var body: some View {
        HStack(spacing: UIConstants.Card.spacing) {
            // Position number (dimmed)
            Text("\(position)")
                .font(.system(size: UIConstants.Card.positionFontSize, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.2))
                .frame(width: UIConstants.Card.positionWidth)

            // Placeholder text
            Text("Empty")
                .font(.system(size: UIConstants.Card.subtitleFontSize))
                .foregroundColor(.white.opacity(0.25))

            Spacer()

            // Keybind hint (subtle)
            Text("\(markKeybind) to mark")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(UIConstants.Card.padding)
        .frame(height: UIConstants.Card.emptyHeight)
        .background(Color.white.opacity(0.02))
        .cornerRadius(UIConstants.Card.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.Card.cornerRadius)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
        .compositingGroup()  // Layer flattening for GPU
    }
}

// Preview provider for development
#if DEBUG
struct WindowCardView_Previews: PreviewProvider {
    static var previews: some View {
        let config = KeybindConfiguration.default

        VStack(spacing: 6) {
            WindowCardView(
                window: SpearfishWindow(
                    cgWindowId: 123,
                    pid: 456,
                    position: 1,
                    bundleId: "com.microsoft.VSCode",
                    appName: "Visual Studio Code",
                    windowTitle: "Dashboard.tsx - Visual Studio Code"
                ),
                icon: NSImage(systemSymbolName: "app.fill", accessibilityDescription: "App")
            )

            EmptySlotView(position: 2, markKeybind: config.markWindowDisplayString())
            EmptySlotView(position: 3, markKeybind: config.markWindowDisplayString())
        }
        .frame(width: 400)
        .padding()
        .background(Color.black)
    }
}
#endif
