//
//  DistanceMeasurer.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation
import ARKit
import RealityKit

class DistanceMeasurer {
    func measureDistance(boundingBox: CGRect, in arView: ARView) -> Float {
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
            
            let query = arView.makeRaycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .any)
            
            if let query = query {
                let results = arView.session.raycast(query)
                if let result = results.first {
                    let dist = length(result.worldTransform.columns.3)
                    if dist > DetectionSettings.minDistance {
                        validDistances.append(dist)
                    }
                }
            }
        }
        
        return validDistances.min() ?? (DetectionSettings.maxDistance + 1.0)
    }
}
