//
//  PerformanceMonitor.swift
//  YOLODetector
//
//  Created by Tushar Wani on 11/19/25.
//

import Foundation
import UIKit
import Combine
import Darwin

class PerformanceMonitor: ObservableObject {
    private var lastExecutionTime: TimeInterval = 0
    private var frameCount: Int = 0
    private var lastFPSUpdate: TimeInterval = 0
    
    @Published var fps: Double = 0
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Double = 0
    
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    func recordFrame() {
        let currentTime = CACurrentMediaTime()
        frameCount += 1
        
        if lastExecutionTime > 0 {
            let processingTime = currentTime - lastExecutionTime
            if processingTime > 0 {
                let currentFPS = 1.0 / processingTime
                // Exponential moving average
                fps = (fps * 0.9) + (currentFPS * 0.1)
            }
        }
        lastExecutionTime = currentTime
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSystemMetrics()
        }
    }
    
    private func updateSystemMetrics() {
        // CPU Usage (approximate)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            // Memory usage in MB
            memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        // CPU usage is harder to get accurately, using a simplified approach
        // In a real app, you'd use more sophisticated methods
        cpuUsage = calculateCPUUsage()
    }
    
    private func calculateCPUUsage() -> Double {
        // Simplified CPU usage calculation
        // In production, you'd use ProcessInfo or more advanced methods
        let processInfo = ProcessInfo.processInfo
        let cpuCount = Double(processInfo.processorCount)
        
        // This is a simplified approximation
        // Real CPU usage would require more complex monitoring
        return min(100.0, (fps / 30.0) * 100.0 / cpuCount)
    }
    
    deinit {
        timer?.invalidate()
    }
}
