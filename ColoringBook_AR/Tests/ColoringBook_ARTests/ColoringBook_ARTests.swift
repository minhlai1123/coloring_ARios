import XCTest
@testable import ColoringBook_AR

final class ColoringBook_ARTests: XCTestCase {

    var repository: ImageRepository!
    var dataURL: URL!

    override func setUpWithError() throws {
        // Locate embedded data directory
        let bundle = Bundle(for: type(of: self))
        if let resourceURL = bundle.url(forResource: "index", withExtension: "json", subdirectory: "data") {
            dataURL = resourceURL.deletingLastPathComponent()
            repository = ImageRepository(bundle: bundle, customDataURL: dataURL)
        } else {
            // Fallback development path in workspace
            dataURL = URL(fileURLWithPath: "E:/colorringbook_AR/coloringbook2_ar_ios/ColoringBook_AR/Resources/data")
            repository = ImageRepository(bundle: bundle, customDataURL: dataURL)
        }
    }

    override func tearDownWithError() throws {
        repository = nil
        dataURL = nil
    }

    // 1. Test JSON parsing
    func testJSONParsingSucceeds() throws {
        let dataset = try repository.loadDataset()
        XCTAssertGreaterThan(dataset.total, 0, "Total must be greater than 0")
        XCTAssertEqual(dataset.total, 235, "Total items should equal 235")
        XCTAssertFalse(dataset.categories.isEmpty, "Categories dictionary must not be empty")
        XCTAssertEqual(dataset.images.count, 235, "Images count should equal 235")
    }

