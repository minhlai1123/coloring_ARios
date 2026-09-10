import SwiftUI
import UIKit
import AVFoundation

/// UIViewRepresentable hosting AVCaptureVideoPreviewLayer for real-time camera feed
public struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    public init(session: AVCaptureSession) {
        self.session = session
    }

    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

public class CameraPreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
