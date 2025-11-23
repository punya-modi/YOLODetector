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
            
            // 3. FPS
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
