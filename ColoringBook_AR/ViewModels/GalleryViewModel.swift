import Foundation
import SwiftUI
import Combine

/// ViewModel managing items, search filtering, and favorites presentation for GalleryScreen
@MainActor
public final class GalleryViewModel: ObservableObject {
    public let category: ColoringCategory

    @Published public private(set) var items: [ColoringItem] = []
    @Published public var searchQuery: String = ""
    @Published public var showFavoritesOnly: Bool = false
    @Published public private(set) var favoriteIds: Set<String> = []
    @Published public private(set) var isLoading: Bool = false

    private let favoritesKey = "user_favorites_coloring"
    private let repository: ImageRepositoryProtocol

    public init(
        category: ColoringCategory,
        repository: ImageRepositoryProtocol = ImageRepository.shared
    ) {
        self.category = category
        self.repository = repository
        loadFavorites()
        loadItems()
    }

    public func loadItems() {
        isLoading = true
        let fetched = repository.getItems(for: category.id)
        self.items = fetched
        self.isLoading = false
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            self.favoriteIds = Set(saved)
        }
    }

    public func isFavorite(item: ColoringItem) -> Bool {
        favoriteIds.contains(item.id)
    }

    public func toggleFavorite(item: ColoringItem) {
        HapticFeedback.light()
        if favoriteIds.contains(item.id) {
            favoriteIds.remove(item.id)
        } else {
            favoriteIds.insert(item.id)
        }
        UserDefaults.standard.set(Array(favoriteIds), forKey: favoritesKey)
    }

    /// Filtered items based on optional search text and favorites filter
    public var filteredItems: [ColoringItem] {
        var result = items
        if showFavoritesOnly {
            result = result.filter { favoriteIds.contains($0.id) }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return result
    }

    /// Lazy loads thumbnail for a specific item
    public func thumbnail(for item: ColoringItem) -> UIImage? {
        return repository.loadThumbnail(for: item)
    }
}
