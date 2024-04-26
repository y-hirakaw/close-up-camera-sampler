import UIKit
import AVFoundation

class CameraPreviewView: UIView {

    var previewLayer: AVCaptureVideoPreviewLayer? {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            return nil
        }
        return layer
    }

    var session: AVCaptureSession? {
        get {
            return previewLayer?.session
        }
        set {
            if let newSession = newValue {
                previewLayer?.session = newSession
            }
        }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override func layoutSublayers(of: CALayer) {
        super.layoutSublayers(of: layer)
        previewLayer?.frame = bounds
    }
}
