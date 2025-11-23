//
//  ARManager.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation
import ARKit
import RealityKit
import Vision
import Combine
import CoreImage
import UIKit

struct RawDetection {
    let label: String
    let confidence: Float
    let rect: CGRect
    let distance: Float
}

class ARManager: NSObject, ObservableObject, ARSessionDelegate {
    @Published var predictions: [Prediction] = []
    @Published var fps: Double = 0
    
    var arView: ARView?
    
    private var trackedObjects: [TrackedObject] = []
    
    // SETTINGS
    private let maxDistance: Float = 5.0
    private let confidenceThreshold: Float = 0.6
    
    // OPTIMIZATION: Throttling
    private var lastVisionTime: TimeInterval = 0
    private let visionInterval: TimeInterval = 0.1 // Cap YOLO at 10 FPS
    
    // Vision
    private var visionModel: VNCoreMLModel
    private var requests = [VNRequest]()
    private var isProcessing = false
    
    // FPS Calculation
    private var lastExecutionTime: TimeInterval = 0
    
    override init() {
        guard let coreMLModel = try? yolov8n(configuration: MLModelConfiguration()),
              let visionModel = try? VNCoreMLModel(for: coreMLModel.model) else {
            fatalError("Failed to load model")
        }
        self.visionModel = visionModel
        super.init()
        setupVision()
    }
    
    func setupVision() {
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            self?.handleVisionRequest(request: request, error: error)
        }
        request.imageCropAndScaleOption = .scaleFill
        self.requests = [request]
    }
    
    // MARK: - ARSession Delegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let currentTime = CACurrentMediaTime()
        
        // Run Vision (Throttled)
        if !isProcessing && (currentTime - lastVisionTime > visionInterval) {
            isProcessing = true
            lastVisionTime = currentTime
            
            let pixelBuffer = frame.capturedImage
            // Note: Creating VNImageRequestHandler is cheap, performing request is heavy
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
            
            DispatchQueue.global(qos: .userInteractive).async {
                try? imageRequestHandler.perform(self.requests)
            }
        }
    }
    
    // MARK: - VISION PROCESSING
    func handleVisionRequest(request: VNRequest, error: Error?) {
        // FPS Calculation
        let currentTime = CACurrentMediaTime()
        if lastExecutionTime > 0 {
            let processingTime = currentTime - lastExecutionTime
            if processingTime > 0 {
                let currentFPS = 1.0 / processingTime
                DispatchQueue.main.async {
                    self.fps = (self.fps * 0.9) + (currentFPS * 0.1)
                }
            }
        }
        lastExecutionTime = currentTime
        
        defer { isProcessing = false }
        
        guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let arView = self.arView else { return }
            
            var currentDetections: [RawDetection] = []
            
            for observation in results {
                guard let label = observation.labels.first, label.confidence > self.confidenceThreshold else { continue }
                
                let distance = self.measureDistance(boundingBox: observation.boundingBox, in: arView)
                
                let rect = CGRect(
                    x: observation.boundingBox.origin.x,
                    y: 1 - observation.boundingBox.origin.y - observation.boundingBox.height,
                    width: observation.boundingBox.width,
                    height: observation.boundingBox.height
                )
                
                currentDetections.append(RawDetection(label: label.identifier, confidence: label.confidence, rect: rect, distance: distance))
            }
            
            self.updateTracker(with: currentDetections)
            
            var finalPredictions: [Prediction] = []
            for tracker in self.trackedObjects {
                if (tracker.distanceHistory.last?.1 ?? 100) < self.maxDistance {
                    let prediction = Prediction(
                        label: tracker.label,
                        classIndex: 0,
                        confidence: 1.0,
                        rect: tracker.rect,
                        velocity: tracker.velocity,
                        isApproaching: tracker.isApproaching
                    )
                    finalPredictions.append(prediction)
                }
            }
            self.predictions = finalPredictions
        }
    }
    
    // MARK: - TRACKING LOGIC
    private func updateTracker(with detections: [RawDetection]) {
        var unmatchedDetections = detections
        
        for tracker in trackedObjects {
            var bestMatchIndex: Int?
            var bestMatchDistance: CGFloat = 0.2
            
            for (index, detection) in unmatchedDetections.enumerated() {
                if detection.label == tracker.label {
                    let dist = distanceBetween(rect1: tracker.rect, rect2: detection.rect)
                    if dist < bestMatchDistance {
                        bestMatchDistance = dist
                        bestMatchIndex = index
                    }
                }
            }
            
            if let index = bestMatchIndex {
                let match = unmatchedDetections[index]
                tracker.update(rect: match.rect, distance: match.distance)
                unmatchedDetections.remove(at: index)
            }
        }
        
        for detection in unmatchedDetections {
            let newTracker = TrackedObject(label: detection.label, rect: detection.rect, distance: detection.distance)
            trackedObjects.append(newTracker)
        }
        
        let now = Date().timeIntervalSince1970
        trackedObjects.removeAll { now - $0.lastSeen > 0.5 }
    }
    
    private func distanceBetween(rect1: CGRect, rect2: CGRect) -> CGFloat {
        let p1 = CGPoint(x: rect1.midX, y: rect1.midY)
        let p2 = CGPoint(x: rect2.midX, y: rect2.midY)
        return hypot(p1.x - p2.x, p1.y - p2.y)
    }
    
    // MARK: - DISTANCE MEASUREMENT (Optimized 5-point)
    private func measureDistance(boundingBox: CGRect, in arView: ARView) -> Float {
        let screenWidth = arView.bounds.width
        let screenHeight = arView.bounds.height
        
        let x = boundingBox.origin.x
        let y = 1 - boundingBox.origin.y - boundingBox.height
        let w = boundingBox.width
        let h = boundingBox.height
        
        // OPTIMIZATION: Use 5 points (Center + 4 Corners) instead of full 3x3 grid
        // This reduces rays from 9 to 5 per object.
        let center = CGPoint(x: x + w/2, y: y + h/2)
        let tl = CGPoint(x: x + w*0.2, y: y + h*0.2)
        let tr = CGPoint(x: x + w*0.8, y: y + h*0.2)
        let bl = CGPoint(x: x + w*0.2, y: y + h*0.8)
        let br = CGPoint(x: x + w*0.8, y: y + h*0.8)
        
        let points = [center, tl, tr, bl, br]
        
        var validDistances: [Float] = []
        
        for normalizedPoint in points {
            let screenPoint = CGPoint(
                x: normalizedPoint.x * screenWidth,
                y: normalizedPoint.y * screenHeight
            )
            
            // Use .estimatedPlane for speed
            let query = arView.makeRaycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .any)
            
            if let query = query {
                let results = arView.session.raycast(query)
                if let result = results.first {
                    let dist = length(result.worldTransform.columns.3)
                    if dist > 0.1 {
                        validDistances.append(dist)
                    }
                }
            }
        }
        
        return validDistances.min() ?? (self.maxDistance + 1.0)
    }
}

func length(_ vector: SIMD4<Float>) -> Float {
    return sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
}
