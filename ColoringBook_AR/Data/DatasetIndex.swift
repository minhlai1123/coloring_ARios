import Foundation

/// Root schema matching `index.json`
public struct DatasetIndex: Codable, Sendable {
    public let total: Int
    public let categories: [String: Int]
    public let images: [ColoringItem]
    public let categoriesCatalog: [CategoryCatalogItem]?

    enum CodingKeys: String, CodingKey {
        case total
        case categories
        case images
        case categoriesCatalog = "categories_catalog"
    }

    public init(
        total: Int,
        categories: [String: Int],
        images: [ColoringItem],
        categoriesCatalog: [CategoryCatalogItem]? = nil
    ) {
        self.total = total
        self.categories = categories
        self.images = images
        self.categoriesCatalog = categoriesCatalog
    }
}

public struct CategoryCatalogItem: Codable, Sendable {
    public let categoryId: String
    public let categoryName: String
    public let count: Int
    public let items: [ColoringItem]

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
        case count
        case items
    }
}
