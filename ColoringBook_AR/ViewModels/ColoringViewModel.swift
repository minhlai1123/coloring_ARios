import Foundation
import SwiftUI
import Photos
import Combine

/// ViewModel managing state, color palette, undo/redo history, and flood-fill operations
@MainActor
public final class ColoringViewModel: ObservableObject {
    public let item: ColoringItem

    @Published public private(set) var currentImage: UIImage?
    @Published public var selectedColor: Color = ColorPalette.defaultColor
    @Published public private(set) var canUndo: Bool = false
    @Published public private(set) var canRedo: Bool = false
    @Published public private(set) var isProcessing: Bool = false
    @Published public var toastMessage: String?
    @Published public var showToast: Bool = false

    private let repository: ImageRepositoryProtocol
    private var baseOriginalImage: UIImage?

    // Bounded Undo / Redo history stacks (max 8 states to conserve memory)
    private let maxHistoryDepth = 8
    private var undoStack: [UIImage] = []
    private var redoStack: [UIImage] = []

    public init(
        item: ColoringItem,
        repository: ImageRepositoryProtocol = ImageRepository.shared
    ) {
        self.item = item
        self.repository = repository
        loadRawImage()
    }

    public func loadRawImage() {
        guard let raw = repository.loadRawImage(for: item) else {
            presentToast("Failed to load line-art image.")
            return
        }
        self.baseOriginalImage = raw
        self.currentImage = raw
        self.undoStack.removeAll()
        self.redoStack.removeAll()
        updateUndoRedoState()
    }

    // MARK: - Interactive Flood Fill

    public func handleTap(at point: CGPoint) {
        guard !isProcessing, let img = currentImage else { return }

        isProcessing = true
        let uiColor = UIColor(selectedColor)

        Task.detached(priority: .userInitiated) { [weak self, img, point, uiColor] in
            guard let self = self else { return }
            let filledImage = ScanlineFloodFill.fill(image: img, atPoint: point, withColor: uiColor)

            await MainActor.run {
                self.isProcessing = false
                if let updated = filledImage {
                    self.pushState(previous: img)
                    self.currentImage = updated
                    self.redoStack.removeAll()
                    self.updateUndoRedoState()
                }
            }
        }
    }

    // MARK: - Undo, Redo, Reset

    public func undo() {
        guard !undoStack.isEmpty, let current = currentImage else { return }
        let previous = undoStack.removeLast()
        redoStack.append(current)
        self.currentImage = previous
        updateUndoRedoState()
    }

    public func redo() {
        guard !redoStack.isEmpty, let current = currentImage else { return }
        let next = redoStack.removeLast()
        undoStack.append(current)
        self.currentImage = next
        updateUndoRedoState()
    }

    public func reset() {
        guard let base = baseOriginalImage else { return }
        if let current = currentImage, current !== base {
            pushState(previous: current)
        }
        self.currentImage = base
        self.redoStack.removeAll()
        updateUndoRedoState()
        presentToast("Canvas reset.")
    }

    private func pushState(previous: UIImage) {
        undoStack.append(previous)
        if undoStack.count > maxHistoryDepth {
            undoStack.removeFirst()
        }
    }

    private func updateUndoRedoState() {
        self.canUndo = !undoStack.isEmpty
        self.canRedo = !redoStack.isEmpty
    }

    // MARK: - Save to Photos

    public func saveToPhotos() {
        guard let image = currentImage else {
            presentToast("No artwork to save.")
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    self.presentToast("Saved artwork to Photos! ✨")
                case .denied, .restricted:
                    self.presentToast("Please allow Photo Library permission in Settings to save.")
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func presentToast(_ message: String) {
        self.toastMessage = message
        self.showToast = true
    }
}
