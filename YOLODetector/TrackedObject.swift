//
//  TrackedObject.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation
import CoreGraphics

class TrackedObject {
    let id: UUID
    var label: String
    var rect: CGRect
    var lastSeen: TimeInterval
    
    // History of (Time, Distance)
    var distanceHistory: [(TimeInterval, Float)] = []
    
    // Velocity in Meters/Second
    var velocity: Float = 0.0
    
    // Smoothing limit
    private let historyLimit = DetectionSettings.trackingHistoryLimit
    
    init(label: String, rect: CGRect, distance: Float) {
        self.id = UUID()
        self.label = label
        self.rect = rect
        self.lastSeen = Date().timeIntervalSince1970
        update(rect: rect, distance: distance)
    }
    
    func update(rect: CGRect, distance: Float) {
        let now = Date().timeIntervalSince1970
        self.lastSeen = now
        self.rect = rect
        
        // 1. Add to history
        distanceHistory.append((now, distance))
        if distanceHistory.count > historyLimit {
            distanceHistory.removeFirst()
        }
        
        // 2. Calculate Velocity
        calculateVelocity()
    }
    
    private func calculateVelocity() {
        guard distanceHistory.count >= 2 else {
            velocity = 0.0
            return
        }
        
        // Compare last 2 readings for immediate responsiveness
        // This works better with higher frequency sampling (0.15s interval)
        let newest = distanceHistory.last!
        let previous = distanceHistory[distanceHistory.count - 2]
        
        let timeDiff = Float(newest.0 - previous.0)
        let distChange = newest.1 - previous.1
        
        if timeDiff > 0 {
            // Velocity = Distance Change / Time Change
            let rawVelocity = distChange / timeDiff
            
            // Apply smoothing using settings
            velocity = (velocity * DetectionSettings.velocitySmoothingOld) + 
                      (rawVelocity * DetectionSettings.velocitySmoothingNew)
        }
    }
    
    var isApproaching: Bool {
        // If moving closer faster than threshold
        return velocity < DetectionSettings.approachingVelocityThreshold
    }
}
