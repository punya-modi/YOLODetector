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
import CoreML
import UIKit

struct RawDetection {
    let label: String
    let confidence: Float
    let rect: CGRect
    let distance: Float
}

class ARManager: NSObject, ObservableObject, ARSessionDelegate {
    @Published var predictions: [Prediction] = []
    
    // Radar / Safety Cone Data
    @Published var obstacleLabel: String = ""
    @Published var obstacleDistance: String = ""
    @Published var obstacleColor: UIColor = .clear
    
    // Performance Metrics
    @Published var fps: Double = 0
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Double = 0
    
    // Error State
    @Published var errorMessage: String?
    @Published var hasError: Bool = false
    
    var arView: ARView?
    
    // Separated Components
    private var visionProcessor: VisionProcessor?
    private let radarProcessor = RadarProcessor()
    private let objectTracker = ObjectTracker()
    private let distanceMeasurer = DistanceMeasurer()
    private let performanceMonitor = PerformanceMonitor()
    
    private var closestObstacleTracker: TrackedObject?
    
    override init() {
        super.init()
        setupComponents()
    }
    
    private func setupComponents() {
        // Initialize Vision Processor with error handling
        do {
            let coreMLModel = try yolov8n(configuration: MLModelConfiguration())
            guard let visionModel = try? VNCoreMLModel(for: coreMLModel.model) else {
                throw DetectionError.visionModelCreationFailed
            }
            
            visionProcessor = VisionProcessor(model: visionModel)
            setupVisionCallbacks()
        } catch {
            handleError(DetectionError.modelLoadFailed(error.localizedDescription))
            return
        }
        
        // Setup Radar Processor
        radarProcessor.onObstacleDetected = { [weak self] distance, point in
            self?.handleObstacleDetected(distance: distance, point: point)
        }
        
        // Initialize closest obstacle tracker
        closestObstacleTracker = TrackedObject(label: "Scanning...", rect: .zero, distance: 0.0)
        
        // Setup performance monitoring callbacks
        performanceMonitor.$fps
            .receive(on: DispatchQueue.main)
            .assign(to: &$fps)
        
        performanceMonitor.$cpuUsage
            .receive(on: DispatchQueue.main)
            .assign(to: &$cpuUsage)
        
        performanceMonitor.$memoryUsage
            .receive(on: DispatchQueue.main)
            .assign(to: &$memoryUsage)
    }
    
    private func setupVisionCallbacks() {
        visionProcessor?.onDetectionComplete = { [weak self] detections, error in
            if let error = error {
                self?.handleError(DetectionError.arSessionFailed(error.localizedDescription))
                return
            }
            
            guard let self = self, let arView = self.arView else { return }
            
            // Measure distances for each detection
            var detectionsWithDistance: [RawDetection] = []
            for detection in detections {
                let distance = self.distanceMeasurer.measureDistance(
                    boundingBox: CGRect(
                        x: detection.rect.origin.x,
                        y: 1 - detection.rect.origin.y - detection.rect.height,
                        width: detection.rect.width,
                        height: detection.rect.height
                    ),
                    in: arView
                )
                
                detectionsWithDistance.append(RawDetection(
                    label: detection.label,
                    confidence: detection.confidence,
                    rect: detection.rect,
                    distance: distance
                ))
            }
            
            // Update tracker
            self.objectTracker.update(with: detectionsWithDistance)
            
            // Generate predictions
            DispatchQueue.main.async {
                self.updatePredictions()
                self.performanceMonitor.recordFrame()
            }
        }
    }
    
    // MARK: - ARSession Delegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let arView = arView else { return }
        
        // Run Radar
        radarProcessor.scanForClosestObstacle(in: arView)
        
        // Run Vision
        visionProcessor?.processFrame(frame)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        handleError(DetectionError.arSessionFailed(error.localizedDescription))
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Handle interruption gracefully
        DispatchQueue.main.async {
            self.errorMessage = "AR Session interrupted. Please resume the app."
            self.hasError = true
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Resume session
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.hasError = false
        }
    }
    
    // MARK: - Obstacle Handling
    private func handleObstacleDetected(distance: Float, point: CGPoint?) {
        let validDist = (distance < DetectionSettings.maxDistance && distance > 0) ? distance : 0.0
        closestObstacleTracker?.update(rect: .zero, distance: validDist)
        
        DispatchQueue.main.async {
            self.updateObstacleUI(closestPoint: point)
        }
    }
    
    private func updateObstacleUI(closestPoint: CGPoint?) {
        guard let tracker = closestObstacleTracker else { return }
        let dist = tracker.distanceHistory.last?.1 ?? 0.0
        
        if dist == 0.0 || dist > DetectionSettings.maxDistance {
            self.obstacleLabel = ""
            self.obstacleDistance = ""
            self.obstacleColor = .clear
            return
        }
        
        var matchedLabel = "Obstacle"
        
        // Try to match with tracked objects
        if let point = closestPoint {
            for obj in objectTracker.getTrackedObjects() {
                if obj.rect.contains(point) {
                    matchedLabel = obj.label
                    break
                }
            }
        }
        
        self.obstacleLabel = matchedLabel
        self.obstacleDistance = String(format: "%.1fm", dist)
        
        if tracker.isApproaching {
            self.obstacleLabel = "\(matchedLabel) (APPROACHING)"
            self.obstacleColor = .red
        } else {
            self.obstacleColor = .yellow
        }
    }
    
    // MARK: - Predictions
    private func updatePredictions() {
        var finalPredictions: [Prediction] = []
        
        for tracker in objectTracker.getTrackedObjects() {
            if (tracker.distanceHistory.last?.1 ?? 100) < DetectionSettings.maxDistance {
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
    
    // MARK: - Error Handling
    private func handleError(_ error: DetectionError) {
        DispatchQueue.main.async {
            self.errorMessage = error.errorDescription
            self.hasError = true
            print("Error: \(error.errorDescription ?? "Unknown error")")
            if let suggestion = error.recoverySuggestion {
                print("Suggestion: \(suggestion)")
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
        hasError = false
    }
}
