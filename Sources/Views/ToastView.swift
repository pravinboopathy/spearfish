//
//  ToastView.swift
//  Spearfish
//
//  Toast notification view for user feedback
//

import SwiftUI

struct ToastView: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

#if DEBUG
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToastView(message: "Window marked to position 3", systemImage: "checkmark.circle.fill")
            ToastView(message: "Window removed", systemImage: "trash.fill")
            ToastView(message: "Desktop snapshot saved", systemImage: "camera.fill")
        }
        .padding()
        .background(Color.black)
    }
}
#endif
