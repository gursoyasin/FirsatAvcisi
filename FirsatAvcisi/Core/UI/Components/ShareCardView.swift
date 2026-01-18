import SwiftUI

struct ShareCardView: View {
    let product: Product
    let brandColor: Color
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [brandColor.opacity(0.8), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Fırsat Avcısı")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 20)
                
                // Product Image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image.resizable()
                         .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 250)
                .cornerRadius(16)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.3), radius: 15, y: 10)
                
                // Info
                VStack(spacing: 8) {
                    Text(product.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(product.source.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                
                // Price
                HStack(alignment: .firstTextBaseline) {
                    Text("\(product.currentPrice, format: .currency(code: "TRY"))")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let original = product.originalPrice, original > product.currentPrice {
                        Text("\(original, format: .currency(code: "TRY"))")
                            .strikethrough()
                            .foregroundColor(.white.opacity(0.6))
                            .font(.title3)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
        .frame(width: 350, height: 500)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
