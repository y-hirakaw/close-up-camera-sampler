import UIKit
import AVFoundation

class SwitchCameraViewController: CameraViewController {

    override func setUpOtherSettings() {
        super.setUpOtherSettings()
        setSwitchZoomFactor()
    }

    func setSwitchZoomFactor() {
        guard let zoomFactor = captureDeviceInput.device.virtualDeviceSwitchOverVideoZoomFactors.first else {
            return
        }
        try? captureDeviceInput.device.lockForConfiguration()
        captureDeviceInput.device.videoZoomFactor = CGFloat(truncating: zoomFactor)
        captureDeviceInput.device.unlockForConfiguration()
    }
}
