import Foundation

/// Represents a single coloring artwork item in the dataset.
/// Conforms to exact schema present in `index.json`.
public struct ColoringItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let categoryName: String?
    public let file: String
    public let arFile: String
    public let thumb: String
    public let difficulty: String
    public let width: Int?
    public let height: Int?
    public let sourceUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case categoryName = "category_name"
        case file
        case arFile = "ar_file"
        case thumb
        case difficulty
        case width
        case height
        case sourceUrl = "source_url"
    }

    public init(
        id: String,
        name: String,
        category: String,
        categoryName: String? = nil,
        file: String,
        arFile: String,
        thumb: String,
        difficulty: String = "EASY",
        width: Int? = nil,
        height: Int? = nil,
        sourceUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.categoryName = categoryName
        self.file = file
        self.arFile = arFile
        self.thumb = thumb
        self.difficulty = difficulty
        self.width = width
        self.height = height
        self.sourceUrl = sourceUrl
    }

    /// Filename without leading directory
    public var fileName: String {
        return (file as NSString).lastPathComponent
    }

    /// Relative bundle resource path for raw coloring artwork
    public var rawResourcePath: String {
        return "data/\(file)"
    }

    /// Relative bundle resource path for transparent AR tracing artwork
    public var arResourcePath: String {
        return "data/\(arFile)"
    }

    /// Relative bundle resource path for UI thumbnail
    public var thumbResourcePath: String {
        return "data/\(thumb)"
    }
}
