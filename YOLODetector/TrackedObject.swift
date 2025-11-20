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
    private let historyLimit = 10
    
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
        guard distanceHistory.count >= 3 else {
            velocity = 0.0
            return
        }
        
        // Compare newest reading vs oldest reading in buffer
        let newest = distanceHistory.last!
        let oldest = distanceHistory.first!
        
        let timeDiff = Float(newest.0 - oldest.0)
        let distChange = newest.1 - oldest.1 // <--- This was missing
        
        if timeDiff > 0 {
            // Velocity = Distance Change / Time Change
            let rawVelocity = distChange / timeDiff
            
            // Apply smoothing: 70% old value + 30% new value
            velocity = (velocity * 0.7) + (rawVelocity * 0.3)
        }
    }
    
    var isApproaching: Bool {
        // If moving closer faster than 0.3 m/s
        return velocity < -0.3
    }
}
