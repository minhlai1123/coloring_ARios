import Foundation
import SwiftUI
import Photos
import Combine

/// ViewModel managing state, color palette, undo/redo history, and flood-fill operations
@MainActor
public final class ColoringViewModel: ObservableObject {
    public let item: ColoringItem

    // Drawing Tools
    public enum DrawingTool: String, CaseIterable, Identifiable {
        case brush = "Brush"
        case fill = "Fill"
        case eraser = "Eraser"

        public var id: String { rawValue }
    }

    @Published public private(set) var currentImage: UIImage?
    @Published public var selectedColor: Color = ColorPalette.defaultColor
    @Published public var currentTool: DrawingTool = .brush
    @Published public var brushSize: CGFloat = 28.0
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

    public func selectTool(_ tool: DrawingTool) {
        self.currentTool = tool
    }

    public func setBrushSize(_ size: CGFloat) {
        self.brushSize = size
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
                    HapticFeedback.light()
                    self.pushState(previous: img)
                    self.currentImage = updated
                    self.redoStack.removeAll()
                    self.updateUndoRedoState()
                }
            }
        }
    }

    // MARK: - Freehand Brush Drawing & Erasing

    public func applyBrushStroke(
        points: [CGPoint],
        strokeWidth: CGFloat,
        color: UIColor,
        isEraser: Bool = false
    ) {
        guard let current = currentImage, let original = baseOriginalImage, !points.isEmpty else { return }

        // Save state for undo
        pushState(previous: current)

        let size = current.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let updatedImage = renderer.image { ctx in
            let cgContext = ctx.cgContext

            // 1. Draw existing canvas
            current.draw(at: .zero)

            // 2. Draw stroke path
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            cgContext.setLineWidth(strokeWidth)

            let strokeColor = isEraser ? UIColor.white : color
            cgContext.setStrokeColor(strokeColor.cgColor)
            cgContext.setFillColor(strokeColor.cgColor)

            if points.count == 1 {
                let p = points[0]
                let rect = CGRect(
                    x: p.x - strokeWidth / 2.0,
                    y: p.y - strokeWidth / 2.0,
                    width: strokeWidth,
                    height: strokeWidth
                )
                cgContext.fillEllipse(in: rect)
            } else {
                let path = CGMutablePath()
                path.move(to: points[0])
                for i in 1..<points.count {
                    let p0 = points[i - 1]
                    let p1 = points[i]
                    let mid = CGPoint(x: (p0.x + p1.x) / 2.0, y: (p0.y + p1.y) / 2.0)
                    path.addQuadCurve(to: mid, control: p0)
                }
                path.addLine(to: points.last!)
                cgContext.addPath(path)
                cgContext.strokePath()
            }

            // 3. Multiply blend original line-art back on top to guarantee black lines are never covered
            original.draw(in: CGRect(origin: .zero, size: size), blendMode: .multiply, alpha: 1.0)
        }

        self.currentImage = updatedImage
        self.redoStack.removeAll()
        self.updateUndoRedoState()
        HapticFeedback.light()
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
