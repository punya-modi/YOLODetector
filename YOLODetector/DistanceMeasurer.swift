//
//  DistanceMeasurer.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation
import ARKit
import RealityKit

struct DistanceMeasurement {
    let distance: Float
    let isValid: Bool
}

class DistanceMeasurer {
    func measureDistance(boundingBox: CGRect, in arView: ARView) -> DistanceMeasurement {
        let screenWidth = arView.bounds.width
        let screenHeight = arView.bounds.height
        
        let x = boundingBox.origin.x
        let y = 1 - boundingBox.origin.y - boundingBox.height
        let w = boundingBox.width
        let h = boundingBox.height
        
        // Use 5 points (Center + 4 Corners) for distance measurement
        let center = CGPoint(x: x + w/2, y: y + h/2)
        let offset = DetectionSettings.cornerOffset
        let tl = CGPoint(x: x + w*offset, y: y + h*offset)
        let tr = CGPoint(x: x + w*(1-offset), y: y + h*offset)
        let bl = CGPoint(x: x + w*offset, y: y + h*(1-offset))
        let br = CGPoint(x: x + w*(1-offset), y: y + h*(1-offset))
        
        let points = [center, tl, tr, bl, br]
        
        var validDistances: [Float] = []
        
        for normalizedPoint in points {
            let screenPoint = CGPoint(
                x: normalizedPoint.x * screenWidth,
                y: normalizedPoint.y * screenHeight
            )
            
            // Try multiple raycast strategies for better reliability
            var raycastSucceeded = false
            
            // First try with estimated plane (works when ARKit has detected planes)
            if let query = arView.makeRaycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .any) {
                let results = arView.session.raycast(query)
                if let result = results.first {
                    let dist = length(result.worldTransform.columns.3)
                    if dist > DetectionSettings.minDistance && dist < DetectionSettings.maxDistance * 2 {
                        validDistances.append(dist)
                        raycastSucceeded = true
                    }
                }
            }
            
            // Fallback: try with existing plane geometry if available
            if !raycastSucceeded {
                if let query = arView.makeRaycastQuery(from: screenPoint, allowing: .existingPlaneGeometry, alignment: .any) {
                    let results = arView.session.raycast(query)
                    if let result = results.first {
                        let dist = length(result.worldTransform.columns.3)
                        if dist > DetectionSettings.minDistance && dist < DetectionSettings.maxDistance * 2 {
                            validDistances.append(dist)
                            raycastSucceeded = true
                        }
                    }
                }
            }
        }
        
        if let minDistance = validDistances.min() {
            return DistanceMeasurement(distance: minDistance, isValid: true)
        } else {
            // When raycasting fails (e.g., in new areas without plane detection),
            // estimate distance based on bounding box size as fallback
            // Larger boxes are typically closer, smaller boxes are farther
            let boxArea = Float(w * h)
            // Rough estimation: larger boxes = closer objects
            let estimatedDistance = max(DetectionSettings.minDistance, 
                                       min(DetectionSettings.maxDistance, 
                                           2.0 / (boxArea + 0.1)))
            return DistanceMeasurement(distance: estimatedDistance, isValid: false)
        }
    }
}
