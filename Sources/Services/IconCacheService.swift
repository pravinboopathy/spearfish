//
//  IconCacheService.swift
//  HarpoonMac
//
//  GPU-optimized icon caching service
//

import Cocoa

class IconCacheService {
    private var cache: [String: NSImage] = [:]
    private let queue = DispatchQueue(label: "com.harpoon.iconcache", attributes: .concurrent)
    private let placeholderIcon: NSImage

    init() {
        // Create placeholder icon
        placeholderIcon = NSImage(systemSymbolName: "app.fill", accessibilityDescription: "App") ??
            NSImage(size: NSSize(width: 64, height: 64))
    }

    // MARK: - Public API

    func getIcon(for bundleId: String) -> NSImage? {
        // Try cache first
        if let cached = getCached(bundleId) {
            return cached
        }

        // Load icon (this will cache it)
        loadIcon(for: bundleId)

        // Return placeholder while loading
        return placeholderIcon
    }

    func preloadIcons(for bundleIds: [String]) {
        queue.async { [weak self] in
            for bundleId in bundleIds {
                self?.loadIcon(for: bundleId)
            }
        }
    }

    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
        }
    }

    // MARK: - Private Methods

    private func getCached(_ bundleId: String) -> NSImage? {
        queue.sync {
            cache[bundleId]
        }
    }

    private func setCached(_ bundleId: String, icon: NSImage) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache[bundleId] = icon
        }
    }

    private func loadIcon(for bundleId: String) {
        // Check if already cached
        if getCached(bundleId) != nil {
            return
        }

        // Load icon from workspace
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            setCached(bundleId, icon: placeholderIcon)
            return
        }

        let icon = NSWorkspace.shared.icon(forFile: appURL.path)

        // Resize to standard size for GPU efficiency
        let resizedIcon = resizeIcon(icon, to: NSSize(width: 64, height: 64))

        setCached(bundleId, icon: resizedIcon)
    }

    private func resizeIcon(_ icon: NSImage, to size: NSSize) -> NSImage {
        return NSImage(size: size, flipped: false) { rect in
            icon.draw(in: rect,
                      from: NSRect(origin: .zero, size: icon.size),
                      operation: .copy,
                      fraction: 1.0)
            return true
        }
    }
}
