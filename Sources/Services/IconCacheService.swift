//
//  IconCacheService.swift
//  Spearfish
//
//  GPU-optimized icon caching service
//

import Cocoa

class IconCacheService {
    private var cache: [String: NSImage] = [:]
    private let queue = DispatchQueue(label: "com.spearfish.iconcache", attributes: .concurrent)
    private let placeholderIcon: NSImage

    init() {
        // Create placeholder icon
        let iconSize = NSSize(width: UIConstants.Icon.cacheSize, height: UIConstants.Icon.cacheSize)
        placeholderIcon = NSImage(systemSymbolName: "app.fill", accessibilityDescription: "App") ??
            NSImage(size: iconSize)
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

    func pruneCache(keeping bundleIds: Set<String>) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache = self?.cache.filter { bundleIds.contains($0.key) } ?? [:]
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
        let iconSize = NSSize(width: UIConstants.Icon.cacheSize, height: UIConstants.Icon.cacheSize)
        let resizedIcon = resizeIcon(icon, to: iconSize)

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
