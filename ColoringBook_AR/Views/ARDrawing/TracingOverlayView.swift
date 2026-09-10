import SwiftUI

/// Stencil Overlay View rendering the transparent `ar_ready` line-art over camera preview.
/// Supports interactive Pinch to Zoom, Drag to Pan, and Rotation gestures (disabled when locked).
public struct TracingOverlayView: View {
    let image: UIImage?
    let opacity: Double
    let isLocked: Bool
    let isFlippedHorizontal: Bool
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var rotationAngle: Angle

    // Gesture transient state
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureOffset: CGSize = .zero
    @GestureState private var gestureRotation: Angle = .zero

    public init(
        image: UIImage?,
        opacity: Double,
        isLocked: Bool,
        isFlippedHorizontal: Bool = false,
        scale: Binding<CGFloat>,
        offset: Binding<CGSize>,
        rotationAngle: Binding<Angle>
    ) {
        self.image = image
        self.opacity = opacity
        self.isLocked = isLocked
        self.isFlippedHorizontal = isFlippedHorizontal
        self._scale = scale
        self._offset = offset
        self._rotationAngle = rotationAngle
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let img = image {
                    let effectiveScale = scale * (isLocked ? 1.0 : gestureScale)

                    Image(uiImage: img)
                        .resizable()
                        .renderingMode(.template) // Allows crisp stencil visibility
                        .foregroundColor(.black)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width * 0.85, maxHeight: geometry.size.height * 0.7)
                        .opacity(opacity)
                        .scaleEffect(
                            x: effectiveScale * (isFlippedHorizontal ? -1.0 : 1.0),
                            y: effectiveScale
                        )
                        .rotationEffect(rotationAngle + (isLocked ? .zero : gestureRotation))
                        .offset(
                            x: offset.width + (isLocked ? 0 : gestureOffset.width),
                            y: offset.height + (isLocked ? 0 : gestureOffset.height)
                        )
                        .gesture(isLocked ? nil : combinedGesture)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // Combined gesture: Drag + Magnification + Rotation simultaneously
    private var combinedGesture: some Gesture {
        let drag = DragGesture()
            .updating($gestureOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                offset.width += value.translation.width
                offset.height += value.translation.height
            }

        let magnification = MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                scale = max(0.4, min(scale * value, 4.0))
            }

        let rotation = RotationGesture()
            .updating($gestureRotation) { value, state, _ in
                state = value
            }
            .onEnded { value in
                rotationAngle += value
            }

        return drag.simultaneously(with: magnification).simultaneously(with: rotation)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        TracingOverlayView(
            image: nil,
            opacity: 0.7,
            isLocked: false,
            isFlippedHorizontal: false,
            scale: .constant(1.0),
            offset: .constant(.zero),
            rotationAngle: .constant(.zero)
        )
    }
}
