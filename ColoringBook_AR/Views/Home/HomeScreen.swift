import SwiftUI

/// Modern commercial Home Screen displaying categories derived dynamically from `index.json`
public struct HomeScreen: View {
    @StateObject private var viewModel = HomeViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Banner
                    headerSection

                    // Quick Mode Highlights
                    quickModeCards

                    // Categories Section
                    categoriesSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("ColoringBook AR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(.orange)
                        Text("ColoringBook AR")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .task {
                viewModel.loadCategories()
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Let's create\nsomething magical ✨")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)

            Text("Choose from \(viewModel.totalImages) hand-crafted templates for Normal Coloring & AR Camera Tracing")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }

    private var quickModeCards: some View {
        HStack(spacing: 12) {
            // Normal Coloring Badge
            HStack {
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Normal Coloring")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Tap to flood-fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

            // AR Tracing Badge
            HStack {
                Image(systemName: "camera.viewfinder")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.purple)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("AR Tracing")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Draw on paper")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Categories")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Text("\(viewModel.categories.count) categories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(40)
                    Spacer()
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Error loading categories")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.categories) { category in
                        NavigationLink(destination: GalleryScreen(category: category)) {
                            CategoryCardView(category: category)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

/// Category Card View with vibrant gradient styling
private struct CategoryCardView: View {
    let category: ColoringCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.systemIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Spacer()

                Text("\(category.count)")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .clipShape(Capsule())
            }

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("Explore pack →")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(16)
        .frame(height: 148)
        .background(
            LinearGradient(
                colors: category.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: category.accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}
