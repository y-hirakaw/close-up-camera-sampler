import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    // MARK: Session Management
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var setupResult: SessionSetupResult = .success
    var captureDeviceInput: AVCaptureDeviceInput!
    private let capturePhotoOutput = AVCapturePhotoOutput()

    @IBOutlet private var previewView: CameraPreviewView!

    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        previewView.session = session

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            setupResult = .notAuthorized
        }

        sessionQueue.async {
            self.configureSession()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "Doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings",
                                                                                     comment: "Alert button to open Settings"),
                                                            style: .`default`, handler: { _ in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    }))
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    self.showAlert("Unable to capture media")
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }

        super.viewWillDisappear(animated)
    }

    @IBAction func captureButtonTapped(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        capturePhotoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: Session Configuration
    private func configureSession() {
        if self.setupResult != .success {
            return
        }

        session.beginConfiguration()

        if !setUpCaptureDeviceInput() {
            session.commitConfiguration()
            return
        }

        if !setUpCapturePhotoOutput() {
            session.commitConfiguration()
            return
        }

        setUpOtherSettings()
        session.commitConfiguration()
    }

    func setUpCaptureDeviceInput() -> Bool {
        do {
            let captureDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

            guard let captureDevice = captureDevice else {
                print("Could not get camera device")
                setupResult = .configurationFailed
                return false
            }

            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

            if session.canSetSessionPreset(.photo) {
                session.sessionPreset = .photo
            }

            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
                self.captureDeviceInput = deviceInput
            } else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                return false
            }
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            return false
        }
        return true
    }

    open func setUpCapturePhotoOutput() -> Bool {
        if session.canAddOutput(capturePhotoOutput) {
            session.addOutput(capturePhotoOutput)
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return false
        }
        return true
    }

    open func setUpOtherSettings() {
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Capture failed: \(error.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            return
        }

        saveImage(imageData)
    }

    /// カメラロールに保存
    private func saveImage(_ imageData: Data) {
        guard let image = UIImage(data: imageData) else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(savedPhotosAlbum(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func savedPhotosAlbum(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(error.localizedDescription)
        } else {
            showAlert("Image saved to Camera Roll")
        }
    }
}
