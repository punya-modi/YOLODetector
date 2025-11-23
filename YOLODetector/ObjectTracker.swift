//
//  ObjectTracker.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation
import CoreGraphics

class ObjectTracker {
    private var trackedObjects: [TrackedObject] = []
    
    func update(with detections: [RawDetection]) {
        var unmatchedDetections = detections
        
        // Match existing trackers with new detections using IoU
        for tracker in trackedObjects {
            var bestMatchIndex: Int?
            var bestMatchIoU: CGFloat = 0.0
            var bestMatchDistance: CGFloat = DetectionSettings.trackingMatchDistance
            
            for (index, detection) in unmatchedDetections.enumerated() {
                // First try to match by label and IoU
                if detection.label == tracker.label {
                    let iou = calculateIoU(rect1: tracker.rect, rect2: detection.rect)
                    if iou > bestMatchIoU && iou > 0.1 { // Minimum IoU threshold
                        bestMatchIoU = iou
                        bestMatchIndex = index
                    }
                }
                
                // Fallback: match by position if IoU is low but close enough
                if bestMatchIndex == nil {
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
        
        // Create new trackers for unmatched detections
        for detection in unmatchedDetections {
            let newTracker = TrackedObject(label: detection.label, rect: detection.rect, distance: detection.distance)
            trackedObjects.append(newTracker)
        }
        
        // Remove stale trackers
        let now = Date().timeIntervalSince1970
        trackedObjects.removeAll { now - $0.lastSeen > DetectionSettings.trackingTimeout }
    }
    
    func getTrackedObjects() -> [TrackedObject] {
        return trackedObjects
    }
    
    func clear() {
        trackedObjects.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func calculateIoU(rect1: CGRect, rect2: CGRect) -> CGFloat {
        let intersection = rect1.intersection(rect2)
        let union = rect1.union(rect2)
        
        guard !intersection.isNull && union.width > 0 && union.height > 0 else {
            return 0.0
        }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = union.width * union.height
        
        return intersectionArea / unionArea
    }
    
    private func distanceBetween(rect1: CGRect, rect2: CGRect) -> CGFloat {
        let p1 = CGPoint(x: rect1.midX, y: rect1.midY)
        let p2 = CGPoint(x: rect2.midX, y: rect2.midY)
        return hypot(p1.x - p2.x, p1.y - p2.y)
    }
}
