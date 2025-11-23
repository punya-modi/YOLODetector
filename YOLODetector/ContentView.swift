import SwiftUI

struct ContentView: View {
    @StateObject private var arManager = ARManager()
    
    var body: some View {
        ZStack {
            // 1. AR Feed
            ARViewContainer(arManager: arManager)
                .ignoresSafeArea()
            
            // 2. Bounding Boxes (YOLO)
            BoundingBoxView(
                predictions: arManager.predictions,
                imageSize: UIScreen.main.bounds.size
            )
            
            // REMOVED CROSSHAIR - It implies precision, but now we are doing area scanning.
            
            // 3. MAIN ALERT (Nearest Danger)
            if !arManager.obstacleLabel.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 5) {
                            // Bigger, clearer text for visual impairment
                            Text(arManager.obstacleLabel.uppercased())
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            
                            Text(arManager.obstacleDistance)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .padding(24)
                        .background(Color(arManager.obstacleColor))
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.horizontal, 20) // Ensure it doesn't touch screen edges
                        Spacer()
                    }
                    .padding(.bottom, 60)
                }
            }
            
            // 4. Performance Metrics
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FPS: \(String(format: "%.0f", arManager.fps))")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                        
                        Text("CPU: \(String(format: "%.1f", arManager.cpuUsage))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(arManager.cpuUsage > 80 ? .red : .yellow)
                        
                        Text("RAM: \(String(format: "%.1f", arManager.memoryUsage))MB")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(arManager.memoryUsage > 500 ? .red : .blue)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.leading, 20)
                Spacer()
            }
            
            // 5. Error Display
            if arManager.hasError, let errorMessage = arManager.errorMessage {
                VStack {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Error")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Dismiss") {
                            arManager.clearError()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .padding(20)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding(.top, 100)
            }
        }
    }
}
