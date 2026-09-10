import SwiftUI
import UIKit

/// High-performance Zoomable Container using UIScrollView for smooth 1x to 5x zooming and panning.
/// Maps tap coordinates directly to underlying image pixel coordinates for accurate flood fill.
public struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage?
    let onTap: (CGPoint) -> Void

    public init(image: UIImage?, onTap: @escaping (CGPoint) -> Void) {
        self.image = image
        self.onTap = onTap
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

        // Single Tap gesture for coloring
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        imageView.addGestureRecognizer(tapGesture)

        // Double Tap gesture for quick zoom reset
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)
        tapGesture.require(toFail: doubleTapGesture)

        return scrollView
    }

    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.onTap = onTap
        guard let imageView = context.coordinator.imageView else { return }

        if imageView.image !== image {
            imageView.image = image
            if let img = image {
                imageView.frame = CGRect(origin: .zero, size: img.size)
                scrollView.contentSize = img.size
                context.coordinator.updateZoomScales(for: scrollView.bounds.size)
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    public class Coordinator: NSObject, UIScrollViewDelegate {
        var onTap: (CGPoint) -> Void
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?

        init(onTap: @escaping (CGPoint) -> Void) {
            self.onTap = onTap
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
            onTap(pointInView)
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
    }
}
