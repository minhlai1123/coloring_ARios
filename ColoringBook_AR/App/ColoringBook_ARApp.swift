import SwiftUI

@main
struct ColoringBook_ARApp: App {
    init() {
        // Preload index on background thread at startup
        DispatchQueue.global(qos: .userInitiated).async {
            _ = try? ImageRepository.shared.loadDataset()
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeScreen()
                .preferredColorScheme(.light)
        }
    }
}
