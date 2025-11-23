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
    
    // Track if the last distance measurement was valid
    var hasValidDistance: Bool = false
    
    // Velocity in Meters/Second
    var velocity: Float = 0.0
    
    // Smoothing limit
    private let historyLimit = DetectionSettings.trackingHistoryLimit
    
    init(label: String, rect: CGRect, distance: Float, hasValidDistance: Bool = false) {
        self.id = UUID()
        self.label = label
        self.rect = rect
        self.lastSeen = Date().timeIntervalSince1970
        self.hasValidDistance = hasValidDistance
        update(rect: rect, distance: distance, hasValidDistance: hasValidDistance)
    }
    
    func update(rect: CGRect, distance: Float, hasValidDistance: Bool = false) {
        let now = Date().timeIntervalSince1970
        self.lastSeen = now
        self.rect = rect
        self.hasValidDistance = hasValidDistance
        
        // 1. Add to history
        distanceHistory.append((now, distance))
        if distanceHistory.count > historyLimit {
            distanceHistory.removeFirst()
        }
        
        // 2. Calculate Velocity (only if we have valid distances)
        if hasValidDistance {
            calculateVelocity()
        } else {
            // Reset velocity if distance is invalid
            velocity = 0.0
        }
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
        // Only meaningful if we have valid distance measurements
        guard hasValidDistance else { return false }
        // If moving closer faster than threshold
        return velocity < DetectionSettings.approachingVelocityThreshold
    }
}
