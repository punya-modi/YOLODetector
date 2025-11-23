//
//  VisionProcessor.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation
import Vision
import CoreML
import ARKit
import RealityKit

class VisionProcessor {
    private var visionModel: VNCoreMLModel
    private var requests = [VNRequest]()
    private var isProcessing = false
    
    private var lastVisionTime: TimeInterval = 0
    private let visionInterval = DetectionSettings.visionInterval
    
    var onDetectionComplete: (([RawDetection], Error?) -> Void)?
    
    init(model: VNCoreMLModel) {
        self.visionModel = model
        setupVision()
    }
    
    private func setupVision() {
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            self?.handleVisionRequest(request: request, error: error)
        }
        request.imageCropAndScaleOption = .scaleFill
        self.requests = [request]
    }
    
    func processFrame(_ frame: ARFrame) -> Bool {
        let currentTime = CACurrentMediaTime()
        
        guard !isProcessing && (currentTime - lastVisionTime > visionInterval) else {
            return false
        }
        
        isProcessing = true
        lastVisionTime = currentTime
        
        let pixelBuffer = frame.capturedImage
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try imageRequestHandler.perform(self.requests)
            } catch {
                DispatchQueue.main.async {
                    self.onDetectionComplete?([], error)
                }
            }
        }
        
        return true
    }
    
    private func handleVisionRequest(request: VNRequest, error: Error?) {
        defer { isProcessing = false }
        
        if let error = error {
            onDetectionComplete?([], error)
            return
        }
        
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            onDetectionComplete?([], nil)
            return
        }
        
        var detections: [RawDetection] = []
        
        for observation in results {
            guard let label = observation.labels.first,
                  label.confidence > DetectionSettings.confidenceThreshold else {
                continue
            }
            
            let rect = CGRect(
                x: observation.boundingBox.origin.x,
                y: 1 - observation.boundingBox.origin.y - observation.boundingBox.height,
                width: observation.boundingBox.width,
                height: observation.boundingBox.height
            )
            
            detections.append(RawDetection(
                label: label.identifier,
                confidence: label.confidence,
                rect: rect,
                distance: 0.0 // Will be calculated separately
            ))
        }
        
        onDetectionComplete?(detections, nil)
    }
}
