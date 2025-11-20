import SwiftUI

struct BoundingBoxView: View {
    let predictions: [Prediction]
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(predictions, id: \.rect) { prediction in
                let rect = prediction.rect
                let scaledRect = CGRect(
                    x: rect.origin.x * geometry.size.width,
                    y: rect.origin.y * geometry.size.height,
                    width: rect.width * geometry.size.width,
                    height: rect.height * geometry.size.height
                )
                
                ZStack {
                    // Box color depends on danger status
                    Rectangle()
                        .stroke(prediction.statusColor, lineWidth: prediction.isApproaching ? 6 : 3)
                        .background(prediction.isApproaching ? prediction.statusColor.opacity(0.2) : Color.clear)
                    
                    // Label
                    VStack {
                        Spacer()
                        VStack(alignment: .center) {
                            Text(prediction.label) // e.g. "Person 2.1m"
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            
                            // Velocity Semantic Text
                            Text(prediction.semanticLabel) // e.g. "APPROACHING! 1.2m/s"
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(prediction.isApproaching ? .white : .black)
                        }
                        .padding(6)
                        .background(prediction.statusColor)
                        .cornerRadius(4)
                    }
                }
                .frame(width: scaledRect.width, height: scaledRect.height)
                .position(x: scaledRect.midX, y: scaledRect.midY)
            }
        }
    }
}
