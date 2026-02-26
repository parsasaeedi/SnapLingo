import AVFoundation
import Vision
import CoreML
import UIKit
import CoreImage
import Combine

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isAuthorized = false
    @Published var error: CameraError?
    @Published var isConfigured = false
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfiguring = false
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    private var latestPixelBuffer: CVPixelBuffer?
    private let ciContext = CIContext()
    
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

                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                    self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CameraVideoQueue"))
                }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }
                
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

    func captureCurrentFrame(completion: @escaping (UIImage?) -> Void) {
        guard let pb = latestPixelBuffer else { completion(nil); return }
        let ci = CIImage(cvPixelBuffer: pb)
        let rect = ci.extent
        if let cg = ciContext.createCGImage(ci, from: rect) {
            completion(UIImage(cgImage: cg))
        } else {
            completion(nil)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pb = CMSampleBufferGetImageBuffer(sampleBuffer) {
            latestPixelBuffer = pb
        }
    }
}
