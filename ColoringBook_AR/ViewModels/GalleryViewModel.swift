import Foundation
import SwiftUI
import Combine

/// ViewModel managing items and presentation for GalleryScreen
@MainActor
public final class GalleryViewModel: ObservableObject {
    public let category: ColoringCategory

    @Published public private(set) var items: [ColoringItem] = []
    @Published public var searchQuery: String = ""
    @Published public private(set) var isLoading: Bool = false

    private let repository: ImageRepositoryProtocol

    public init(
        category: ColoringCategory,
        repository: ImageRepositoryProtocol = ImageRepository.shared
    ) {
        self.category = category
        self.repository = repository
        loadItems()
    }

    public func loadItems() {
        isLoading = true
        let fetched = repository.getItems(for: category.id)
        self.items = fetched
        self.isLoading = false
    }

    /// Filtered items based on optional search text
    public var filteredItems: [ColoringItem] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return items
        }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }

    /// Lazy loads thumbnail for a specific item
    public func thumbnail(for item: ColoringItem) -> UIImage? {
        return repository.loadThumbnail(for: item)
    }
}
