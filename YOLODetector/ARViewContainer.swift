//
//  ARViewContainer.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arManager: ARManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // 1. Configure LiDAR for Mesh Generation
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        // 2. Enable Plane Detection (Walls/Floors)
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        // 3. Enable Apple's Built-in Visualization (Fastest Performance)
        // This overlays the wireframe mesh on the world automatically.
        // It usually colors floors blue, walls red/green, etc.
        arView.debugOptions.insert(.showSceneUnderstanding)
        
        // 4. Hook up the Manager
        arView.session.delegate = arManager
        arManager.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
