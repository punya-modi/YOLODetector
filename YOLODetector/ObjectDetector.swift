//
//  ObjectDetector.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/10/25.
//

import Vision
import CoreML
import UIKit
import Combine

class ObjectDetector: ObservableObject {
    @Published var predictions: [Prediction] = []
    private var model: VNCoreMLModel

    init() {
        // Load the model
        guard let coreMLModel = try? yolov8m(configuration: MLModelConfiguration()) else {
            fatalError("Failed to load Core ML model.")
        }
        
        // Create a VNCoreMLModel from the Core ML model
        guard let visionModel = try? VNCoreMLModel(for: coreMLModel.model) else {
            fatalError("Failed to create VNCoreMLModel.")
        }
        self.model = visionModel
    }

    func performDetection(on frame: CGImage) {
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.handleDetectionResults(request, error: error)
        }
        
        request.imageCropAndScaleOption = .scaleFill

        // Perform the request
        let handler = VNImageRequestHandler(cgImage: frame)
        try? handler.perform([request])
    }

    private func handleDetectionResults(_ request: VNRequest, error: Error?) {
        if let error = error {
            print("Vision request failed with error: \(error)")
            return
        }

        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return
        }

        let detectedObjects = results.compactMap { observation -> Prediction? in
            // The model's output bounding box is normalized and has its origin at the bottom-left.
            // We need to convert it to the top-left coordinate system.
            let boundingBox = observation.boundingBox
            let convertedRect = CGRect(
                x: boundingBox.origin.x,
                y: 1 - boundingBox.origin.y - boundingBox.height,
                width: boundingBox.width,
                height: boundingBox.height
            )

            guard let bestLabel = observation.labels.first else {
                return nil
            }
            
            print("Model is saying \(bestLabel.identifier) with confidence level \(bestLabel.confidence)")

            return Prediction(
                label: bestLabel.identifier,
                classIndex: Int(bestLabel.identifier) ?? 0,
                confidence: bestLabel.confidence,
                rect: convertedRect,
                // ADD THESE LINES:
                velocity: 0.0,       // Default for non-AR detector
                isApproaching: false // Default for non-AR detector
            )
        }
        
        DispatchQueue.main.async {
            self.predictions = detectedObjects
        }
    }
}
