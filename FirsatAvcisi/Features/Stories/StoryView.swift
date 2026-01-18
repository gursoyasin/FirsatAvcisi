import SwiftUI
import Combine

struct StoryView: View {
    let products: [Product]
    @Binding var isPresented: Bool
    @State private var currentIndex = 0
    @State private var progress: CGFloat = 0
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var currentProduct: Product? {
        if products.indices.contains(currentIndex) {
            return products[currentIndex]
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let product = currentProduct {
                // Background Image (Blurred)
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.black
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(Material.ultraThinMaterial)
                .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: 0) {
                    // Progress Bars
                    HStack(spacing: 4) {
                        ForEach(0..<products.count, id: \.self) { index in
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle().fill(Color.white.opacity(0.3))
                                    if index < currentIndex {
                                        Rectangle().fill(Color.white)
                                    } else if index == currentIndex {
                                        Rectangle().fill(Color.white).frame(width: geo.size.width * progress)
                                    }
                                }
                            }
                            .frame(height: 3)
                            .cornerRadius(1.5)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.horizontal)
                    
                    // Header
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Günün Fırsatları")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Product Card
                    VStack(alignment: .leading, spacing: 12) {
                        AsyncImage(url: URL(string: product.imageUrl ?? "")) { img in
                            img.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(height: 300)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(product.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .lineLimit(2)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("\(product.currentPrice, format: .currency(code: "TRY"))")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if let original = product.originalPrice, original > product.currentPrice {
                                    Text("\(original, format: .currency(code: "TRY"))")
                                        .strikethrough()
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            Link(destination: URL(string: product.url)!) {
                                Text("Fırsata Git")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Instructions
                    Text("Kaydırmak için dokun")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 20)
                }
            }
        }
        .onReceive(timer) { _ in
            if progress < 1.0 {
                progress += 0.02 // 5 seconds per slide
            } else {
                nextSlide()
            }
        }
        .onTapGesture { location in
            let width = UIScreen.main.bounds.width
            if location.x > width / 2 {
                nextSlide()
            } else {
                prevSlide()
            }
        }
        // Force status bar hidden for immersion
        .statusBar(hidden: true)
    }
    
    private func nextSlide() {
        if currentIndex < products.count - 1 {
            currentIndex += 1
            progress = 0
            HapticManager.shared.impact(style: .light)
        } else {
            isPresented = false
            HapticManager.shared.notification(type: .success)
        }
    }
    
    private func prevSlide() {
        if currentIndex > 0 {
            currentIndex -= 1
            progress = 0
            HapticManager.shared.impact(style: .light)
        }
    }
}
