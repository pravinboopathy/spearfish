//
//  Toast.swift
//  HarpoonMac
//
//  Model for toast notifications
//

import Foundation

struct Toast: Equatable {
    let message: String
    let icon: String
    let type: ToastType

    enum ToastType {
        case success
        case error
        case info
    }

    static func success(_ message: String, icon: String = "checkmark.circle.fill") -> Toast {
        Toast(message: message, icon: icon, type: .success)
    }

    static func error(_ message: String, icon: String = "exclamationmark.triangle.fill") -> Toast {
        Toast(message: message, icon: icon, type: .error)
    }

    static func info(_ message: String, icon: String = "info.circle.fill") -> Toast {
        Toast(message: message, icon: icon, type: .info)
    }
}
