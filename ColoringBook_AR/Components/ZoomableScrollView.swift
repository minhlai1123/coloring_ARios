import SwiftUI
import UIKit

/// High-performance Zoomable Container using UIScrollView for smooth 1x to 5x zooming and panning.
/// Supports both interactive Flood Fill (single tap) and Freehand Brush / Eraser drawing with live bezier preview.
public struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage?
    let currentTool: ColoringViewModel.DrawingTool
    let brushSize: CGFloat
    let selectedColor: Color
    let onTap: (CGPoint) -> Void
    let onStrokeFinished: ([CGPoint], CGFloat, UIColor, Bool) -> Void

    public init(
        image: UIImage?,
        currentTool: ColoringViewModel.DrawingTool = .fill,
        brushSize: CGFloat = 28.0,
        selectedColor: Color = .red,
        onTap: @escaping (CGPoint) -> Void,
        onStrokeFinished: @escaping ([CGPoint], CGFloat, UIColor, Bool) -> Void = { _, _, _, _ in }
    ) {
        self.image = image
        self.currentTool = currentTool
        self.brushSize = brushSize
        self.selectedColor = selectedColor
        self.onTap = onTap
        self.onStrokeFinished = onStrokeFinished
    }

    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .systemGroupedBackground

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)

        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView

        // Live stroke layer for smooth 60fps drawing preview
        let strokeLayer = CAShapeLayer()
        strokeLayer.lineCap = .round
        strokeLayer.lineJoin = .round
        strokeLayer.fillColor = nil
        imageView.layer.addSublayer(strokeLayer)
        context.coordinator.strokeLayer = strokeLayer

        // Single Tap gesture for flood fill or single-dot brush stamp
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        imageView.addGestureRecognizer(tapGesture)
        context.coordinator.tapGesture = tapGesture

        // Double Tap gesture for quick zoom reset
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)
        tapGesture.require(toFail: doubleTapGesture)

        // Freehand drawing Pan gesture (1 finger)
        let drawPanGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrawPan(_:)))
        drawPanGesture.minimumNumberOfTouches = 1
        drawPanGesture.maximumNumberOfTouches = 1
        imageView.addGestureRecognizer(drawPanGesture)
        context.coordinator.drawPanGesture = drawPanGesture

        return scrollView
    }

    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onStrokeFinished = onStrokeFinished
        context.coordinator.currentTool = currentTool
        context.coordinator.brushSize = brushSize
        context.coordinator.selectedColor = selectedColor

        guard let imageView = context.coordinator.imageView else { return }

        // Configure scroll & pan gesture sensitivity based on selected tool
        if currentTool == .fill {
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 1
            context.coordinator.drawPanGesture?.isEnabled = false
        } else {
            // For Brush and Eraser: 2 fingers zoom & pan, 1 finger draws smoothly
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
            context.coordinator.drawPanGesture?.isEnabled = true
        }

        if imageView.image !== image {
            imageView.image = image
            if let img = image {
                imageView.frame = CGRect(origin: .zero, size: img.size)
                context.coordinator.strokeLayer?.frame = CGRect(origin: .zero, size: img.size)
                scrollView.contentSize = img.size
                context.coordinator.updateZoomScales(for: scrollView.bounds.size)
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onTap: onTap,
            onStrokeFinished: onStrokeFinished,
            currentTool: currentTool,
            brushSize: brushSize,
            selectedColor: selectedColor
        )
    }

    public class Coordinator: NSObject, UIScrollViewDelegate {
        var onTap: (CGPoint) -> Void
        var onStrokeFinished: ([CGPoint], CGFloat, UIColor, Bool) -> Void
        var currentTool: ColoringViewModel.DrawingTool
        var brushSize: CGFloat
        var selectedColor: Color

        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        weak var strokeLayer: CAShapeLayer?
        weak var tapGesture: UITapGestureRecognizer?
        weak var drawPanGesture: UIPanGestureRecognizer?

        private var currentPoints: [CGPoint] = []

        init(
            onTap: @escaping (CGPoint) -> Void,
            onStrokeFinished: @escaping ([CGPoint], CGFloat, UIColor, Bool) -> Void,
            currentTool: ColoringViewModel.DrawingTool,
            brushSize: CGFloat,
            selectedColor: Color
        ) {
            self.onTap = onTap
            self.onStrokeFinished = onStrokeFinished
            self.currentTool = currentTool
            self.brushSize = brushSize
            self.selectedColor = selectedColor
        }

        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }

        public func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImage()
        }

        func updateZoomScales(for viewSize: CGSize) {
            guard let scrollView = scrollView, let imageView = imageView, let image = imageView.image else { return }
            guard image.size.width > 0 && image.size.height > 0 && viewSize.width > 0 && viewSize.height > 0 else { return }

            let widthScale = viewSize.width / image.size.width
            let heightScale = viewSize.height / image.size.height
            let minScale = min(widthScale, heightScale)

            scrollView.minimumZoomScale = minScale
            scrollView.maximumZoomScale = max(minScale * 5.0, 5.0)
            scrollView.zoomScale = minScale
            centerImage()
        }

        private func centerImage() {
            guard let scrollView = scrollView, let imageView = imageView else { return }
            let boundsSize = scrollView.bounds.size
            var frameToCenter = imageView.frame

            if frameToCenter.size.width < boundsSize.width {
                frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
            } else {
                frameToCenter.origin.x = 0
            }

            if frameToCenter.size.height < boundsSize.height {
                frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
            } else {
                frameToCenter.origin.y = 0
            }

            imageView.frame = frameToCenter
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let imageView = imageView else { return }
            let pointInView = gesture.location(in: imageView)

            if currentTool == .fill {
                onTap(pointInView)
            } else {
                // Stamp a single dot for brush/eraser tap
                let isEraser = (currentTool == .eraser)
                let color = UIColor(selectedColor)
                onStrokeFinished([pointInView], brushSize, color, isEraser)
            }
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let point = gesture.location(in: imageView)
                let zoomRect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }

        @objc func handleDrawPan(_ gesture: UIPanGestureRecognizer) {
            guard let imageView = imageView, let strokeLayer = strokeLayer else { return }
            let pt = gesture.location(in: imageView)
            let clampedPt = CGPoint(
                x: max(0, min(pt.x, imageView.bounds.width)),
                y: max(0, min(pt.y, imageView.bounds.height))
            )

            switch gesture.state {
            case .began:
                currentPoints = [clampedPt]
                let isEraser = (currentTool == .eraser)
                let strokeColor = isEraser ? UIColor.white : UIColor(selectedColor)
                strokeLayer.strokeColor = strokeColor.cgColor
                strokeLayer.lineWidth = brushSize

                let dotPath = UIBezierPath(
                    arcCenter: clampedPt,
                    radius: brushSize / 2.0,
                    startAngle: 0,
                    endAngle: CGFloat.pi * 2,
                    clockwise: true
                )
                strokeLayer.path = dotPath.cgPath

            case .changed:
                currentPoints.append(clampedPt)
                guard currentPoints.count > 1 else { return }

                let path = UIBezierPath()
                path.move(to: currentPoints[0])
                for i in 1..<currentPoints.count {
                    let p0 = currentPoints[i - 1]
                    let p1 = currentPoints[i]
                    let mid = CGPoint(x: (p0.x + p1.x) / 2.0, y: (p0.y + p1.y) / 2.0)
                    path.addQuadCurve(to: mid, controlPoint: p0)
                }
                path.addLine(to: currentPoints.last!)
                strokeLayer.path = path.cgPath

            case .ended:
                currentPoints.append(clampedPt)
                strokeLayer.path = nil
                if !currentPoints.isEmpty {
                    let pts = currentPoints
                    currentPoints = []
                    let isEraser = (currentTool == .eraser)
                    let color = UIColor(selectedColor)
                    onStrokeFinished(pts, brushSize, color, isEraser)
                }

            case .cancelled, .failed:
                currentPoints = []
                strokeLayer.path = nil

            default:
                break
            }
        }
    }
}
