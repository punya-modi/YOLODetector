//
//  DetectionError.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation

enum DetectionError: LocalizedError {
    case modelLoadFailed(String)
    case visionModelCreationFailed
    case arSessionFailed(String)
    case cameraNotAvailable
    case lidarNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let details):
            return "Failed to load ML model: \(details)"
        case .visionModelCreationFailed:
            return "Failed to create Vision model from CoreML model"
        case .arSessionFailed(let details):
            return "AR Session error: \(details)"
        case .cameraNotAvailable:
            return "Camera is not available"
        case .lidarNotAvailable:
            return "LiDAR is not available on this device"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelLoadFailed:
            return "Please ensure the model file is included in the app bundle"
        case .visionModelCreationFailed:
            return "The model format may be incompatible. Please check the model version."
        case .arSessionFailed:
            return "Please restart the app and ensure ARKit is supported on your device"
        case .cameraNotAvailable:
            return "Please grant camera permissions in Settings"
        case .lidarNotAvailable:
            return "LiDAR is only available on iPhone 12 Pro and later, or iPad Pro 2020 and later"
        }
    }
}
