import Foundation
import SwiftUI
import Combine

/// ViewModel managing data and state for HomeScreen
@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var categories: [ColoringCategory] = []
    @Published public private(set) var totalImages: Int = 0
    @Published public private(set) var isLoading: Bool = false
    @Published public var errorMessage: String?

    private let repository: ImageRepositoryProtocol

    public init(repository: ImageRepositoryProtocol = ImageRepository.shared) {
        self.repository = repository
        loadCategories()
    }

    public func loadCategories() {
        isLoading = true
        errorMessage = nil

        do {
            let dataset = try repository.loadDataset()
            self.totalImages = dataset.total
            self.categories = repository.getCategories()
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
