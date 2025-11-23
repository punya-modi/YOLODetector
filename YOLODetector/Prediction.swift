//
//  Prediction.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/10/25.
//

import CoreGraphics
import SwiftUI

struct Prediction {
    let label: String
    let classIndex: Int
    let confidence: Float
    let rect: CGRect
    
    // New fields
    let velocity: Float
    let isApproaching: Bool
    
    // Helper to format semantics for the blind
    var semanticLabel: String {
        if isApproaching {
            // Positive velocity means getting closer (after sign flip fix)
            return String(format: "APPROACHING! %.1f m/s", abs(velocity))
        } else if velocity < -0.3 {
            // Negative velocity means moving away (after sign flip fix)
            return String(format: "Moving Away %.1f m/s", abs(velocity))
        } else {
            return "Stationary"
        }
    }
    
    // Helper for UI Color
    var statusColor: Color {
        if isApproaching { return .red }
        if velocity < -0.3 { return .green }
        return .yellow
    }
}
