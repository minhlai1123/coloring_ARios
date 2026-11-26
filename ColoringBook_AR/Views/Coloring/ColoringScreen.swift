import SwiftUI
import UIKit

/// Normal Coloring Studio Screen with interactive flood-fill canvas, zoom/pan, and palette toolbar
public struct ColoringScreen: View {
    @StateObject private var viewModel: ColoringViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingResetAlert: Bool = false
    @State private var showingShareSheet: Bool = false

    public init(item: ColoringItem) {
        _viewModel = StateObject(wrappedValue: ColoringViewModel(item: item))
    }

    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Interactive Zoomable Canvas
                ZStack {
                    ZoomableScrollView(
                        image: viewModel.currentImage,
                        currentTool: viewModel.currentTool,
                        brushSize: viewModel.brushSize,
                        selectedColor: viewModel.selectedColor,
                        onTap: { point in
                            viewModel.handleTap(at: point)
                        },
                        onStrokeFinished: { points, width, color, isEraser in
                            viewModel.applyBrushStroke(points: points, strokeWidth: width, color: color, isEraser: isEraser)
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Processing Spinner Overlay
                    if viewModel.isProcessing {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            Text("Filling...")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                }

                // Palette & Action Toolbar
                PaletteBarView(
                    selectedColor: $viewModel.selectedColor,
                    currentTool: $viewModel.currentTool,
                    brushSize: $viewModel.brushSize,
                    canUndo: viewModel.canUndo,
                    canRedo: viewModel.canRedo,
                    onToolSelected: { viewModel.selectTool($0) },
                    onBrushSizeSelected: { viewModel.setBrushSize($0) },
                    onUndo: { viewModel.undo() },
                    onRedo: { viewModel.redo() },
                    onReset: { showingResetAlert = true },
                    onSave: { viewModel.saveToPhotos() },
                    onShare: {
                        if viewModel.currentImage != nil {
                            showingShareSheet = true
                        }
                    }
                )
            }

            // Toast Alert Banner
            if viewModel.showToast, let message = viewModel.toastMessage {
                VStack {
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .shadow(radius: 8)
                        .padding(.top, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.showToast)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        viewModel.showToast = false
                    }
                }
            }
        }
        .navigationTitle(viewModel.item.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: ARDrawingScreen(item: viewModel.item)) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                        Text("AR Tracing")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .alert("Reset Artwork?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                viewModel.reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All colors applied to this drawing will be cleared.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = viewModel.currentImage {
                ActivityViewController(activityItems: [image])
            }
        }
    }
}

/// UIActivityViewController bridge to present native iOS Share Sheet
private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ColoringScreen(
            item: ColoringItem(
                id: "animals_creatures_001",
                name: "Animals Creatures 001",
                category: "animals_creatures",
                file: "raw/animals_creatures_001.png",
                arFile: "ar_ready/animals_creatures_001.png",
                thumb: "thumbnails/animals_creatures_001.png",
                difficulty: "Easy"
            )
        )
    }
}
