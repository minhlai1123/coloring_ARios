import Foundation
import UIKit

/// Protocol defining operations for retrieving coloring artworks and metadata
public protocol ImageRepositoryProtocol: Sendable {
    func loadDataset() throws -> DatasetIndex
    func getCategories() -> [ColoringCategory]
    func getAllItems() -> [ColoringItem]
    func getItems(for category: String) -> [ColoringItem]
    func getItem(id: String) -> ColoringItem?
    func loadThumbnail(for item: ColoringItem) -> UIImage?
    func loadRawImage(for item: ColoringItem) -> UIImage?
    func loadAROverlay(for item: ColoringItem) -> UIImage?
}

/// Thread-safe Repository managing lazy loading and caching of coloring artworks
public final class ImageRepository: ImageRepositoryProtocol, @unchecked Sendable {
    public static let shared = ImageRepository()

    private let bundle: Bundle
    private let customDataURL: URL?
    private let lock = NSLock()

    private var cachedDataset: DatasetIndex?
    private var itemsById: [String: ColoringItem] = [:]
    private var itemsByCategory: [String: [ColoringItem]] = [:]

    // In-memory image cache with cost limits to protect RAM
    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let rawImageCache = NSCache<NSString, UIImage>()
    private let arOverlayCache = NSCache<NSString, UIImage>()

    public init(bundle: Bundle = .main, customDataURL: URL? = nil) {
        self.bundle = bundle
        self.customDataURL = customDataURL

        // Configure memory cache limits
        thumbnailCache.countLimit = 100
        thumbnailCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB

        rawImageCache.countLimit = 5 // Keep only recently used full-res images
        rawImageCache.totalCostLimit = 60 * 1024 * 1024 // 60 MB

        arOverlayCache.countLimit = 2 // Only 1-2 active AR overlays
        arOverlayCache.totalCostLimit = 30 * 1024 * 1024
    }

    // MARK: - Dataset Loading & Indexing

    @discardableResult
    public func loadDataset() throws -> DatasetIndex {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedDataset {
            return cached
        }

        let data: Data
        if let customURL = customDataURL {
            let indexURL = customURL.appendingPathComponent("index.json")
            data = try Data(contentsOf: indexURL)
        } else if let bundleURL = bundle.url(forResource: "index", withExtension: "json", subdirectory: "data") {
            data = try Data(contentsOf: bundleURL)
        } else if let fallbackURL = bundle.url(forResource: "index", withExtension: "json") {
            data = try Data(contentsOf: fallbackURL)
        } else {
            throw RepositoryError.indexFileNotFound
        }

        let decoder = JSONDecoder()
        let dataset = try decoder.decode(DatasetIndex.self, from: data)

        // Build index lookup tables
        var byId: [String: ColoringItem] = [:]
        var byCategory: [String: [ColoringItem]] = [:]

        for item in dataset.images {
            byId[item.id] = item
            byCategory[item.category, default: []].append(item)
        }

        self.cachedDataset = dataset
        self.itemsById = byId
        self.itemsByCategory = byCategory

        return dataset
    }

    public func getCategories() -> [ColoringCategory] {
        ensureLoaded()
        lock.lock()
        defer { lock.unlock() }

        guard let dataset = cachedDataset else { return [] }

        // Category priority order
        let order = [
            "magic_fantasy",
            "animals_creatures",
            "fantasy_landscapes",
            "holidays_festivals",
            "mandala_patterns",
            "unicorns_horses",
            "characters_princesses",
            "vehicles",
            "nature_plants"
        ]

        var categories: [ColoringCategory] = []
        for catId in order {
            if let count = dataset.categories[catId], count > 0 {
                categories.append(ColoringCategory.make(id: catId, count: count))
            }
        }

        // Add any additional categories not in predefined order
        for (catId, count) in dataset.categories where !order.contains(catId) && count > 0 {
            categories.append(ColoringCategory.make(id: catId, count: count))
        }

        return categories
    }

    public func getAllItems() -> [ColoringItem] {
        ensureLoaded()
        lock.lock()
        defer { lock.unlock() }
        return cachedDataset?.images ?? []
    }

    public func getItems(for category: String) -> [ColoringItem] {
        ensureLoaded()
        lock.lock()
        defer { lock.unlock() }

        if category.isEmpty || category.lowercased() == "all" {
            return cachedDataset?.images ?? []
        }
        return itemsByCategory[category] ?? []
    }

    public func getItem(id: String) -> ColoringItem? {
        ensureLoaded()
        lock.lock()
        defer { lock.unlock() }
        return itemsById[id]
    }

    // MARK: - Lazy Image Loading with Caching

    public func loadThumbnail(for item: ColoringItem) -> UIImage? {
        let cacheKey = NSString(string: item.id)
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        guard let image = loadImage(relPath: item.thumb) else { return nil }
        let cost = Int(image.size.width * image.size.height * 4)
        thumbnailCache.setObject(image, forKey: cacheKey, cost: cost)
        return image
    }

    public func loadRawImage(for item: ColoringItem) -> UIImage? {
        let cacheKey = NSString(string: item.id)
        if let cached = rawImageCache.object(forKey: cacheKey) {
            return cached
        }

        guard let image = loadImage(relPath: item.file) else { return nil }
        let cost = Int(image.size.width * image.size.height * 4)
        rawImageCache.setObject(image, forKey: cacheKey, cost: cost)
        return image
    }

    public func loadAROverlay(for item: ColoringItem) -> UIImage? {
        let cacheKey = NSString(string: item.id)
        if let cached = arOverlayCache.object(forKey: cacheKey) {
            return cached
        }

        guard let image = loadImage(relPath: item.arFile) else { return nil }
        let cost = Int(image.size.width * image.size.height * 4)
        arOverlayCache.setObject(image, forKey: cacheKey, cost: cost)
        return image
    }

    public func clearCache() {
        thumbnailCache.removeAllObjects()
        rawImageCache.removeAllObjects()
        arOverlayCache.removeAllObjects()
    }

    // MARK: - Private Helpers

    private func ensureLoaded() {
        if cachedDataset == nil {
            _ = try? loadDataset()
        }
    }

    private func loadImage(relPath: String) -> UIImage? {
        // 1. Check customDataURL
        if let customURL = customDataURL {
            let fileURL = customURL.appendingPathComponent(relPath)
            if let data = try? Data(contentsOf: fileURL) {
                return UIImage(data: data)
            }
        }

        // 2. Check Bundle inside "data/"
        let subPath = (relPath as NSString).deletingLastPathComponent
        let fname = (relPath as NSString).lastPathComponent
        let ext = (fname as NSString).pathExtension
        let nameNoExt = (fname as NSString).deletingPathExtension

        let searchDirectory = subPath.isEmpty ? "data" : "data/\(subPath)"
        if let url = bundle.url(forResource: nameNoExt, withExtension: ext, subdirectory: searchDirectory) {
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }

        // 3. Fallback direct bundle search
        if let url = bundle.url(forResource: nameNoExt, withExtension: ext) {
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }

        return nil
    }
}

public enum RepositoryError: Error, LocalizedError {
    case indexFileNotFound
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .indexFileNotFound:
            return "index.json could not be found in bundle resources."
        case .decodingFailed(let err):
            return "Failed to decode index.json: \(err.localizedDescription)"
        }
    }
}
