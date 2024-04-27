import UIKit
import AVFoundation

class CameraViewController: UIViewController {

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
                    let changePrivacySetting = "カメラの使用許可がありません。プライバシー設定を変更してください。"
                    let message = NSLocalizedString(changePrivacySetting, comment: "ユーザがカメラへのアクセスを拒否した場合の警告メッセージ")
                    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: "設定", style: .`default`, handler: { _ in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    }))
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    self.showAlert("メディアをキャプチャできません")
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
                print("カメラデバイスを取得できませんでした")
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
                print("カメラ入力をセッションに追加できませんでした")
                setupResult = .configurationFailed
                return false
            }
        } catch {
            print("デバイス入力を作成できませんでした: \(error)")
            setupResult = .configurationFailed
            return false
        }
        return true
    }

    open func setUpCapturePhotoOutput() -> Bool {
        if session.canAddOutput(capturePhotoOutput) {
            session.addOutput(capturePhotoOutput)
        } else {
            print("出力セッションに追加できませんでした")
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
            print("キャプチャ失敗: \(error.localizedDescription)")
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
            showAlert("カメラロールに保存された画像")
        }
    }
}
