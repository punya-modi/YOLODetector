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
            
            // 4. FPS
            VStack {
                HStack {
                    Text("FPS: \(String(format: "%.0f", arManager.fps))")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.leading, 20)
                Spacer()
            }
        }
    }
}
