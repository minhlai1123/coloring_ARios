import SwiftUI

/// AR Drawing Studio View projecting line-art stencil over real-time camera feed for paper tracing
public struct ARDrawingScreen: View {
    @StateObject private var viewModel: ARDrawingViewModel
    @Environment(\.dismiss) private var dismiss

    public init(item: ColoringItem) {
        _viewModel = StateObject(wrappedValue: ARDrawingViewModel(item: item))
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 1. Live Camera Preview Layer
            if viewModel.isCameraAuthorized {
                CameraPreviewView(session: viewModel.captureSession)
                    .ignoresSafeArea()
            } else if let error = viewModel.cameraError {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.6))
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            // 2. Interactive Stencil Overlay Layer
            TracingOverlayView(
                image: viewModel.overlayImage,
                opacity: viewModel.opacity,
                isLocked: viewModel.isLocked,
                scale: $viewModel.scale,
                offset: $viewModel.offset,
                rotationAngle: $viewModel.rotationAngle
            )

            // 3. Top Controls Bar
            VStack {
                HStack(spacing: 16) {
                    // Close button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }

                    Spacer()

                    // Flashlight button
                    Button(action: { viewModel.toggleFlashlight() }) {
                        Image(systemName: viewModel.isFlashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.title2)
                            .foregroundColor(viewModel.isFlashlightOn ? .yellow : .white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    // Reset Transform button
                    Button(action: { viewModel.resetTransform() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    // Lock / Unlock button
                    Button(action: { viewModel.toggleLock() }) {
                        Image(systemName: viewModel.isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.title2)
                            .foregroundColor(viewModel.isLocked ? .green : .white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // 4. Bottom Controls Bar (Opacity & Instructions)
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white.opacity(0.8))

                        Slider(value: $viewModel.opacity, in: 0.1...1.0)
                            .tint(.white)

                        Text("\(Int(viewModel.opacity * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.65))
                    .cornerRadius(16)

                    // Helper Prompt
                    Text(viewModel.isLocked ? "🔒 Stencil locked in place. Trace on paper!" : "Pinch, rotate & drag to align over paper, then lock.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            viewModel.stopCameraSession()
        }
    }
}
