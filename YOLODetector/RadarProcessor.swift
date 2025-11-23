//
//  RadarProcessor.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation
import ARKit
import RealityKit

class RadarProcessor {
    private var lastRadarTime: TimeInterval = 0
    private let radarInterval = DetectionSettings.radarInterval
    
    var onObstacleDetected: ((Float, CGPoint?) -> Void)?
    
    func scanForClosestObstacle(in arView: ARView) -> Bool {
        let currentTime = CACurrentMediaTime()
        
        guard currentTime - lastRadarTime > radarInterval else {
            return false
        }
        
        lastRadarTime = currentTime
        
        let screenWidth = arView.bounds.width
        let screenHeight = arView.bounds.height
        
        let rows = DetectionSettings.radarRows
        let cols = DetectionSettings.radarCols
        let minX = DetectionSettings.radarMinX
        let maxX = DetectionSettings.radarMaxX
        let minY = DetectionSettings.radarMinY
        let maxY = DetectionSettings.radarMaxY
        
        var closestDist: Float = 100.0
        var closestPoint: CGPoint? = nil
        
        for r in 0..<rows {
            for c in 0..<cols {
                let x = minX + (CGFloat(c) / CGFloat(cols-1)) * (maxX - minX)
                let y = minY + (CGFloat(r) / CGFloat(rows-1)) * (maxY - minY)
                
                let point = CGPoint(x: x * screenWidth, y: y * screenHeight)
                
                let query = arView.makeRaycastQuery(from: point, allowing: .estimatedPlane, alignment: .any)
                
                if let query = query {
                    let results = arView.session.raycast(query)
                    if let result = results.first {
                        let dist = length(result.worldTransform.columns.3)
                        if dist > DetectionSettings.safeDistance && dist < closestDist {
                            closestDist = dist
                            closestPoint = CGPoint(x: x, y: 1-y)
                        }
                    }
                }
            }
        }
        
        let validDist = (closestDist < DetectionSettings.maxDistance) ? closestDist : 0.0
        onObstacleDetected?(validDist, closestPoint)
        
        return true
    }
}
