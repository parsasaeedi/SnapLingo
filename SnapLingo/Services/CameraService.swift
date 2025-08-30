import AVFoundation
import Vision
import CoreML
import UIKit
import Combine

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isAuthorized = false
    @Published var error: CameraError?
    @Published var isConfigured = false
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfiguring = false
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    
    // Expose the session for preview layers
    var captureSession: AVCaptureSession { session }
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    enum CameraError: Error, LocalizedError {
        case notAuthorized
        case sessionConfigurationFailed
        case deviceNotFound
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access is required for SnapLingo"
            case .sessionConfigurationFailed:
                return "Failed to configure camera session"
            case .deviceNotFound:
                return "Camera device not found"
            }
        }
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
            error = .notAuthorized
        @unknown default:
            isAuthorized = false
            error = .notAuthorized
        }
    }
    
    private func setupSession() {
        guard !isConfiguring else { return }
        isConfiguring = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    self.error = .deviceNotFound
                    self.isConfiguring = false
                }
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                
                // Set continuous autofocus/exposure if supported
                try? videoDevice.lockForConfiguration()
                if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                    videoDevice.focusMode = .continuousAutoFocus
                }
                if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                    videoDevice.exposureMode = .continuousAutoExposure
                }
                videoDevice.unlockForConfiguration()

                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                }

                // Removed videoOutput addition
                // if self.session.canAddOutput(self.videoOutput) {
                //     self.session.addOutput(self.videoOutput)
                // }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }
                self.photoOutput.isHighResolutionCaptureEnabled = true
                
                self.session.commitConfiguration()

                DispatchQueue.main.async {
                    self.isConfigured = true
                    self.isConfiguring = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.error = .sessionConfigurationFailed
                    self.isConfiguring = false
                }
            }
        }
    }
    
    func startSession() {
        guard !session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        session.stopRunning()
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
    // Future: Object detection using Vision and Core ML
    func detectObject(in image: CVPixelBuffer, targetObject: String) -> Bool {
        // This would integrate with Vision framework and Core ML models
        // For now, return a simulated result
        return Double.random(in: 0...1) < 0.7
    }

    // MARK: - Photo Capture

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard isAuthorized, isConfigured else { completion(nil); return }
        photoCaptureCompletion = completion

        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            let completion = photoCaptureCompletion; photoCaptureCompletion = nil
            completion?(nil)
            return
        }

        var image: UIImage? = nil
        if let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
        }

        let completion = photoCaptureCompletion; photoCaptureCompletion = nil
        completion?(image)
    }
}
