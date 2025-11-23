//
//  DetectionSettings.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation

struct DetectionSettings {
    // Distance Settings
    static let maxDistance: Float = 5.0
    static let minDistance: Float = 0.1
    static let safeDistance: Float = 0.2
    
    // Confidence Thresholds
    static let confidenceThreshold: Float = 0.6
    
    // Velocity Settings
    static let approachingVelocityThreshold: Float = -0.1
    static let movingAwayVelocityThreshold: Float = 0.3
    
    // Performance Throttling
    static let visionInterval: TimeInterval = 0.1 // Cap YOLO at 10 FPS
    static let radarInterval: TimeInterval = 0.15 // Cap Radar at ~6.7 FPS
    
    // Tracking Settings
    static let trackingTimeout: TimeInterval = 0.5 // Remove objects not seen for 0.5s
    static let trackingMatchDistance: CGFloat = 0.2 // Max distance for matching (normalized)
    static let trackingHistoryLimit: Int = 10 // Max history entries per object
    
    // Velocity Calculation
    static let velocitySmoothingOld: Float = 0.6
    static let velocitySmoothingNew: Float = 0.4
    
    // Radar Settings
    static let radarRows: Int = 3
    static let radarCols: Int = 3
    static let radarMinX: CGFloat = 0.2
    static let radarMaxX: CGFloat = 0.8
    static let radarMinY: CGFloat = 0.25
    static let radarMaxY: CGFloat = 0.75
    
    // Distance Measurement
    static let distanceMeasurementPoints: Int = 5 // Center + 4 corners
    static let cornerOffset: CGFloat = 0.2 // Offset from corners for measurement
}
