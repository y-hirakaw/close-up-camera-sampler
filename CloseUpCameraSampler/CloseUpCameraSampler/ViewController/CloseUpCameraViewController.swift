import UIKit
import AVFoundation

class CloseUpCameraViewController: CameraViewController {

    private let initialCloseUpTargetSize = Float(40)

    private var rectOfInterestWidth = Double()
    private var rectOfInterestHeight = Double()

    // MARK: Zoom Management
    @IBOutlet private var zoomSlider: UISlider!

    override func setUpCapturePhotoOutput() -> Bool {
        let result = super.setUpCapturePhotoOutput()
        setRectOfInterest()
        return result
    }

    override func setUpOtherSettings() {
        super.setUpOtherSettings()
        setRecommendedZoomFactor()
        DispatchQueue.main.async {
            self.zoomSlider.maximumValue = Float(min(self.captureDeviceInput.device.activeFormat.videoMaxZoomFactor, CGFloat(8.0)))
            self.zoomSlider.value = Float(self.captureDeviceInput.device.videoZoomFactor)
            self.zoomSlider.isEnabled = true
        }
    }

    @IBAction private func zoomCamera(with zoomSlider: UISlider) {
        do {
            try captureDeviceInput.device.lockForConfiguration()
            captureDeviceInput.device.videoZoomFactor = CGFloat(zoomSlider.value)
            captureDeviceInput.device.unlockForConfiguration()
        } catch {
            print("Could not lock for configuration: \(error)")
        }
    }

    private func setRectOfInterest() {
        let formatDimensions = CMVideoFormatDescriptionGetDimensions(self.captureDeviceInput.device.activeFormat.formatDescription)
        self.rectOfInterestWidth = Double(formatDimensions.height) / Double(formatDimensions.width)
        self.rectOfInterestHeight = 1.0
    }

    private func setRecommendedZoomFactor() {
        let deviceMinimumFocusDistance = Float(self.captureDeviceInput.device.minimumFocusDistance)
        guard deviceMinimumFocusDistance != -1 else { return }

        let deviceFieldOfView = self.captureDeviceInput.device.activeFormat.videoFieldOfView
        let minimumSubjectDistanceForCode = minimumSubjectDistanceForCode(fieldOfView: deviceFieldOfView,
                                                                          minimumCodeSize: self.initialCloseUpTargetSize,
                                                                          previewFillPercentage: Float(self.rectOfInterestWidth))
        if minimumSubjectDistanceForCode < deviceMinimumFocusDistance {
            let zoomFactor = deviceMinimumFocusDistance / minimumSubjectDistanceForCode
            do {
                try captureDeviceInput.device.lockForConfiguration()
                captureDeviceInput.device.videoZoomFactor = CGFloat(zoomFactor)
                captureDeviceInput.device.unlockForConfiguration()
            } catch {
                print("Could not lock for configuration: \(error)")
            }
        }
    }

    private func minimumSubjectDistanceForCode(fieldOfView: Float, minimumCodeSize: Float, previewFillPercentage: Float) -> Float {
        let radians = degreesToRadians(fieldOfView / 2)
        let filledCodeSize = minimumCodeSize / previewFillPercentage
        return filledCodeSize / tan(radians)
    }

    private func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * Float.pi / 180
    }
}
