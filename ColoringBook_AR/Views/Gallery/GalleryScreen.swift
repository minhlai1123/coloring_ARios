import SwiftUI

/// Gallery Screen presenting items in a category using a 2-column LazyVGrid of 256x256 thumbnails
public struct GalleryScreen: View {
    @StateObject private var viewModel: GalleryViewModel
    @State private var selectedItemForAction: ColoringItem?
    @State private var selectedColoringItem: ColoringItem?
    @State private var selectedARItem: ColoringItem?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    public init(category: ColoringCategory) {
        _viewModel = StateObject(wrappedValue: GalleryViewModel(category: category))
    }

    public var body: some View {
        ScrollView {
            if viewModel.filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: viewModel.showFavoritesOnly ? "heart.slash" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top, 60)

                    Text(viewModel.showFavoritesOnly ? "No favorites yet" : "No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(viewModel.showFavoritesOnly ? "Tap the heart icon on any drawing to add it to your favorites." : "Try searching with a different keyword.")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.filteredItems) { item in
                        GalleryThumbnailCard(
                            item: item,
                            thumbnail: viewModel.thumbnail(for: item),
                            isFavorite: viewModel.isFavorite(item: item),
                            onToggleFavorite: {
                                viewModel.toggleFavorite(item: item)
                            },
                            onTap: {
                                selectedItemForAction = item
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(viewModel.category.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchQuery, prompt: "Search in \(viewModel.category.title)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showFavoritesOnly.toggle()
                    }
                }) {
                    Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.showFavoritesOnly ? .red : .primary)
                }
            }
        }
        .confirmationDialog(
            "Select Drawing Mode",
            isPresented: Binding(
                get: { selectedItemForAction != nil },
                set: { if !$0 { selectedItemForAction = nil } }
            ),
            presenting: selectedItemForAction
        ) { item in
            Button {
                selectedColoringItem = item
            } label: {
                Label("Normal Coloring", systemImage: "paintbrush.fill")
            }

            Button {
                selectedARItem = item
            } label: {
                Label("AR Camera Tracing", systemImage: "camera.viewfinder")
            }

            Button("Cancel", role: .cancel) {
                selectedItemForAction = nil
            }
        } message: { item in
            Text("How would you like to create '\(item.name)'?")
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedColoringItem != nil },
            set: { if !$0 { selectedColoringItem = nil } }
        )) {
            if let item = selectedColoringItem {
                ColoringScreen(item: item)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedARItem != nil },
            set: { if !$0 { selectedARItem = nil } }
        )) {
            if let item = selectedARItem {
                ARDrawingScreen(item: item)
            }
        }
    }
}

/// Thumbnail Card View in Gallery Grid
private struct GalleryThumbnailCard: View {
    let item: ColoringItem
    let thumbnail: UIImage?
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail container
                ZStack(alignment: .topTrailing) {
                    Color.white

                    if let img = thumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    } else {
                        ProgressView()
                    }

                    // Favorite button
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isFavorite ? .red : .gray.opacity(0.6))
                            .padding(8)
                            .background(Color.white.opacity(0.85))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
                .frame(height: 156)
                .clipped()

                // Info footer
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack {
                        // Difficulty Tag
                        Text(item.difficulty)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(difficultyColor(item.difficulty))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor(item.difficulty).opacity(0.12))
                            .clipShape(Capsule())

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.uppercased() {
        case "HARD": return .red
        case "MEDIUM": return .orange
        default: return .green
        }
    }
}

#Preview {
    NavigationStack {
        GalleryScreen(
            category: ColoringCategory(
                id: "animals_creatures",
                title: "Animals & Creatures",
                icon: "hare.fill",
                count: 36,
                accentColorHex: "FF6B6B"
            )
        )
    }
}
