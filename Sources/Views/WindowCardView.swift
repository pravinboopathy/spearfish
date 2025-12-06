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
        HStack(spacing: UIConstants.Card.spacing) {
            // Position number
            Text("\(window.position)")
                .font(.system(size: UIConstants.Card.positionFontSize, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: UIConstants.Card.positionWidth)

            // App icon
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)  // GPU-accelerated scaling
                    .frame(width: UIConstants.Icon.displaySize, height: UIConstants.Icon.displaySize)
                    .cornerRadius(UIConstants.Card.cornerRadius)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: UIConstants.Icon.displaySize, height: UIConstants.Icon.displaySize)
                    .foregroundColor(.gray)
            }

            // Window info
            VStack(alignment: .leading, spacing: 4) {
                Text(window.appName)
                    .font(.system(size: UIConstants.Card.titleFontSize, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(window.windowTitle)
                    .font(.system(size: UIConstants.Card.subtitleFontSize))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(UIConstants.Card.padding)
        .frame(height: UIConstants.Card.height)
        .background(Color.white.opacity(0.1))
        .cornerRadius(UIConstants.Card.cornerRadius)
        .compositingGroup()  // Layer flattening for GPU
    }
}

struct EmptySlotView: View {
    let position: Int
    let markKeybind: String

    var body: some View {
        HStack(spacing: UIConstants.Card.spacing) {
            // Position number
            Text("\(position)")
                .font(.system(size: UIConstants.Card.positionFontSize, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: UIConstants.Card.positionWidth)

            // Placeholder icon
            Image(systemName: "app.dashed")
                .resizable()
                .frame(width: UIConstants.Icon.displaySize, height: UIConstants.Icon.displaySize)
                .foregroundColor(.gray.opacity(0.3))

            // Placeholder text
            Text("Empty - Press \(markKeybind) to mark a window")
                .font(.system(size: UIConstants.Card.subtitleFontSize))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)

            Spacer()
        }
        .padding(UIConstants.Card.padding)
        .frame(height: UIConstants.Card.height)
        .background(Color.white.opacity(0.05))
        .cornerRadius(UIConstants.Card.cornerRadius)
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