    // 2. Test Invalid JSON Error Handling
    func testInvalidJSONThrowsError() {
        let invalidData = "{\"total\": \"invalid_type\"}".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(DatasetIndex.self, from: invalidData))
    }

    // 3. Test Repository Category Retrieval
    func testGetCategories() throws {
        try repository.loadDataset()
        let categories = repository.getCategories()
        XCTAssertEqual(categories.count, 9, "Expected exactly 9 categories")

        let magicCat = categories.first(where: { $0.id == "magic_fantasy" })
        XCTAssertNotNil(magicCat)
        XCTAssertEqual(magicCat?.count, 100)
    }

    // 4. Test Category Filtering
    func testCategoryFiltering() throws {
        try repository.loadDataset()

        let magicItems = repository.getItems(for: "magic_fantasy")
        XCTAssertEqual(magicItems.count, 100)

        let animalItems = repository.getItems(for: "animals_creatures")
        XCTAssertEqual(animalItems.count, 34)

        let nonExistent = repository.getItems(for: "non_existent_category")
        XCTAssertTrue(nonExistent.isEmpty)
    }

    // 5. Test Image Lookup by ID
    func testImageLookupById() throws {
        try repository.loadDataset()

        let item = repository.getItem(id: "magic_fantasy_001")
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.id, "magic_fantasy_001")
        XCTAssertEqual(item?.category, "magic_fantasy")
    }

    // 6. Test Missing Image Lookup
    func testMissingImageLookupReturnsNil() throws {
        try repository.loadDataset()
        let item = repository.getItem(id: "invalid_id_99999")
        XCTAssertNil(item)
    }

    // 7. Test Unique IDs in Dataset
    func testDatasetUniqueIDs() throws {
        let dataset = try repository.loadDataset()
        let allIDs = dataset.images.map { $0.id }
        let uniqueIDs = Set(allIDs)
        XCTAssertEqual(allIDs.count, uniqueIDs.count, "Duplicate IDs found in dataset!")
    }

    // 8. Test Expected Dataset Categories and Count
    func testExpectedCategoryCounts() throws {
        let dataset = try repository.loadDataset()
        let expected: [String: Int] = [
            "magic_fantasy": 100,
            "animals_creatures": 34,
            "fantasy_landscapes": 24,
            "holidays_festivals": 22,
            "mandala_patterns": 19,
            "unicorns_horses": 13,
            "characters_princesses": 11,
            "vehicles": 8,
            "nature_plants": 4
        ]
        for (cat, expectedCount) in expected {
            XCTAssertEqual(dataset.categories[cat], expectedCount, "Count mismatch for category \(cat)")
        }
    }

    // 9. Test Thumbnail, Raw, and AR Files Existence on Disk
    func testFilesExistenceOnDisk() throws {
        let dataset = try repository.loadDataset()
        let fileManager = FileManager.default

        for item in dataset.images {
            let thumbPath = dataURL.appendingPathComponent(item.thumb).path
            let rawPath = dataURL.appendingPathComponent(item.file).path
            let arPath = dataURL.appendingPathComponent(item.arFile).path

            XCTAssertTrue(fileManager.fileExists(atPath: thumbPath), "Missing thumbnail: \(thumbPath)")
            XCTAssertTrue(fileManager.fileExists(atPath: rawPath), "Missing raw image: \(rawPath)")
            XCTAssertTrue(fileManager.fileExists(atPath: arPath), "Missing AR overlay: \(arPath)")
        }
    }

    // 10. Test Flood Fill Engine Boundary and Line-art Protection
    func testFloodFillLineArtProtection() {
        // Create a 20x20 test canvas with a black horizontal line at y = 10
        let width = 20
        let height = 20
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        guard let ctx = UIGraphicsGetCurrentContext() else {
            XCTFail("Failed to create graphics context")
            return
        }

        // Fill background with white
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw a black line across the center
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(x: 0, y: 10, width: width, height: 2))

        guard let testImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            XCTFail("Failed to render test image")
            return
        }
        UIGraphicsEndImageContext()

        // 1. Tapping on the black line itself must return nil (protected)
        let tapOnLine = ScanlineFloodFill.fill(image: testImage, atPoint: CGPoint(x: 5, y: 10), withColor: .red)
        XCTAssertNil(tapOnLine, "Flood fill must not color over black line-art!")

        // 2. Tapping above the line (y = 5) should fill the top half and NOT cross the black line
        let filledTop = ScanlineFloodFill.fill(image: testImage, atPoint: CGPoint(x: 5, y: 5), withColor: .red)
        XCTAssertNotNil(filledTop, "Flood fill should succeed on white region")
    }

    // 11. Test Gallery Search & Favorites Filter Logic
    @MainActor
    func testGallerySearchAndFavoritesFilter() throws {
        try repository.loadDataset()
        let cat = ColoringCategory.make(id: "animals_creatures", count: 34)
        let vm = GalleryViewModel(category: cat, repository: repository)

        XCTAssertEqual(vm.filteredItems.count, 34)

        // Test search
        vm.searchQuery = "001"
        XCTAssertEqual(vm.filteredItems.count, 1)
        XCTAssertEqual(vm.filteredItems.first?.id, "animals_creatures_001")

        vm.searchQuery = ""
        XCTAssertEqual(vm.filteredItems.count, 34)

        // Test favorite toggle
        if let first = vm.items.first {
            XCTAssertFalse(vm.isFavorite(item: first))
            vm.toggleFavorite(item: first)
            XCTAssertTrue(vm.isFavorite(item: first))

            vm.showFavoritesOnly = true
            XCTAssertEqual(vm.filteredItems.count, 1)

            vm.toggleFavorite(item: first)
            XCTAssertFalse(vm.isFavorite(item: first))
            XCTAssertEqual(vm.filteredItems.count, 0)
        }
    }

    // 12. Test AR Drawing ViewModel Mirror / Flip Horizontal
    @MainActor
    func testARDrawingViewModelFlipHorizontal() {
        let item = ColoringItem(
            id: "test_001",
            name: "Test 001",
            category: "animals_creatures",
            file: "raw/test.png",
            arFile: "ar_ready/test.png",
            thumb: "thumbnails/test.png",
            difficulty: "Easy"
        )
        let vm = ARDrawingViewModel(item: item, repository: repository)

        XCTAssertFalse(vm.isFlippedHorizontal)
        vm.toggleFlipHorizontal()
        XCTAssertTrue(vm.isFlippedHorizontal)

        vm.resetTransform()
        XCTAssertFalse(vm.isFlippedHorizontal)
    }
}

