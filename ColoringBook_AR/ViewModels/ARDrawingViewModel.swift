import Foundation
import SwiftUI
import AVFoundation
import Combine

/// ViewModel managing AVFoundation Camera session, flashlight, stencil transformations, and lock states
@MainActor
public final class ARDrawingViewModel: ObservableObject {
    public let item: ColoringItem

    // Overlay Stencil State
    @Published public private(set) var overlayImage: UIImage?
    @Published public var opacity: Double = 0.65 // 10% - 100%
    @Published public var scale: CGFloat = 1.0
    @Published public var offset: CGSize = .zero
    @Published public var rotationAngle: Angle = .zero
    @Published public var isLocked: Bool = false
    @Published public var isFlippedHorizontal: Bool = false
    @Published public var isFlashlightOn: Bool = false

    // Camera Session State
    @Published public private(set) var isCameraAuthorized: Bool = false
    @Published public private(set) var cameraError: String?

    public let captureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private let repository: ImageRepositoryProtocol

    public init(
        item: ColoringItem,
        repository: ImageRepositoryProtocol = ImageRepository.shared
    ) {
        self.item = item
        self.repository = repository
        loadOverlay()
        checkCameraPermissions()
    }

    public func loadOverlay() {
        self.overlayImage = repository.loadAROverlay(for: item)
    }

    // MARK: - Camera Session Lifecycle

    public func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isCameraAuthorized = true
            setupCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isCameraAuthorized = granted
                    if granted {
                        self.setupCameraSession()
                    } else {
                        self.cameraError = "Camera access is needed to project drawing stencils onto your paper."
                    }
                }
            }
        case .denied, .restricted:
            self.isCameraAuthorized = false
            self.cameraError = "Camera access denied. Please enable Camera permissions in iOS Settings."
        @unknown default:
            break
        }
    }

    private func setupCameraSession() {
        guard !captureSession.isRunning else { return }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            self.cameraError = "No back camera available on this device."
            captureSession.commitConfiguration()
            return
        }
        self.videoDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            self.cameraError = "Unable to initialize camera input: \(error.localizedDescription)"
        }

        captureSession.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    public func stopCameraSession() {
        if isFlashlightOn {
            toggleFlashlight(false)
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    // MARK: - Flashlight / Torch Control

    public func toggleFlashlight(_ enable: Bool? = nil) {
        guard let device = videoDevice, device.hasTorch else { return }

        let targetState = enable ?? !isFlashlightOn
        do {
            try device.lockForConfiguration()
            if targetState {
                try device.setTorchModeOn(level: 1.0)
                isFlashlightOn = true
            } else {
                device.torchMode = .off
                isFlashlightOn = false
            }
            device.unlockForConfiguration()
        } catch {
            print("Flashlight error: \(error.localizedDescription)")
        }
    }

    // MARK: - Stencil Transform Manipulations

    public func resetTransform() {
        HapticFeedback.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.scale = 1.0
            self.offset = .zero
            self.rotationAngle = .zero
            self.isFlippedHorizontal = false
        }
    }

    public func toggleFlipHorizontal() {
        HapticFeedback.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.isFlippedHorizontal.toggle()
        }
    }

    public func toggleLock() {
        HapticFeedback.medium()
        withAnimation(.easeInOut(duration: 0.2)) {
            self.isLocked.toggle()
        }
    }
}
