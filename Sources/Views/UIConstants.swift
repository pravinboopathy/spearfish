//
//  UIConstants.swift
//  HarpoonMac
//
//  Centralized UI dimension constants
//

import Foundation

enum UIConstants {
    enum Icon {
        static let cacheSize: CGFloat = 64
        static let displaySize: CGFloat = 48
    }

    enum Picker {
        static let width: CGFloat = 400
        static let height: CGFloat = 650
    }

    enum Card {
        static let height: CGFloat = 72
        static let spacing: CGFloat = 12
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 8
        static let positionFontSize: CGFloat = 24
        static let positionWidth: CGFloat = 40
        static let titleFontSize: CGFloat = 14
        static let subtitleFontSize: CGFloat = 12
    }

    enum Toast {
        static let width: CGFloat = 300
        static let height: CGFloat = 50
        static let bottomOffset: CGFloat = 100
        static let cornerRadius: CGFloat = 10
    }
}
