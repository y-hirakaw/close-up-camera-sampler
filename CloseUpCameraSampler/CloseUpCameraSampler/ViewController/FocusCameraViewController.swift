import UIKit
import AVFoundation

class FocusCameraViewController: CameraViewController {

    override func setUpOtherSettings() {
        super.setUpOtherSettings()
        DispatchQueue.main.async {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTapFocus(_:)))
            self.previewView.addGestureRecognizer(tapGesture)
        }
    }

    func changeFocusPoint(_ focusPoint: CGPoint) {
        do {
            try captureDeviceInput.device.lockForConfiguration()
            captureDeviceInput.device.focusPointOfInterest = focusPoint
            captureDeviceInput.device.focusMode = .autoFocus
            captureDeviceInput.device.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }

    @objc func handleTapFocus(_ recognizer: UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: recognizer.view)
        print(pointInView)
        changeFocusPoint(pointInView)
    }
}
