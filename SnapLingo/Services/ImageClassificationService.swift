import Foundation
import Vision
import CoreML
import UIKit
import ImageIO

final class ImageClassificationService {
    private let queue = DispatchQueue(label: "ImageClassificationService.queue")
    private let vnModel: VNCoreMLModel?

    struct Result: Equatable {
        let identifier: String
        let confidence: Float
    }

    init() {
        if let coreMLModel = try? FastViTT8F16(configuration: MLModelConfiguration()).model,
           let vnModel = try? VNCoreMLModel(for: coreMLModel) {
            self.vnModel = vnModel
        } else {
            self.vnModel = nil
        }
    }

    func classify(image: UIImage, topK: Int = 10, completion: @escaping ([Result]) -> Void) {
        guard let cg = image.cgImage else { completion([]); return }
        classify(cgImage: cg, orientation: image.cgImageOrientation, topK: topK, completion: completion)
    }

    func classify(cgImage: CGImage, orientation: CGImagePropertyOrientation = .up, topK: Int = 10, completion: @escaping ([Result]) -> Void) {
        guard let vnModel else { completion([]); return }
        queue.async {
            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            do {
                try handler.perform([request])
                let observations = (request.results as? [VNClassificationObservation]) ?? []
                let results = observations.prefix(topK).map { Result(identifier: $0.identifier, confidence: $0.confidence) }
                DispatchQueue.main.async { completion(results) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }
    }

    func classify(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .up, topK: Int = 10, completion: @escaping ([Result]) -> Void) {
        guard let vnModel else { completion([]); return }
        queue.async {
            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
            do {
                try handler.perform([request])
                let observations = (request.results as? [VNClassificationObservation]) ?? []
                let results = observations.prefix(topK).map { Result(identifier: $0.identifier, confidence: $0.confidence) }
                DispatchQueue.main.async { completion(results) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
